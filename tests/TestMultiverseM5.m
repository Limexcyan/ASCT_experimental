classdef TestMultiverseM5 < matlab.unittest.TestCase
    % Tests for the independent M5 core; does not require raw EEG or FieldTrip.
    methods (Test)
        function selectedIdsStable(tc)
            specs=struct('id',{'mv_0001','mv_0002','mv_0003'});
            o=struct('selectedVariantIds',{{'mv_0003','mv_0001'}}, ...
                'startStep',8,'stopStep',9);
            p=asct_m5_plan(specs,o);
            tc.verifyEqual(string({p.id}),["mv_0001" "mv_0003"]);
            tc.verifyEqual([p.stopStep],[9 9]);
        end
        function unsupportedRangeRejected(tc)
            s=struct('id','mv_0001');
            tc.verifyError(@()asct_m5_plan(s,struct('startStep',10,'stopStep',9)), ...
                'ASCT:M5:InvalidRange');
            tc.verifyError(@()asct_m5_plan(s,struct('startStep',5,'stopStep',10)), ...
                'ASCT:M5:StartStep');
        end
        function registryMatchesOnlyVerifiedData(tc)
            root=tempname; mkdir(root); c=onCleanup(@() rmdir(root,'s')); %#ok<NASGU>
            p=fullfile(root,'roi.mat'); writeBytes(p,'sample ROI');
            compat=compatibility();
            e=artifact(p,compat,'ROI','runA','v1','revisionA');
            asct_m5_registry('add',root,e);
            req=struct('stage','ROI','compatibility',compat,'gitRevision','revisionA');
            donor=asct_m5_find({root},req);
            tc.verifyEqual(donor.artifact.artifactId,'runA__v1__ROI');
            req.gitRevision='revisionB';
            tc.verifyError(@()asct_m5_find({root},req),'ASCT:M5:NoCompatibleDonor');
            req.gitRevision='revisionA';
            req.compatibility.stageSettings=struct('band','narrow');
            tc.verifyError(@()asct_m5_find({root},req),'ASCT:M5:NoCompatibleDonor');
            req.compatibility=compat;
            writeBytes(p,'altered ROI');
            tc.verifyError(@()asct_m5_find({root},req),'ASCT:M5:CorruptArtifact');
        end
        function dryRunIsReadOnly(tc)
            folder=tempname;
            plan=asct_m5_plan(struct('id','mv_0001'),struct('startStep',0,'stopStep',10));
            o=opts(folder); o.dryRun=true;
            r=asct_m5_run(plan,o,@fakeRunner);
            tc.verifyEqual(r.status,'pending');
            tc.verifyFalse(isfolder(folder));
        end
        function runAndResume(tc)
            root=tempname; c=onCleanup(@() cleanupFolder(root)); %#ok<NASGU>
            p=asct_m5_plan(struct('id','mv_0001'),struct('startStep',0,'stopStep',10));
            o=opts(root); o.dryRun=false;
            r=asct_m5_run(p,o,@fakeRunner);
            tc.verifyEqual(r.status,'passed');
            tc.verifyTrue(isfile(fullfile(root,'m5_registry.mat')));
            o.resume=true;
            r=asct_m5_run(p,o,@mustNotExecute);
            tc.verifyEqual(r.status,'passed');
            o.gitRevision='different';
            tc.verifyError(@()asct_m5_run(p,o,@fakeRunner),'ASCT:M5:PlanChanged');
        end
        function failedAttemptArchivedOnRetry(tc)
            root=tempname; c=onCleanup(@()cleanupFolder(root)); %#ok<NASGU>
            p=asct_m5_plan(struct('id','mv_0001'),struct('startStep',0,'stopStep',10));
            o=opts(root);o.dryRun=false;
            tc.verifyError(@()asct_m5_run(p,o,@failAfterWrite),'ASCT:M5:TestFailure');
            o.resume=true;
            tc.verifyError(@()asct_m5_run(p,o,@fakeRunner),'ASCT:M5:IncompleteOutput');
            o.retryFailed=true;
            r=asct_m5_run(p,o,@fakeRunner);
            tc.verifyEqual(r.status,'passed');
            tc.verifyEqual(r.attempt,2);
            tc.verifyTrue(isfolder(fullfile(root,'variants','mv_0001.incomplete_backup_0001')));
        end
        function crossRunUsesExactRoi(tc)
            base=tempname;mkdir(base);c=onCleanup(@()cleanupFolder(base)); %#ok<NASGU>
            a=fullfile(base,'donor');mkdir(a);
            p=fullfile(a,'roi.mat');writeBytes(p,'good data');
            cmp=compatibility();
            e=artifact(p,cmp,'ROI','runA','mv_0001','revisionA');
            asct_m5_registry('add',a,e);
            runroot=fullfile(base,'consumer');
            plan=asct_m5_plan(struct('id','mv_0001'),struct('startStep',10,'stopStep',10));
            o=opts(runroot);o.dryRun=false;
            o.donorRoots={a};
            o.inputs=struct('variantId','mv_0001','compatibility',cmp);
            r=asct_m5_run(plan,o,@fakeRunner);
            tc.verifyEqual(r.status,'passed');
            tc.verifyEqual(r.reusedFrom,e.artifactId);
            tc.verifyTrue(isfile(p)); % donor not moved or modified
        end
    end
end
function o=opts(folder)
o=struct('outputRoot',folder,'runId','runB', ...
    'gitRevision','revisionA','gitDirty',false,'dryRun',true, ...
    'resume',false,'retryFailed',false,'donorRoots',{{}},'inputs',struct([]));
end
function c=compatibility()
c=struct('dataset','Flanker','subjects',{{'A1'}},'conditions',{{'DC1','DC2'}}, ...
    'stageSettings',struct('band','wide'), 'upstream',{{}});
end
function e=artifact(p,c,stage,run,id,rev)
e=struct('artifactId',[run '__' id '__' stage], 'stage',stage, ...
    'producerRunId',run,'producerVariantId',id, ...
    'gitRevision',rev,'gitDirty',false, ...
    'compatibility',c,'files',{{p}});
end
function r=fakeRunner(item,donor,folder)
p=fullfile(folder,'result.mat');writeBytes(p,'M5 test data');
c=compatibility();
if ~isempty(donor)
    c.upstream={donor.artifact.artifactId};
else
    c.upstream={};
end
s='CONN';if item.stopStep==8,s='ICLOC';end
if item.stopStep==9,s='ROI';end
r=struct('executedStartStep',item.startStep, ...
    'executedStopStep',item.stopStep,'stage',s, ...
    'files',{{p}},'compatibility',c);
if ~isempty(donor),r.usedDonorArtifactId=donor.artifact.artifactId;end
end
function r=mustNotExecute(~,~,~)
r=[]; %#ok<NASGU>
error('ASCT:M5:ShouldNotRun','Passed variant should be skipped');
end
function r=failAfterWrite(~,~,folder)
r=[]; %#ok<NASGU>
writeBytes(fullfile(folder,'partial.mat'),'incomplete');
error('ASCT:M5:TestFailure','Intentional failure for retry test');
end
function writeBytes(p,content)
f=fopen(p,'w');assert(f>0);fwrite(f,content,'char');fclose(f);
end
function cleanupFolder(p)
if isfolder(p),rmdir(p,'s');end
end
