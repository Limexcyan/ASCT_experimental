classdef TestMultiverseM10 < matlab.unittest.TestCase
    % Opt-in provenance inventory; tests never require EEG or FieldTrip.
    methods (Test)
        function snapshotAndVerifyExactHashes(tc)
            root=tempname; mkdir(root);
            out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root);
            s=fixture(root);
            m=asct_m10_snapshot(s,out);
            tc.verifyTrue(isfile(fullfile(out,'snapshot.mat')));
            tc.verifyTrue(isfile(fullfile(out,'snapshot.json')));
            tc.verifyEqual(numel(m.artifacts),2);
            tc.verifyEqual(m.artifacts(2).upstream,{'roi'});
            r=asct_m10_verify(fullfile(out,'snapshot.mat'));
            tc.verifyTrue(r.ok);
            tc.verifyEqual(numel(r.files),3);
            tc.verifyEqual(numel(r.artifacts),2);
            tc.verifyEqual(r.hashMode,'sha256');
        end
        function detectsSameSizeCorruption(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root);
            asct_m10_snapshot(fixture(root),out);
            writeText(fullfile(root,'ROI','A1.mat'),'BAD!');
            r=asct_m10_verify(fullfile(out,'snapshot.mat'));
            tc.verifyFalse(r.ok);
            tc.verifyFalse(r.complete);
            tc.verifyTrue(any(strcmp({r.files.status},'hash_mismatch')));
        end
        function detectsMissingArtifact(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root);
            asct_m10_snapshot(fixture(root),out);
            delete(fullfile(root,'CONN','A1.mat'));
            r=asct_m10_verify(fullfile(out,'snapshot.mat'));
            tc.verifyFalse(r.complete);
            tc.verifyTrue(any(strcmp({r.files.status},'missing')));
        end
        function rejectsMissingPatternBeforeWrites(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root); s=fixture(root);
            s.artifacts(1).patterns={'ROI/no-such-file*.mat'};
            tc.verifyError(@()asct_m10_snapshot(s,out),'ASCT:M10:MissingPattern');
            tc.verifyFalse(isfolder(out));
        end
        function rejectsPathTraversalAndCycles(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root); s=fixture(root);
            s.artifacts(1).patterns={'../outside.mat'};
            tc.verifyError(@()asct_m10_snapshot(s,out),'ASCT:M10:BadPattern');
            s=fixture(root);
            s.artifacts(1).upstream={'conn'};
            tc.verifyError(@()asct_m10_snapshot(s,out),'ASCT:M10:BadDependency');
        end
        function expectedCountBlocksPartialImport(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root); s=fixture(root);
            s.artifacts(1).expectedCount=3;
            s.artifacts(2).expectedCount=1;
            tc.verifyError(@()asct_m10_snapshot(s,out),'ASCT:M10:FileCount');
            tc.verifyFalse(isfolder(out));
        end
        function existingOutputNeverOverwritten(tc)
            root=tempname; mkdir(root); out=tempname; mkdir(out);
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root);
            tc.verifyError(@()asct_m10_snapshot(fixture(root),out), ...
                'ASCT:M10:OutputExists');
            tc.verifyFalse(isfile(fullfile(out,'snapshot.mat')));
        end
        function sizeModeNeverCountsAsVerified(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root);
            asct_m10_snapshot(fixture(root),out,struct('hashMode','size'));
            r=asct_m10_verify(fullfile(out,'snapshot.mat'));
            tc.verifyTrue(r.complete);
            tc.verifyFalse(r.ok);
            tc.verifyTrue(all(strcmp({r.artifacts.status},'inventory_only')));
        end
        function movedRootsCanBeVerified(tc)
            root=tempname; mkdir(root); other=tempname; mkdir(other);
            out=tempname;
            c=onCleanup(@()cleanupDirs({root,other,out})); %#ok<NASGU>
            makeFiles(root); makeFiles(other);
            asct_m10_snapshot(fixture(root),out);
            delete(fullfile(root,'ROI','A1.mat'));
            overrides=struct('artifactId',{'roi','conn'}, ...
                'root',{other,other});
            r=asct_m10_verify(fullfile(out,'snapshot.mat'), ...
                struct('roots',overrides));
            tc.verifyTrue(r.ok);
        end
        function tamperedManifestFailsClosed(tc)
            root=tempname; mkdir(root); out=tempname;
            c=onCleanup(@() cleanupDirs({root,out})); %#ok<NASGU>
            makeFiles(root);
            asct_m10_snapshot(fixture(root),out);
            p=fullfile(out,'snapshot.mat');
            q=load(p,'manifest'); manifest=q.manifest;
            manifest.parameters.band='narrow';
            save(p,'manifest','-v7');
            tc.verifyError(@()asct_m10_verify(p),'ASCT:M10:SnapshotChanged');
        end
    end
end
function s=fixture(root)
a(1)=struct('id','roi','variantId','mv_0001','stage','ROI', ...
    'root',root,'patterns',{{'ROI/*.mat'}}, ...
    'upstream',{{}},'settings',struct('roiCount',5));
a(2)=struct('id','conn','variantId','mv_0001','stage','CONN', ...
    'root',root,'patterns',{{'CONN/*.mat'}}, ...
    'upstream',{{'roi'}},'settings',struct('varOrder',7));
s=struct('experimentId','test_recovery','codeRevision','revision-for-fixture', ...
    'parameters',struct('band','wide','numberOfROIs',5), ...
    'artifacts',a);
end
function makeFiles(root)
if ~isfolder(fullfile(root,'ROI')), mkdir(fullfile(root,'ROI')); end
if ~isfolder(fullfile(root,'CONN')), mkdir(fullfile(root,'CONN')); end
writeText(fullfile(root,'ROI','A1.mat'),'GOOD');
writeText(fullfile(root,'ROI','A2.mat'),'MORE');
writeText(fullfile(root,'CONN','A1.mat'),'DATA');
end
function writeText(p,s)
fid=fopen(p,'w'); assert(fid>0);
fwrite(fid,s,'char');fclose(fid);
end
function cleanupDirs(paths)
for k=1:numel(paths), if isfolder(paths{k}),rmdir(paths{k},'s');end,end
end
