classdef TestMultiverseM8 < matlab.unittest.TestCase
    % ERP/nonstationarity source-level benchmark and real-data preflight.
    methods (TestClassSetup)
        function paths(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function roiCountsRequireActualConfiguredROIs(tc)
            setup=struct();
            setup.loc.ROI=repmat(struct('name','ROI'),5,1);
            setup.con=struct('mvarOrd',7);
            tc.verifyError(@()asct_m8_realdata_factors(setup,[5 8 12]), ...
                'ASCT:M8:InsufficientROIs');
            [f,required]=asct_m8_realdata_factors(setup,5);
            tc.verifyEqual(required,5);
            tc.verifyEqual(f.chanSel,{'1-5'});
            mv=struct('factors',struct('con',f),'maxRuns',8);
            tc.verifyNumElements(asct_multiverse_realdata_grid(mv),8);
            setup.loc.ROI=repmat(struct('name','ROI'),12,1);
            [f,required]=asct_m8_realdata_factors(setup,[5 8 12]);
            tc.verifyEqual(required,12);
            mv=struct('factors',struct('con',f),'maxRuns',24);
            tc.verifyNumElements(asct_multiverse_realdata_grid(mv),24);
        end
        function physicalMvarCoefficientsInvariantToGlobalScaling(tc)
            cfg=cfg5();sim=asct_m6_generate(cfg,smallOptions());
            opts=struct('orderMode','fixed','fixedOrder',2, ...
                'maxMvarOrder',3,'varNorm',false,'removeERP',false);
            u=asct_m8_fit(sim.observedSources,opts);
            opts.varNorm=true;
            v=asct_m8_fit(sim.observedSources,opts);
            tc.verifyEqual(u.A,v.A,'AbsTol',1e-8);
            tc.verifyEqual(u.order,v.order);
            tc.verifyTrue(v.oracleOLS);
            tc.verifyFalse(v.productionMultarValidated);
        end
        function subtractingERPReducesPhaseLockedMean(tc)
            cfg=cfg5();cfg.evokedAmplitude=2;
            sim=asct_m6_generate(cfg,smallOptions());
            before=mean(sim.observedSources,3);
            after=asct_remove_erp(sim.observedSources);
            tc.verifyGreaterThan(norm(before(:)),1);
            tc.verifyLessThan(norm(mean(after,3),'fro'),1e-9);
        end
        function factorialStudyAndPairs(tc)
            output=tempname;
            tc.addTeardown(@()localCleanup(output));
            cfg=cfg5();cfg=rmfield(cfg,{'simSeed','evokedAmplitude','varianceDrift'});
            opts=struct('source',cfg,'simulation',smallOptions(), ...
                'seed',23,'nReplicates',2,'nBootstrap',100, ...
                'roiCounts',5,'evokedAmplitudes',[0 1], ...
                'varianceDrifts',[0 0.5],'orderModes',{{'fixed','aic'}}, ...
                'normModes',[0 1],'removeERPModes',[false true], ...
                'fixedOrder',2,'maxMvarOrder',3);
            [T,S,P]=asct_m8_study(output,opts);
            tc.verifyEqual(height(T),64);
            tc.verifyEqual(height(S),32);
            tc.verifyEqual(height(P),32);
            tc.verifyTrue(all(isfinite(T.f1)));
            tc.verifyTrue(all(isfinite(P.fprReduction)));
            tc.verifyTrue(isfile(fullfile(output,'m9_erp_pairs.csv')));
            tc.verifyTrue(isfile(fullfile(output,'m9_erp_effect_summary.csv')));
            tc.verifyTrue(isfile(fullfile(output,'m9_robustness_summary.csv')));
        end
        function syntheticTwelveRoiStudyIsDistinctFromRealFlanker(tc)
            output=tempname;
            tc.addTeardown(@()localCleanup(output));
            cfg=cfg5();cfg.nSources=12;cfg.nInteractions=9;
            cfg=rmfield(cfg,{'simSeed','evokedAmplitude','varianceDrift'});
            opts=struct('source',cfg,'simulation',smallOptions(), ...
                'seed',91,'nReplicates',2,'nBootstrap',100, ...
                'roiCounts',[5 8 12],'evokedAmplitudes',0, ...
                'varianceDrifts',0,'orderModes',{{'fixed'}}, ...
                'normModes',0,'removeERPModes',[false true], ...
                'fixedOrder',2,'maxMvarOrder',3);
            [T,S,P]=asct_m8_study(output,opts);
            tc.verifyEqual(height(T),12);
            tc.verifyEqual(height(S),6);
            tc.verifyEqual(height(P),6);
            tc.verifyEqual(unique(T.nROIs),[5;8;12]);
            tc.verifyTrue(all(T.nTrueEdges>=0));
        end
        function noTrueEdgesKeepFPRButLeaveF1Undefined(tc)
            output=tempname;
            tc.addTeardown(@()localCleanup(output));
            cfg=cfg5();cfg.nInteractions=0;cfg.strength=0;
            cfg=rmfield(cfg,{'simSeed','evokedAmplitude','varianceDrift'});
            opts=struct('source',cfg,'simulation',smallOptions(), ...
                'seed',17,'nReplicates',2,'nBootstrap',100, ...
                'roiCounts',5,'evokedAmplitudes',0, ...
                'varianceDrifts',0,'orderModes',{{'fixed'}}, ...
                'normModes',0,'removeERPModes',[false true], ...
                'fixedOrder',2,'maxMvarOrder',3);
            [T,S,P]=asct_m8_study(output,opts);
            tc.verifyTrue(all(T.nTrueEdges==0));
            tc.verifyTrue(all(isnan(T.f1)));
            tc.verifyTrue(all(isfinite(T.falsePositiveRate)));
            tc.verifyTrue(all(isnan(P.f1Gain)));
            tc.verifyTrue(all(S.nValid_f1==0));
            [R,RS]=asct_m9_robustness(T,100,17);
            tc.verifyTrue(all(isnan(R.f1Range)));
            tc.verifyTrue(all(isfinite(R.maxFPR)));
            tc.verifyTrue(all(RS.nValid_f1Range==0));
        end
        function selectedROILabelsAreForwardedToMultar(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            source=fileread(fullfile(root,'pipelineSC','sc_8_CONN.m'));
            tc.verifyTrue(contains(source,'mv.descfil = labelfiletrim;'));
        end
        function realOutputAuditChecksSelectedDimension(tc)
            folder=tempname;mkdir(folder);
            tc.addTeardown(@()localCleanup(folder));
            analysisName='m8_demo__mv_0001';
            mroot=fullfile(folder,'m8_demo__multiverse');mkdir(mroot);
            configId="mv_0001";analysisNameT=string(analysisName);
            status="passed";
            T=table(configId,analysisNameT,status, ...
                'VariableNames',{'configId','analysisName','status'});
            writetable(T,fullfile(mroot,'realdata_manifest.csv'));
            out=fullfile(folder,analysisName);
            mkdir(out);
            runsetup.con=struct('conName','conn','chanSel','1-5', ...
                'varNorm',0,'mvarOrd',2,'orderSelection','fixed');
            runsetup.loc.ROI=repmat(struct('name','roi'),12,1);
            save(fullfile(out,'multiverse_setup.mat'),'runsetup');
            conn=fullfile(out,'8_CONN','conn','lc','DC1');mkdir(conn);
            NDTF=zeros(5,5,10);ARs=struct('coefs',zeros(5,5,2),'V',eye(5));
            ARs.coefs(:,:,1)=0.25*eye(5);
            labelFile=fullfile(out,'8_CONN','conn','labels_trimmed.txt');
            fid=fopen(labelFile,'w');
            for j=1:5,fprintf(fid,'roi%d\n',j);end
            fclose(fid);
            mv=struct('pord',2,'norm1',0,'descfil',labelFile);
            save(fullfile(conn,'01_A_mltout.mat'),'NDTF','ARs','mv');
            report=asct_m8_conn_audit(mroot);
            tc.verifyEqual(height(report),1);
            tc.verifyTrue(report.stableVAR);
            tc.verifyTrue(report.labelsVerified);
            tc.verifyEqual(report.nROIs,5);
            NDTF=zeros(12,12,10); %#ok<NASGU>
            save(fullfile(conn,'01_A_mltout.mat'),'NDTF','ARs','mv');
            tc.verifyError(@()asct_m8_conn_audit(mroot),'ASCT:M8:InvalidDTF');
        end
        function storedROIInputPreflight(tc)
            folder=tempname;mkdir(folder);
            tc.addTeardown(@()localCleanup(folder));
            path=fullfile(folder,'ana1','7_SOURCEACT','DC1','lc');mkdir(path);
            data_sigroi=struct('FLANK',struct('signal',ones(12,120), ...
                'trialen',30,'sampling_rate',128)); %#ok<NASGU>
            save(fullfile(path,'01_A_sigroi_lc.mat'),'data_sigroi');
            setup=struct();setup.rc.expFolder=folder;
            setup.con=struct('lc',true,'unc',false);
            setup.design.DC=struct('name','flanker');
            report=asct_m8_realdata_preflight(setup,'ana1',12);
            tc.verifyEqual(height(report),1);
            tc.verifyEqual(report.nROIs,12);
            tc.verifyError(@()asct_m8_realdata_preflight(setup,'ana1',13), ...
                'ASCT:M8:InsufficientROIs');
        end
    end
end
function cfg=cfg5()
cfg=struct('nSources',5,'distanceCm',2,'nInteractions',3, ...
    'strength',0.3,'lag',2,'snrDb',12,'simSeed',357, ...
    'evokedAmplitude',0,'varianceDrift',0);
end
function o=smallOptions()
o=struct('fs',64,'nSamples',144,'nTrials',4,'nSensors',14);
end
function localCleanup(path)
if isfolder(path),rmdir(path,'s');end
end
