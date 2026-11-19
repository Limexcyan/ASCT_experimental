classdef TestMultiverseM1 < matlab.unittest.TestCase
    % Tests stage planning/cache/resume with filesystem mock outputs only.
    methods (TestClassSetup)
        function addPath(tc)
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            tc.addTeardown(@()rmpath(fullfile(root,'multiverse')));
        end
    end
    methods (Test)
        function stageDependencyGraph(tc)
            [s,g]=asct_multiverse_dependencies(struct('con',struct('varNorm',1)));
            tc.verifyEqual(s,10);
            tc.verifyEqual(g.stages,[0 8 9 10 11]);
            tc.verifyEqual(asct_multiverse_dependencies(struct('con',struct('decimate',2))),9);
            tc.verifyEqual(asct_multiverse_dependencies(struct('con',struct('lc',0))),9);
            tc.verifyEqual(asct_multiverse_dependencies(struct('loc',struct('depthWeight',1))),8);
            tc.verifyEqual(asct_multiverse_dependencies(struct('filter',struct('HPfreq',8))),0);
        end
        function nonCartesianGridFilter(tc)
            mv=opts();
            mv.maxRuns=2;
            mv.factors.con.varNorm=[0 1];
            mv.factors.con.removeERP=[false true];
            mv.includeFcn=@(c)c.con.varNorm==double(c.con.removeERP);
            s=asct_multiverse_realdata_grid(mv);
            tc.verifyNumElements(s,2);
            tc.verifyEqual({s.id},{'mv_0001','mv_0004'});
        end
        function readOnlyPlanAndCachePreview(tc)
            [p,folder]=fixture(tc);
            mkdir(fullfile(folder,'previous','6_ICA2'));
            mv=opts();
            mv.cacheStages=true;
            mv.factors.loc.depthWeight=[0 0.5];
            mv.factors.con.varNorm=[0 1];
            [plan,specs]=asct_multiverse_plan(p,mv);
            tc.verifyEqual(numel(plan),4);
            tc.verifyEqual([specs.startStep],[8 8 8 8]);
            tc.verifyEqual([plan.executionStartStep],[8 8 10 10]);
            tc.verifyFalse(isfolder(fullfile(folder,'experiment__multiverse')));
        end
        function reusesRealROIArtifacts(tc)
            [p,folder]=fixture(tc);
            mkdir(fullfile(folder,'previous','6_ICA2'));
            mv=opts(); mv.dryRun=false; mv.cacheStages=true;
            mv.factors.loc.depthWeight=[0 0.5];
            mv.factors.con.varNorm=[0 1];
            r=asct_multiverse_realdata(p,mv,@mockStageRunner);
            tc.verifyTrue(all(strcmp({r.status},'passed')));
            tc.verifyEqual([r.executionStartStep],[8 8 10 10]);
            tc.verifyEqual(r(3).reuseFrom,'experiment__mv_0001');
            tc.verifyEqual(r(4).reuseFrom,'experiment__mv_0002');
            tc.verifyEqual(r(3).output.stage,10);
            tc.verifyEqual(r(3).output.input,'experiment__mv_0001');
            report=asct_multiverse_collect(fullfile(folder,'experiment__multiverse'));
            tc.verifyEqual(report.counts.passed,4);
            tc.verifyEqual(report.reusedCount,2);
        end
        function reusesICA2AfterSTEP0(tc)
            [p,folder]=fixture(tc);
            mkdir(fullfile(folder,'0_raw'));
            mv=opts(); mv.dryRun=false; mv.cacheStages=true;
            mv.factors.filter.HPfreq=[1 8];
            mv.factors.loc.depthWeight=[0 0.5];
            r=asct_multiverse_realdata(p,mv,@mockStageRunner);
            tc.verifyEqual([r.executionStartStep],[0 0 8 8]);
            tc.verifyEqual(r(3).output.input,'experiment__mv_0001');
        end
        function reusesICLOCWithSeparateICA2(tc)
            [p,folder]=fixture(tc);
            mkdir(fullfile(folder,'previous','6_ICA2'));
            touchFile(fullfile(folder,'previous','6_ICA2','x_ica2.mat'));
            mv=opts(); mv.dryRun=false; mv.cacheStages=true;
            mv.factors.loc.depthWeight=[0 0.5];
            mv.factors.con.decimate=[1 2];
            r=asct_multiverse_realdata(p,mv,@mockStageRunner);
            tc.verifyEqual([r.executionStartStep],[8 8 9 9]);
            tc.verifyEqual(r(3).output.icloc,'experiment__mv_0001');
            tc.verifyEqual(r(3).output.ica2,'previous');
        end
        function missingArtifactsCannotBeCached(tc)
            [p,folder]=fixture(tc);
            mkdir(fullfile(folder,'previous','6_ICA2'));
            mv=opts(); mv.dryRun=false; mv.cacheStages=true;
            mv.factors.loc.depthWeight=[0 0.5];
            mv.factors.con.varNorm=[0 1];
            r=asct_multiverse_realdata(p,mv,@mockNoArtifactRunner);
            tc.verifyEqual([r.executionStartStep],[8 8 8 8]);
            tc.verifyEqual({r.reuseFrom},{'','','',''});
        end
        function resumeSkipsPassedWithoutRunner(tc)
            [p,~]=fixture(tc);
            mv=opts(); mv.dryRun=false;
            mv.factors.con.varNorm=[0 1];
            asct_multiverse_realdata(p,mv,@mockStageRunner);
            mv.resume=true;
            r=asct_multiverse_resume(p,mv,@unexpectedRunner);
            tc.verifyTrue(all(strcmp({r.status},'passed')));
            tc.verifyEqual([r.attempt],[1 1]);
        end
        function resumeArchivesOnlyIncompleteVariant(tc)
            [p,folder]=fixture(tc);
            mv=opts(); mv.dryRun=false;
            mv.factors.con.varNorm=[0 1];
            tc.verifyError(@()asct_multiverse_realdata(p,mv,@failSecondRunner), ...
                'ASCT:RealMultiverse:Stopped');
            mv.resume=true;
            mv.retryFailed=true;
            r=asct_multiverse_resume(p,mv,@mockStageRunner);
            tc.verifyTrue(all(strcmp({r.status},'passed')));
            tc.verifyEqual([r.attempt],[1 2]);
            tc.verifyTrue(isfolder(fullfile(folder,'experiment__mv_0002.incomplete_backup_0001')));
            tc.verifyTrue(isfile(fullfile(folder,'experiment__mv_0001','multiverse_setup.mat')));
        end
        function resumeStatisticsWithoutRerunningConnectivity(tc)
            [p,folder]=fixture(tc);
            p.con.conName='conn';
            p.con.contrast2test={[1 2]};
            mv=opts(); mv.dryRun=false;
            mv.runStatistics=true;
            mv.factors.con.varNorm=1;
            tc.verifyError(@()asct_multiverse_realdata(p,mv,@failStatRunner), ...
                'ASCT:RealMultiverse:Stopped');
            cp=fullfile(folder,'experiment__mv_0001','8_CONN','conn', ...
                'lc','DC1','A1_mltout.mat');
            tc.verifyTrue(isfile(cp));
            mv.resume=true; mv.retryFailed=true;
            r=asct_multiverse_resume(p,mv,@mockStatsOnlyRunner);
            tc.verifyEqual(r.status,'passed');
            tc.verifyEqual(r.connectivityStatus,'passed');
            tc.verifyEqual(r.statisticsStatus,'passed');
            tc.verifyEqual(r.output.statistics.stage,11);
            tc.verifyEqual(r.attempt,2);
            tc.verifyTrue(isfile(cp));
            tc.verifyFalse(isfolder(fullfile(folder, ...
                'experiment__mv_0001.incomplete_backup_0001')));
        end
        function resumePlanChangeCannotDamageManifest(tc)
            [p,folder]=fixture(tc);
            mv=opts(); mv.dryRun=false;
            mv.factors.con.varNorm=[0 1];
            asct_multiverse_realdata(p,mv,@mockStageRunner);
            manifest=fullfile(folder,'experiment__multiverse','realdata_manifest.csv');
            before=fileread(manifest);
            mv.resume=true; mv.factors.con.varNorm=[0 2];
            tc.verifyError(@()asct_multiverse_resume(p,mv,@mockStageRunner), ...
                'ASCT:RealMultiverse:PlanChanged');
            tc.verifyEqual(fileread(manifest),before);
        end
        function dryRunDoesNotAlterCompletedResume(tc)
            [p,folder]=fixture(tc);
            mv=opts(); mv.dryRun=false;
            mv.factors.con.varNorm=[0 1];
            asct_multiverse_realdata(p,mv,@mockStageRunner);
            manifest=fullfile(folder,'experiment__multiverse','realdata_manifest.csv');
            before=fileread(manifest);
            mv.resume=true; mv.dryRun=true;
            r=asct_multiverse_realdata(p,mv,@mockStageRunner);
            tc.verifyTrue(all(strcmp({r.status},'passed')));
            tc.verifyEqual(fileread(manifest),before);
        end
    end
