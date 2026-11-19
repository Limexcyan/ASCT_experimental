classdef TestMultiverseM10Diff < matlab.unittest.TestCase
    % M10.2 manifest-only semantic comparison. Does not require real EEG.
    methods (TestClassSetup)
        function addSourcePath(tc)
            repoRoot=fileparts(fileparts(mfilename('fullpath')));
            sourceDir=fullfile(repoRoot,'multiverse');
            tc.assertTrue(isfolder(sourceDir));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(sourceDir));
        end
    end
    methods (Test)
        function sameMetadataAcrossRootsIsEquivalent(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            asct_m10_snapshot(s1,p1);
            asct_m10_snapshot(s2,p2);
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            tc.verifyTrue(d.metadataEquivalent);
            tc.verifyEqual(d.summary.filesUnchanged,3);
            tc.verifyEqual(d.summary.artifactsUnchanged,2);
            tc.verifyTrue(all([d.artifacts.rootRelocated]));
            tc.verifyEqual(d.scope,'manifest_only');
        end
        function nestedParametersAreExplained(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            s2.parameters.model.nested.lambda=5;
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            tc.verifyFalse(d.metadataEquivalent);
            tc.verifyEqual({d.parameterChanges.path},{'parameters.model.nested.lambda'});
            tc.verifyEqual(d.parameterChanges.before,'2');
            tc.verifyEqual(d.parameterChanges.after,'5');
            tc.verifyEqual(d.summary.filesUnchanged,3);
        end
        function sameSizeChangedBytesAreDetected(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            writeText(fullfile(s2.artifacts(1).root,'ROI','A1.mat'),'FAIL');
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            tc.verifyEqual(d.summary.filesModified,1);
            tc.verifyEqual(d.summary.artifactsModified,1);
            tc.verifyEqual(d.summary.artifactsUnchanged,1);
            tc.verifyFalse(d.metadataEquivalent);
        end
        function dependencyAndSettingsDivergenceIsExplained(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            s2.artifacts(2).upstream={};
            s2.artifacts(2).settings.pord=9;
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            ix=find(strcmp({d.artifacts.id},'conn'));
            tc.verifyEqual(d.artifacts(ix).status,'modified');
            tc.verifyEqual(d.artifacts(ix).upstreamRemoved,{'roi'});
            tc.verifyEqual({d.artifacts(ix).settingsChanges.path},{'settings.pord'});
            tc.verifyEqual(d.summary.filesUnchanged,3);
        end
        function addedRemovedStagesAreSymmetric(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            s2.artifacts=s2.artifacts(1);
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            a=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            b=asct_m10_diff(fullfile(p2,'snapshot.mat'),fullfile(p1,'snapshot.mat'));
            tc.verifyEqual(a.summary.artifactsRemoved,1);
            tc.verifyEqual(a.summary.filesRemoved,1);
            tc.verifyEqual(b.summary.artifactsAdded,1);
            tc.verifyEqual(b.summary.filesAdded,1);
        end
        function sizeOnlyNeverCountsAsEqualFiles(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            asct_m10_snapshot(s1,p1);
            asct_m10_snapshot(s2,p2,struct('hashMode','size'));
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            tc.verifyEqual(d.summary.filesUnverified,3);
            tc.verifyEqual(d.summary.artifactsUnverified,2);
            tc.verifyFalse(d.metadataEquivalent);
        end
        function recordingOrderDoesNotChangeSemantics(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            f=fullfile(p2,'snapshot.mat');
            z=load(f,'manifest');manifest=z.manifest;
            manifest.artifacts(1).files=manifest.artifacts(1).files([2,1]);
            manifest.snapshotDigest=asct_m5_digest(rmfield(manifest,'snapshotDigest'));
            save(f,'manifest','-v7');
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),f);
            tc.verifyTrue(d.metadataEquivalent);
            tc.verifyEqual(d.summary.filesUnchanged,3);
        end
        function tamperedSnapshotIsRejected(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            f=fullfile(p2,'snapshot.mat');
            z=load(f,'manifest');manifest=z.manifest;
            manifest.parameters.model.nested.lambda=77;
            save(f,'manifest','-v7');
            tc.verifyError(@()asct_m10_diff(fullfile(p1,'snapshot.mat'),f), ...
                'ASCT:M10:SnapshotChanged');
        end
        function absentSnapshotFailsClosed(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            asct_m10_snapshot(s1,p1);
            tc.verifyError(@()asct_m10_diff(fullfile(p1,'snapshot.mat'), ...
                fullfile(p2,'snapshot.mat')), 'ASCT:M10:MissingSnapshot');
        end
        function sourceDataNotAccessedAfterSnapshot(tc)
            [s1,s2,p1,p2,c]=makePair(); %#ok<ASGLU>
            asct_m10_snapshot(s1,p1);asct_m10_snapshot(s2,p2);
            delete(fullfile(s1.artifacts(1).root,'ROI','A1.mat'));
            delete(fullfile(s2.artifacts(2).root,'CONN','A1.mat'));
            d=asct_m10_diff(fullfile(p1,'snapshot.mat'),fullfile(p2,'snapshot.mat'));
            tc.verifyTrue(d.metadataEquivalent);
            integrity=asct_m10_verify(fullfile(p1,'snapshot.mat'));
            tc.verifyFalse(integrity.ok);
        end
    end
end

function [s1,s2,p1,p2,cleanup]=makePair()
base=tempname;mkdir(base);
cleanup=onCleanup(@()cleanupDir(base));
root1=fullfile(base,'sourceA');root2=fullfile(base,'sourceB');
mkdir(root1);mkdir(root2);
makeFiles(root1);makeFiles(root2);
s1=makeSpec(root1);s2=makeSpec(root2);
p1=fullfile(base,'snapshotA');p2=fullfile(base,'snapshotB');
end
function s=makeSpec(root)
a(1)=struct('id','roi','variantId','mv_0001','stage','STEP9', ...
    'root',root,'patterns',{{'ROI/*.mat'}}, ...
    'upstream',{{}},'settings',struct('roiCount',5),'expectedCount',2);
a(2)=struct('id','conn','variantId','mv_0001','stage','STEP10', ...
    'root',root,'patterns',{{'CONN/*.mat'}}, ...
    'upstream',{{'roi'}},'settings',struct('pord',7),'expectedCount',1);
s=struct('experimentId','test-multiverse','codeRevision','abcd1234', ...
    'parameters',struct('model',struct('nested',struct('lambda',2)), ...
    'band','wide'), 'artifacts',a);
end
function makeFiles(root)
mkdir(fullfile(root,'ROI'));mkdir(fullfile(root,'CONN'));
writeText(fullfile(root,'ROI','A1.mat'),'GOOD');
writeText(fullfile(root,'ROI','A2.mat'),'MORE');
writeText(fullfile(root,'CONN','A1.mat'),'DATA');
end
function writeText(p,s)
fid=fopen(p,'w');assert(fid>0);fwrite(fid,s,'char');fclose(fid);
end
function cleanupDir(root)
if isfolder(root),rmdir(root,'s');end
end
