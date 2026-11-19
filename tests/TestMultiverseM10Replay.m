classdef TestMultiverseM10Replay < matlab.unittest.TestCase
    % All fixtures are tiny files; no real ASCT executor, FieldTrip or EEG.
    methods(TestClassSetup)
        function sourcePath(tc)
            repo=fileparts(fileparts(mfilename('fullpath')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'multiverse')));
        end
    end
    methods(Test)
        function dryRunIsReadOnly(tc)
            [setup,specs,opts,~,out,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            opts.m5.dryRun=true;
            [p,r]=asct_m10_replay(specs,setup,opts,@(x)error('ASCT:Test:Executed','Wrong'));
            tc.verifyEqual(p(1).startStep,10);
            tc.verifyEqual(r(1).status,'pending');
            tc.verifyFalse(isfolder(out));
        end
        function connectivityReplayCopiesROIAndRegisters(tc)
            [setup,specs,opts,donor,out,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            [~,r]=asct_m10_replay(specs,setup,opts,@(p)fakeExecute(p,'ok'));
            tc.verifyEqual(r(1).status,'passed');
            tc.verifyEqual(r(1).reusedFrom,donor.artifactId);
            tc.verifyTrue(isfile(fullfile(out,'variants','mv_0001', ...
                'input_donor','7_SOURCEACT','DC1','lc','A1_sigroi_lc.mat')));
            reg=asct_m5_registry('read',out);
            tc.verifyEqual(reg.stage,'CONN');
            tc.verifyTrue(asct_m5_registry('verify',out,reg));
            tc.verifyEqual(reg.compatibility.upstream,{donor.artifactId});
            tc.verifyEqual(reg.compatibility.subjects,{'A1'});
            tc.verifyEqual(reg.compatibility.conditions,{'DC1'});
        end
        function stepEightHasStageSpecificNames(tc)
            [setup,specs,opts,~,out,clean]=fixture('ICA2',8); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            [~,r]=asct_m10_replay(specs,setup,opts,@(p)fakeExecute(p,'ok'));
            tc.verifyEqual(r(1).status,'passed');
            reg=asct_m5_registry('read',out);
            tc.verifyEqual(reg.stage,'ICLOC');
            tc.verifyTrue(isfile(fullfile(out,'variants','mv_0001', ...
                'input_donor','6_ICA2','A1_ica2.mat')));
        end
        function stepNineRequiresICA2AndICLOC(tc)
            [setup,specs,opts,~,out,clean]=fixture('ICLOC',9); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:IncompleteDonor');
            reg=asct_m5_registry('read',out);
            tc.verifyEmpty(reg);
        end
        function stepNineWithCompleteDonorRuns(tc)
            [setup,specs,opts,~,out,clean]=fixture('ICLOC',9,true); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            [~,r]=asct_m10_replay(specs,setup,opts,@(p)fakeExecute(p,'ok'));
            tc.verifyEqual(r(1).status,'passed');
            tc.verifyTrue(isfile(fullfile(out,'variants','mv_0001', ...
                'input_donor','6_ICA2','A1_ica2.mat')));
        end
        function donorIdentityMismatchRejected(tc)
            [setup,specs,opts,~,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            opts.adapter.subjects={'OTHER'};
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:DonorIdentity');
        end
        function noOutputIsExplicitFailure(tc)
            [setup,specs,opts,~,out,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'none')),'ASCT:M10:OutputCoverage');
            q=load(fullfile(out,'m5_checkpoint.mat'),'results');
            tc.verifyEqual(q.results(1).status,'failed');
        end
        function wrongOutputCountFails(tc)
            [setup,specs,opts,~,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            opts.adapter.expectedMainFiles=2;
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:OutputCoverage');
        end
        function exactOutputPathsRejectWrongDataset(tc)
            [setup,specs,opts,~,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            opts.adapter.expectedMainPaths={fullfile('8_CONN','demo','lc', ...
                'DC1','A2_mltout.mat')};
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:OutputCoverage');
        end
        function legalConnectivitySettingsApply(tc)
            [setup,specs,opts,~,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            specs.changes=struct('con',struct('mvarOrd',11));
            [~,r]=asct_m10_replay(specs,setup,opts,@(p)fakeExecute(p,'ok'));
            tc.verifyEqual(r(1).status,'passed');
        end
        function rejectsUnsafeVariantPathBeforeFiles(tc)
            [setup,specs,opts,~,out,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            specs.id='../outside';
            opts.selection.selectedVariantIds={'../outside'};
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:UnsafeVariant');
            tc.verifyFalse(isfolder(out));
        end
        function unsafeRcChangesRejected(tc)
            [setup,specs,opts,~,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            specs.changes=struct('rc',struct('analysisName','donor'));
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:UnsafeOverride');
        end
        function stepTenUpstreamChangeRejected(tc)
            [setup,specs,opts,~,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            specs.changes=struct('con',struct('decimate',4));
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M10:UpstreamChange');
        end
        function donorBitFlipRejected(tc)
            [setup,specs,opts,donor,~,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            writeText(donor.files{1},'BAD');
            tc.verifyError(@()asct_m10_replay(specs,setup,opts, ...
                @(p)fakeExecute(p,'ok')),'ASCT:M5:CorruptArtifact');
        end
        function resumeSkipsPreviouslyPassed(tc)
            [setup,specs,opts,~,out,clean]=fixture('ROI',10); %#ok<ASGLU>
            c=onCleanup(@()clean()); %#ok<NASGU>
            [~,r1]=asct_m10_replay(specs,setup,opts,@(p)fakeExecute(p,'ok'));
            tc.verifyEqual(r1(1).status,'passed');
            opts.m5.resume=true;
            [~,r2]=asct_m10_replay(specs,setup,opts, ...
                @(p)error('ASCT:Test:Reexecuted','Should skip'));
            tc.verifyEqual(r2(1).status,'passed');
            tc.verifyTrue(isfile(fullfile(out,'m5_checkpoint.mat')));
        end
    end
end

function [setup,specs,opts,donor,out,cleanup]=fixture(stage,step,includeICA)
if nargin<3,includeICA=false;end
repo=fileparts(fileparts(mfilename('fullpath')));
identity=asct_m5_git_identity(repo);
assert(~identity.gitDirty,'ASCT:Test:DirtyRepo','CI test expects a clean checkout');
source=tempname;mkdir(source);
out=tempname;
setup=struct('rc',struct('expFolder','/unused_source','analysisName','baseline', ...
    'sim',[],'simStats',0,'dataRawFolder','raw'), ...
    'chan',struct(),'filter',struct(),'seg',struct(),'ar',struct(), ...
    'ica',struct(),'loc',struct(), ...
    'con',struct('conName','demo'), 'design',struct());
specs=struct('id','mv_0001','changes',struct());
c=struct('dataset','fixture','subjects',{{'A1'}}, ...
    'conditions',{{'DC1'}},'stageSettings',struct('source','fixture'), ...
    'upstream',{{}});
files={};
switch stage
    case 'ICA2'
        files={fullfile(source,'variants','source','output','6_ICA2','A1_ica2.mat')};
    case 'ICLOC'
        files={fullfile(source,'variants','source','output','7_SOURCEACT','icloc','A1_icloc.mat')};
        if includeICA
            files{end+1}=fullfile(source,'variants','source','output','6_ICA2','A1_ica2.mat');
        end
    case 'ROI'
        files={fullfile(source,'variants','source','output','7_SOURCEACT', ...
            'DC1','lc','A1_sigroi_lc.mat')};
end
for i=1:numel(files)
    folder=fileparts(files{i});if ~isfolder(folder),mkdir(folder);end
    writeText(files{i},'OK');
end
donor=struct('artifactId','donor__mv_0001__stage', ...
    'stage',stage,'producerRunId','donor','producerVariantId','mv_0001', ...
    'gitRevision',identity.gitRevision,'gitDirty',false, ...
    'compatibility',c,'files',{files});
asct_m5_registry('add',source,donor);
m5=struct('outputRoot',out,'runId','replay','gitRevision',identity.gitRevision, ...
    'gitDirty',false,'inputs',struct('variantId','mv_0001','compatibility',c), ...
    'donorRoots',{{source}},'repoRoot',repo,'dryRun',false);
opts=struct('selection',struct('startStep',step,'stopStep',step), ...
    'm5',m5,'adapter',struct('dataset','fixture','subjects',{{'A1'}}, ...
    'conditions',{{'DC1'}},'expectedMainFiles',1));
cleanup=@()cleanupDirs({source,out});
end
function fakeExecute(p,mode)
assert(p.rc.load>=8 && p.rc.stop>=p.rc.load && p.rc.stop<=10);
assert(strcmp(p.rc.analysisFolder,fullfile(p.rc.expFolder,p.rc.analysisName)));
switch p.rc.load
    case 8
        assert(strcmp(p.rc.ica2Name,'input_donor'));
    case 9
        assert(strcmp(p.rc.ica2Name,'input_donor'));
        assert(strcmp(p.rc.iclocName,'input_donor'));
    case 10
        assert(strcmp(p.rc.sigroiName,'input_donor'));
end
if strcmp(mode,'none'),return;end
switch p.rc.stop
    case 8
        target=fullfile(p.rc.analysisFolder,'7_SOURCEACT','icloc','A1_icloc.mat');
    case 9
        target=fullfile(p.rc.analysisFolder,'7_SOURCEACT','DC1','lc','A1_sigroi_lc.mat');
    case 10
        target=fullfile(p.rc.analysisFolder,'8_CONN',p.con.conName,'lc','DC1','A1_mltout.mat');
end
folder=fileparts(target);if ~isfolder(folder),mkdir(folder);end
writeText(target,'MATTEST');
end
function writeText(p,value)
f=fopen(p,'w');assert(f>0);fwrite(f,value,'char');fclose(f);
end
function cleanupDirs(dirs)
for i=1:numel(dirs)
    if isfolder(dirs{i}),rmdir(dirs{i},'s');end
end
end