end

function mv=opts()
mv=struct('sourceAnalysis','previous','maxRuns',8,'dryRun',true, ...
    'factors',struct());
end

function [p,folder]=fixture(tc)
folder=tempname; mkdir(folder);
tc.addTeardown(@()rmdir(folder,'s'));
mkdir(fullfile(folder,'previous','7_SOURCEACT'));
p.rc=struct('expFolder',folder,'analysisName','experiment','dataRawFolder','0_raw');
p.chan=struct();p.filter=struct();p.seg=struct();p.ar=struct();
p.ica=struct();p.loc=struct('method','mne','norm','cov');
p.con=struct('mvarOrd',2,'lc',1,'unc',0);
p.design=struct();
end

function out=mockStageRunner(p,~,~)
out=struct('stage',p.rc.load,'input','','icloc','','ica2','');
if isfield(p.rc,'sigroiName'), out.input=p.rc.sigroiName; end
if isfield(p.rc,'iclocName'), out.icloc=p.rc.iclocName; end
if isfield(p.rc,'ica2Name'), out.ica2=p.rc.ica2Name;out.input=p.rc.ica2Name; end
if p.rc.load==0
    touchFile(fullfile(p.rc.expFolder,p.rc.analysisName,'6_ICA2','A1_ica2.mat'));
