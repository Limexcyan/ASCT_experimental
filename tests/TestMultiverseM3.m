classdef TestMultiverseM3 < matlab.unittest.TestCase
    % Parallel safety, paired STEP0 passbands, read-only metric plugins.
    methods (TestClassSetup)
        function addPath(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'),fullfile(root,'pipelineSC'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse'), ...
                fullfile(root,'pipelineSC')));
        end
    end
    methods (Test)
        function zeroWorkersMeansSerialParfor(tc)
            tc.verifyEqual(sc_parallelWorkerLimit(struct('useParallel',0)),0);
            tc.verifyEqual(sc_parallelWorkerLimit(struct()),0);
            tc.verifyEqual(sc_parallelWorkerLimit(struct('useParallel',2)),2);
            tc.verifyError(@()sc_parallelWorkerLimit(struct('useParallel',-1)), ...
                'ASCT:Parallel:InvalidWorkers');
            tc.verifyError(@()sc_parallelWorkerLimit(struct('useParallel',0.5)), ...
                'ASCT:Parallel:InvalidWorkers');
        end
        function bothSourceStagesUseExplicitParforLimit(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            a=fileread(fullfile(root,'pipelineSC','sc_6_SOURCE_LOC_ICA.m'));
            b=fileread(fullfile(root,'pipelineSC','sc_7_SIG_RECON.m'));
            tc.verifyTrue(contains(a,'parfor (ds = 1:length(infile), asctWorkerLimit)'));
            tc.verifyTrue(contains(b,'parfor (ds = 1:length(infile), asctWorkerLimit)'));
            tc.verifyTrue(contains(a,'sc_parallelWorkerLimit(rc)'));
            tc.verifyTrue(contains(b,'sc_parallelWorkerLimit(rc)'));
        end
        function pairedBandsExpandWithoutCartesianMistakes(tc)
            [p,~]=fixture(tc);
            mv=options(); mv.maxRuns=4;
            mv.factors.filter.bandHz={[2 48],[8 12]};
            mv.factors.con.varNorm=[0 1];
            [plan,specs]=asct_multiverse_plan(p,mv);
            tc.verifyNumElements(specs,4);
            tc.verifyEqual([specs.startStep],[0 0 0 0]);
            tc.verifyEqual([plan.requiredStartStep],[0 0 0 0]);
            tc.verifyEqual(specs(1).changes.filter.HPfreq,2);
            tc.verifyEqual(specs(1).changes.filter.LPfreq,48);
            tc.verifyEqual(specs(2).changes.filter.HPfreq,8);
            tc.verifyEqual(specs(2).changes.filter.LPfreq,12);
            tc.verifyFalse(isfield(specs(1).changes.filter,'bandHz'));
        end
        function singleNumericBandIsOneChoice(tc)
            mv=options(); mv.factors.filter.bandHz=[4 30];
            specs=asct_multiverse_realdata_grid(mv);
            tc.verifyNumElements(specs,1);
            tc.verifyEqual(specs.changes.filter.HPfreq,4);
            tc.verifyEqual(specs.changes.filter.LPfreq,30);
        end
        function invalidAndConflictingBandsAreRejected(tc)
            mv=options();mv.factors.filter.bandHz={[15 10]};
            tc.verifyError(@()asct_multiverse_realdata_grid(mv), ...
                'ASCT:STEP0:InvalidBand');
            mv.factors.filter.bandHz={[2 48],[8 12]};
            mv.factors.filter.HPfreq=[2 8];
            tc.verifyError(@()asct_multiverse_realdata_grid(mv), ...
                'ASCT:STEP0:ConflictingBands');
        end
        function effectiveFilterValidation(tc)
            f=struct('HPfreq',2,'LPfreq',48,'resampleTo',0, ...
                'HPord',846,'LPord',282);
            tc.verifyEqual(asct_multiverse_validate_filter(f),f);
            f.HPfreq=50;
            tc.verifyError(@()asct_multiverse_validate_filter(f), ...
                'ASCT:STEP0:InvalidBand');
            f.HPfreq=2;f.resampleTo=80;
            tc.verifyError(@()asct_multiverse_validate_filter(f), ...
                'ASCT:STEP0:Nyquist');
            f.resampleTo=0;f.LPord=1.5;
            tc.verifyError(@()asct_multiverse_validate_filter(f), ...
                'ASCT:STEP0:InvalidOrder');
        end
        function step0RequiresRawInputsBeforeAnyOutput(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.factors.filter.bandHz={[2 48],[8 12]};
            tc.verifyError(@()asct_multiverse_realdata(p,mv), ...
                'ASCT:RealMultiverse:MissingInput');
            tc.verifyFalse(isfolder(fullfile(folder,'experiment__multiverse')));
        end
        function rawBandsReuseOnlyCompatibleROI(tc)
            [p,folder]=fixture(tc);
            mkdir(fullfile(folder,'0_raw'));
            mv=options();mv.maxRuns=4;mv.dryRun=false;mv.cacheStages=true;
            mv.factors.filter.bandHz={[2 48],[8 12]};
            mv.factors.con.varNorm=[0 1];
            r=asct_multiverse_realdata(p,mv,@mockRunner);
            tc.verifyTrue(all(strcmp({r.status},'passed')));
            tc.verifyEqual([r.executionStartStep],[0 0 10 10]);
            tc.verifyEqual(r(3).reuseFrom,'experiment__mv_0001');
            tc.verifyEqual(r(4).reuseFrom,'experiment__mv_0002');
            tc.verifyTrue(isfile(fullfile(folder,'experiment__mv_0001', ...
                '6_ICA2','A1_ica2.mat')));
        end
        function standaloneMetricsReadSavedData(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.dryRun=false;mv.factors.con.varNorm=[0 1];
            asct_multiverse_realdata(p,mv,@mockRunner);
            root=fullfile(folder,'experiment__multiverse');
            plugins=struct('name','artifacts','fn',@asct_multiverse_metric_artifacts);
            T=asct_multiverse_metrics(root,plugins);
            tc.verifyEqual(height(T),2);
            tc.verifyTrue(all(T.status=="passed"));
            v=jsondecode(char(T.valuesJson(1)));
            tc.verifyEqual(v.connectivityFiles,2);
            tc.verifyEqual(v.roiFilesAvailable,2);
            tc.verifyTrue(isfile(fullfile(root,'multiverse_metric_results.mat')));
            tc.verifyTrue(isfile(fullfile(root,'multiverse_metric_results.csv')));
            old=load(fullfile(root,'realdata_results.mat'),'results');
            tc.verifyTrue(all(strcmp({old.results.status},'passed')));
        end
        function metricsRunAutomaticallyWhenRequested(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.dryRun=false;mv.factors.con.varNorm=0;
            mv.metrics=struct('name','constant','fn',@constantMetric);
            asct_multiverse_realdata(p,mv,@mockRunner);
            root=fullfile(folder,'experiment__multiverse');
            T=readtable(fullfile(root,'multiverse_metric_results.csv'), ...
                'FileType','text','Delimiter',',','ReadVariableNames',true, ...
                'VariableNamingRule','preserve','TextType','string');
            tc.verifyEqual(string(T.metricName),"constant");
            tc.verifyEqual(string(T.status),"passed");
            decoded=jsondecode(char(T.valuesJson(1)));
            tc.verifyEqual(decoded.score,42);
        end
        function pluginErrorsDoNotInvalidateCompletedPipeline(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.dryRun=false;mv.factors.con.varNorm=0;
            asct_multiverse_realdata(p,mv,@mockRunner);
            root=fullfile(folder,'experiment__multiverse');
            before=fileread(fullfile(root,'realdata_manifest.csv'));
            plugins=struct('name','failing','fn',@failingMetric);
            T=asct_multiverse_metrics(root,plugins);
            tc.verifyEqual(T.status,"failed");
            tc.verifyEqual(fileread(fullfile(root,'realdata_manifest.csv')),before);
            old=load(fullfile(root,'realdata_results.mat'),'results');
            tc.verifyEqual(old.results.status,'passed');
        end
        function groundTruthPluginRequiresExplicitAlignedTruth(tc)
            root=tempname;mkdir(root);
            tc.addTeardown(@()rmdir(root,'s'));
            d=fullfile(root,'8_CONN','conn','lc','DC1');
            mkdir(d);
            NDTF=zeros(2,2,3);
            NDTF(1,2,:)=0.9;
            save(fullfile(d,'A1_mltout.mat'),'NDTF');
            p.con=struct('conName','conn');
            ctx=struct('analysisFolder',root);
            tc.verifyError(@()asct_multiverse_metric_truth(p,struct(),ctx), ...
                'ASCT:Metrics:MissingTruth');
            p.truthConnectivity=logical([0 1;0 0]);
            v=asct_multiverse_metric_truth(p,struct(),ctx);
            tc.verifyEqual(v.meanF1,1);
            tc.verifyEqual(v.meanFalsePositiveRate,0);
            tc.verifyEqual(v.evaluatedFiles,1);
        end
        function duplicatePluginsFailBeforeExecution(tc)
            [p,folder]=fixture(tc);
            mv=options();mv.dryRun=false;mv.factors.con.varNorm=0;
            mv.metrics=struct('name',{'A','a'}, ...
                'fn',{@constantMetric,@constantMetric});
            tc.verifyError(@()asct_multiverse_realdata(p,mv,@mockRunner), ...
                'ASCT:Metrics:DuplicateName');
            tc.verifyFalse(isfolder(fullfile(folder,'experiment__multiverse')));
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
mkdir(fullfile(folder,'previous','7_SOURCEACT'));
mkdir(fullfile(folder,'previous','6_ICA2'));
for dc=1:2
    touchFile(fullfile(folder,'previous','7_SOURCEACT',sprintf('DC%d',dc), ...
        'lc','A1_sigroi_lc.mat'));
end
p.rc=struct('expFolder',folder,'analysisName','experiment', ...
    'dataRawFolder','0_raw','mriRawFolder','','useParallel',0);
p.chan=struct();
p.filter=struct('HPfreq',2,'LPfreq',48,'resampleTo',0);
p.seg=struct();p.ar=struct();p.ica=struct();
p.loc=struct('method','mne','norm','cov','noiseLev',2, ...
    'lambda',0.1,'depthWeight',0.5);
p.con=struct('mvarOrd',7,'varNorm',1,'conName','conn','lc',1,'unc',0);
p.design=struct('DC',struct('name',{'DC1','DC2'}));
p.begId=1;p.endId=1;
end

function out=mockRunner(p,~,~)
out=struct('stage',p.rc.load);
folder=fullfile(p.rc.expFolder,p.rc.analysisName);
if p.rc.load<=0
    touchFile(fullfile(folder,'6_ICA2','A1_ica2.mat'));
end
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

function values=constantMetric(~,~,~)
values=struct('score',42);
end

function values=failingMetric(~,~,~) %#ok<STOUT>
error('ASCT:Test:MetricsInjectedFailure','Expected metric callback failure');
end

function touchFile(f)
[d,~,~]=fileparts(f);
if ~isfolder(d), mkdir(d); end
fid=fopen(f,'w');assert(fid>0);fwrite(fid,'mock artifact');fclose(fid);
end
