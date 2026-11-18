classdef TestMultiverseM2 < matlab.unittest.TestCase
    % Tests M2 configuration safety, leadfield isolation and integration.
    methods (TestClassSetup)
        function paths(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function validatesAllMNEParameters(tc)
            loc=struct('method','mne','norm','lambda', ...
                'lambda',0.1,'noiseLev',2,'depthWeight',0.5);
            got=asct_multiverse_validate_localization(loc,struct(),true);
            tc.verifyEqual(got.lambda,0.1);
            tc.verifyEqual(got.depthWeight,0.5);
            loc.norm='cov';
            got=asct_multiverse_validate_localization(loc,struct(),true);
            tc.verifyEqual(got.norm,'cov');
        end
        function rejectsInvalidAndInertSettings(tc)
            l=struct('method','mne','norm','cov','noiseLev',2,'depthWeight',0.5);
            x=l;x.noiseLev=0;
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct(),true), ...
                'ASCT:M2:InvalidNoiseLevel');
            x=l;x.depthWeight=-1;
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct(),true), ...
                'ASCT:M2:InvalidDepthWeight');
            x=l;x.depthWeight=1.1;
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct(),true), ...
                'ASCT:M2:InvalidDepthWeight');
            x=l;x.method='beamformer';
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct(),true), ...
                'ASCT:M2:UnsupportedMethod');
            x=l;x.norm='lambda';
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct(),true), ...
                'ASCT:M2:MissingLambda');
            x=l;x.lambda=0.1;
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct('lambda',0.1),true), ...
                'ASCT:M2:InertFactor');
            x=l;x=rmfield(x,'noiseLev');
            tc.verifyError(@()asct_multiverse_validate_localization(x,struct(),true), ...
                'ASCT:M2:MissingNoiseLevel');
        end
        function planRejectsInertLambdaChoice(tc)
            [p,~]=fixture(tc);
            mv=options();
            mv.factors.loc.lambda=[0.1 0.2];
            tc.verifyError(@()asct_multiverse_plan(p,mv),'ASCT:M2:InertFactor');
        end
        function filteredNormLambdaGridIsValid(tc)
            [p,~]=fixture(tc);
            mv=options();mv.maxRuns=4;
            mv.factors.loc.norm={'lambda','cov'};
            mv.factors.loc.lambda=[0.1 0.2];
            mv.includeFcn=@(c)strcmp(c.loc.norm,'lambda') || c.loc.lambda==0.1;
            [plan,specs]=asct_multiverse_plan(p,mv);
            tc.verifyNumElements(specs,3);
            tc.verifyEqual([plan.requiredStartStep],[8 8 8]);
        end
        function stage8IsolatesAndForcesLeadfield(tc)
            [p,~]=fixture(tc);
            p.loc.force_lf=0;
            mv=options();mv.strictLocalization=true;
            mv.factors.loc.depthWeight=[0 0.5];
            s=asct_multiverse_realdata_grid(mv);
            q=asct_multiverse_realdata_prepare(p,mv,s(1));
            tc.verifyEqual(q.rc.load,8);
            tc.verifyTrue(q.rc.multiverseIsolatedLeadfield);
            tc.verifyEqual(q.loc.force_lf,1);
            tc.verifyEqual(q.loc.depthWeight,0);
            tc.verifyEqual(q.rc.ica2Name,'previous');
        end
        function strictConfigFailsBeforeWriting(tc)
            [p,folder]=fixture(tc);
            p.loc=rmfield(p.loc,'noiseLev');
            mv=options();mv.strictLocalization=true;
            mv.factors.loc.depthWeight=[0 0.5];
            tc.verifyError(@()asct_multiverse_realdata(p,mv), ...
                'ASCT:M2:MissingNoiseLevel');
            tc.verifyFalse(isfolder(fullfile(folder,'experiment__multiverse')));
        end
        function verifiesMissingDC(tc)
            [p,folder]=fixture(tc);
            p.rc.load=10;
            p.rc.analysisName='ready';
            touchFile(fullfile(folder,'ready','8_CONN','conn','lc','DC1','A1_mltout.mat'));
            tc.verifyError(@()asct_multiverse_verify_artifacts(p), ...
                'ASCT:M2:MissingArtifact');
            touchFile(fullfile(folder,'ready','8_CONN','conn','lc','DC2','A1_mltout.mat'));
            t=asct_multiverse_verify_artifacts(p);
            tc.verifyEqual(t.connFiles,2);
        end
        function strictArtifactsRejectsFakeSuccess(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.dryRun=false;mv.strictArtifacts=true;
            mv.factors.con.varNorm=0;
            tc.verifyError(@()asct_multiverse_realdata(p,mv,@emptyRunner), ...
                'ASCT:RealMultiverse:Stopped');
            saved=load(fullfile(folder,'experiment__multiverse','realdata_results.mat'),'results');
            tc.verifyEqual(saved.results.connectivityStatus,'failed');
        end
        function fullMockIntegrationChecksDonorAndOutputs(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.dryRun=false;mv.cacheStages=true;
            mv.strictArtifacts=true;mv.strictLocalization=true;
            mv.factors.loc.depthWeight=[0 0.5];
            mv.factors.con.varNorm=[0 1];
            r=asct_multiverse_realdata(p,mv,@fullRunner);
            tc.verifyTrue(all(strcmp({r.status},'passed')));
            tc.verifyEqual([r.executionStartStep],[8 8 10 10]);
            out=asct_multiverse_m1m2_verify(folder,'experiment');
            tc.verifyEqual(height(out),4);
            tc.verifyEqual(out.connFiles,[2;2;2;2]);
        end
        function variantPreparationRejectsNegativeLambda(tc)
            [p,~]=fixture(tc);
            p.loc.norm='lambda';p.loc.lambda=-0.1;
            mv=options();mv.factors.loc.depthWeight=0.5;
            tc.verifyError(@()asct_multiverse_plan(p,mv), ...
                'ASCT:M2:InvalidLambda');
        end
    end
end

function mv=options()
mv=struct('sourceAnalysis','previous','maxRuns',8,'dryRun',true, ...
    'factors',struct());
end

function [p,folder]=fixture(tc)
folder=tempname;mkdir(folder);
tc.addTeardown(@()rmdir(folder,'s'));
mkdir(fullfile(folder,'previous','6_ICA2'));
mkdir(fullfile(folder,'previous','7_SOURCEACT'));
touchFile(fullfile(folder,'previous','6_ICA2','A1_ica2.mat'));
p.rc=struct('expFolder',folder,'analysisName','experiment', ...
    'dataRawFolder','0_raw','mriRawFolder','');
p.chan=struct();p.filter=struct();p.seg=struct();p.ar=struct();
p.ica=struct();p.loc=struct('method','mne','norm','cov', ...
    'noiseLev',2,'lambda',0.1,'depthWeight',0.5);
p.con=struct('mvarOrd',7,'varNorm',1,'conName','conn','lc',1,'unc',0);
p.design=struct('DC',struct('name',{'DC1','DC2'}));
p.begId=1;p.endId=1;
end

function out=fullRunner(p,~,~)
out=struct('stage',p.rc.load);
folder=fullfile(p.rc.expFolder,p.rc.analysisName);
if p.rc.load<=8
    touchFile(fullfile(folder,'7_SOURCEACT','icloc','A1_icloc.mat'));
end
if p.rc.load<=9
    for dc=1:2
        touchFile(fullfile(folder,'7_SOURCEACT',sprintf('DC%d',dc), ...
            'lc','A1_sigroi_lc.mat'));
    end
end
for dc=1:2
    touchFile(fullfile(folder,'8_CONN','conn','lc', ...
        sprintf('DC%d',dc),'A1_mltout.mat'));
end
end

function out=emptyRunner(~,~,~)
out=struct('stage',10);
end

function touchFile(path)
[folder,~,~]=fileparts(path);
if ~isfolder(folder), mkdir(folder); end
fid=fopen(path,'w');assert(fid>0);fwrite(fid,'mock artifact');fclose(fid);
end