end
if p.rc.load<=8
    touchFile(fullfile(p.rc.expFolder,p.rc.analysisName,'7_SOURCEACT', ...
        'icloc','A1_icloc.mat'));
end
if p.rc.load<=9
    touchFile(fullfile(p.rc.expFolder,p.rc.analysisName,'7_SOURCEACT', ...
        'DC1','lc','A1_sigroi_lc.mat'));
end
end

function out=mockNoArtifactRunner(p,~,~)
out=struct('stage',p.rc.load);
end

function out=failSecondRunner(p,s,~)
if strcmp(s.id,'mv_0002')
    error('ASCT:Test:PlannedFailure','Simulated interruption');
end
out=mockStageRunner(p,s,[]);
end

function touchFile(path)
[folder,~,~]=fileparts(path);
if ~isfolder(folder), mkdir(folder); end
fid=fopen(path,'w'); assert(fid~=-1); fwrite(fid,'test data'); fclose(fid);
end

function out=failStatRunner(p,s,~)
if p.rc.load==11
    error('ASCT:Test:StatsFailed','Injected statistics failure');
end
out=mockStatInputs(p,s,[]);
end

function out=mockStatInputs(p,~,~)
out=struct('stage',p.rc.load);
for dc=1:2
    touchFile(fullfile(p.rc.expFolder,p.rc.analysisName,'8_CONN','conn', ...
        'lc',sprintf('DC%d',dc),'A1_mltout.mat'));
end
end

function out=mockStatsOnlyRunner(p,~,~)
assert(p.rc.load==11,'ASCT:Test:RecomputedSTEP10', ...
    'Statistics-only resume must not re-execute connectivity');
out=struct('stage',p.rc.load);
end

function out=unexpectedRunner(~,~,~)
error('ASCT:Test:UnexpectedRun','A completed variant must be skipped');
out=struct(); %#ok<UNRCH>
end
