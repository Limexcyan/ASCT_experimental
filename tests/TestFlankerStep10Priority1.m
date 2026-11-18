classdef TestFlankerStep10Priority1 < matlab.unittest.TestCase
    % Lightweight synthetic MAT fixtures; FieldTrip/mmultar are not needed.
    methods (TestClassSetup)
        function addPaths(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(root,fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function eightStep10Configs(tc)
            mv=struct('maxRuns',8,'factors',struct());
            mv.factors.con.varNorm=[0 1];
            mv.factors.con.orderSelection={'fixed','aic'};
            mv.factors.con.removeERP=[false true];
            specs=asct_multiverse_realdata_grid(mv);
            tc.verifyNumElements(specs,8);
            tc.verifyEqual([specs.startStep],10*ones(1,8));
            tc.verifyEqual(specs(1).changes.con.varNorm,0);
            tc.verifyEqual(specs(2).changes.con.varNorm,1);
            tc.verifyEqual(specs(3).changes.con.orderSelection,'aic');
            tc.verifyFalse(specs(3).changes.con.removeERP);
            tc.verifyTrue(specs(5).changes.con.removeERP);
        end
        function validatesOriginalARSummaryAndVarNormPairs(tc)
            folder=fixture(tc);
            out=flanker_step10_audit(folder,'case_v2','ana1','conn',false);
            tc.verifyEqual(height(out.perFile),8);
            tc.verifyEqual(height(out.pairwise),1);
            tc.verifyEqual(out.pairwise.changedFactor(1),"varNorm");
            tc.verifyGreaterThan(out.pairwise.maxAbsNDTF(1),0);
        end
        function detectsTamperedMLTin(tc)
            folder=fixture(tc);
            path=fullfile(folder,'case_v2__mv_0002','8_CONN','conn', ...
                'lc','DC1','A1_FLA_1_FLANK_INCO_mltin.mat');
            mltin=zeros(3,32); %#ok<NASGU>
            save(path,'mltin');
            tc.verifyError(@()flanker_step10_audit(folder,'case_v2','ana1','conn',false), ...
                'ASCT:Audit:ERPInputMismatch');
        end
        function detectsIncompleteARSummary(tc)
            folder=fixture(tc);
            path=fullfile(folder,'case_v2__mv_0001','8_CONN','conn','AR_summary.csv');
            T=readtable(path);
            writetable(T(1:2,:),path);
            tc.verifyError(@()flanker_step10_audit(folder,'case_v2','ana1','conn',false), ...
                'ASCT:Audit:BadARSummary');
        end
        function detectsInvalidNDTF(tc)
            folder=fixture(tc);
            path=fullfile(folder,'case_v2__mv_0001','8_CONN','conn', ...
                'lc','DC1','A1_FLA_1_FLANK_INCO_mltout.mat');
            O=load(path);
            NDTF=O.NDTF; NDTF(1,2,1)=NaN; %#ok<NASGU>
            ARs=O.ARs; mv=O.mv; %#ok<NASGU>
            save(path,'NDTF','ARs','mv');
            tc.verifyError(@()flanker_step10_audit(folder,'case_v2','ana1','conn',false), ...
                'ASCT:Audit:InvalidNDTF');
        end
        function checksPairingEvenWithoutSTEP11(tc)
            folder=fixture(tc);
            M=load(fullfile(folder,'case_v2__mv_0001','multiverse_setup.mat'));
            p=M.runsetup;
            mv=struct('sourceAnalysis','ana1','runStatistics',false);
            dest=fullfile(folder,'ana1','7_SOURCEACT','DC2','lc');
            movefile(fullfile(dest,'A2_FLA_1_sigroi_lc.mat'), ...
                fullfile(dest,'A3_FLA_1_sigroi_lc.mat'));
            tc.verifyError(@()asct_multiverse_flanker_preflight(p,mv), ...
                'ASCT:Flanker:UnpairedSubjects');
        end
        function auditsAICAndRealERPRemoval(tc)
            folder=fixture(tc,true);
            out=flanker_step10_audit(folder,'case_v2','ana1','conn',false);
            tc.verifyEqual(height(out.perFile),12);
            aic=out.perFile(out.perFile.orderSelection=="aic",:);
            tc.verifyEqual(height(aic),4);
            tc.verifyTrue(all(aic.selectedOrder==4));
            tc.verifyTrue(all(aic.removeERP));
            tc.verifyLessThan(max(aic.maxInputDeviation),1e-10);
            % Replace correctly ERP-cleaned mltin with uncleaned source.
            target=fullfile(folder,'case_v2__mv_0003','8_CONN', ...
                'conn','lc','DC1','A1_FLA_1_FLANK_INCO_mltin.mat');
            src=load(fullfile(folder,'ana1','7_SOURCEACT','DC1', ...
                'lc','A1_FLA_1_sigroi_lc.mat'));
            mltin=src.data_sigroi.FLANK_INCO.signal; %#ok<NASGU>
            save(target,'mltin');
            tc.verifyError(@()flanker_step10_audit(folder,'case_v2','ana1','conn',false), ...
                'ASCT:Audit:ERPInputMismatch');
        end
    end
end

function folder=fixture(tc,withERP)
if nargin<2, withERP=false; end
folder=tempname; mkdir(folder);
tc.addTeardown(@()rmdir(folder,'s'));
configId=["mv_0001";"mv_0002"];
analysisName=["case_v2__mv_0001";"case_v2__mv_0002"];
if withERP
    configId(end+1,1)="mv_0003";
    analysisName(end+1,1)="case_v2__mv_0003";
end
connectivityStatus=repmat("passed",numel(configId),1);
manifest=table(configId,analysisName,connectivityStatus);
mdir=fullfile(folder,'case_v2__multiverse');mkdir(mdir);
writetable(manifest,fullfile(mdir,'realdata_manifest.csv'));
for dc=1:2
    rdir=fullfile(folder,'ana1','7_SOURCEACT',sprintf('DC%d',dc),'lc');
    mkdir(rdir);
    if dc==1, cname='FLANK_INCO'; else, cname='FLANK_CONG'; end
    for s=1:2
        stem=sprintf('A%d_FLA_1',s);
        % Deterministic, nonzero trial-averaged ERP component.
        v=reshape(1:96,3,32) + dc*0.01 + s*0.1;
        data_sigroi=struct();
        data_sigroi.(cname)=struct('signal',v,'trialen',8, ...
            'sampling_rate',512); %#ok<AGROW>
        save(fullfile(rdir,[stem '_sigroi_lc.mat']),'data_sigroi');
    end
end
for vno=1:numel(configId)
    erpFlag=vno==3;
    root=fullfile(folder,char(analysisName(vno)));
    mkdir(root);
    runsetup.rc=struct('expFolder',folder, ...
        'analysisName',char(analysisName(vno)),'sigroiName','ana1');
    runsetup.con=struct('conName','conn','varNorm',mod(vno-1,2), ...
        'orderSelection','fixed','mvarOrd',7,'maxMvarOrder',10, ...
        'removeERP',erpFlag,'lc',1,'unc',0, ...
        'testType','within','contrast2test',{{[1 2]}});
    if erpFlag, runsetup.con.orderSelection='aic'; end
    runsetup.design.DC=struct('name',{'inco','cong'});
    runsetup.design.idPosStart=1;runsetup.design.idPosEnd=2;
    runsetup.begId=1;runsetup.endId=2;
    spec=struct('id',sprintf('mv_%04d',vno)); %#ok<NASGU>
    save(fullfile(root,'multiverse_setup.mat'),'runsetup','spec');
    for dc=1:2
        if dc==1, cname='FLANK_INCO'; else, cname='FLANK_CONG'; end
        dest=fullfile(root,'8_CONN','conn','lc',sprintf('DC%d',dc));mkdir(dest);
        for s=1:2
            stem=sprintf('A%d_FLA_1',s);
            src=load(fullfile(folder,'ana1','7_SOURCEACT', ...
                sprintf('DC%d',dc),'lc',[stem '_sigroi_lc.mat']));
            mltin=src.data_sigroi.(cname).signal; %#ok<NASGU>
            if erpFlag, mltin=asct_remove_erp(mltin,8); end
            save(fullfile(dest,[stem '_' cname '_mltin.mat']),'mltin');
            NDTF=ones(3,3,25)*vno*0.1; %#ok<NASGU>
            if erpFlag, pord=4; else, pord=7; end
            coefs=zeros(3,3,pord); coefs(:,:,1)=eye(3)*0.1;
            ARs=struct('V',eye(3)*vno*.01,'coefs',coefs); %#ok<NASGU>
            mv=struct('pord',pord,'norm1',mod(vno-1,2)); %#ok<NASGU>
            save(fullfile(dest,[stem '_' cname '_mltout.mat']),'NDTF','ARs','mv');
        end
    end
    rc=struct('expFolder',folder,'analysisName',char(analysisName(vno)), ...
        'sigroiName','ana1');
    con=struct('conName','conn');
    sc_arstat(rc,con);
end
end
