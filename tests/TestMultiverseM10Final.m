classdef TestMultiverseM10Final < matlab.unittest.TestCase
    methods(TestClassSetup)
        function pathSetup(tc)
            repo=fileparts(fileparts(mfilename('fullpath')));
            tc.applyFixture(matlab.unittest.fixtures.PathFixture(fullfile(repo,'multiverse')));
        end
    end
    methods(Test)
        function legacySpecRequiresCoverage(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            spec.artifacts=rmfield(spec.artifacts,'expectedCount');
            tc.verifyError(@()asct_m10_legacy_spec('id','sha', ...
                struct(),spec.artifacts),'ASCT:M10:BadLegacySpec');
        end
        function legacySpecRetainsDependencies(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            s=asct_m10_legacy_spec(spec.experimentId, ...
                spec.codeRevision,spec.parameters,spec.artifacts);
            tc.verifyEqual(s.artifacts.expectedCount,1);
        end
        function integrityAndShapePass(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            a=asct_m10_audit(fullfile(snap,'snapshot.mat'), ...
                struct('rules',rules([5 5])));
            tc.verifyTrue(a.ok);
            tc.verifyFalse(a.reuseAuthorized);
            tc.verifyEqual(a.scientificValidity,'not_assessed');
        end
        function wrongShapeFails(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            a=asct_m10_audit(fullfile(snap,'snapshot.mat'), ...
                struct('rules',rules([6 5])));
            tc.verifyFalse(a.ok);
            tc.verifyEqual(a.checks(1).status,'dimension_mismatch');
        end
        function missingMatVariableFails(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            r=rules([5 5]);r.variable='not_existing';
            a=asct_m10_audit(fullfile(snap,'snapshot.mat'),struct('rules',r));
            tc.verifyFalse(a.ok);
            tc.verifyEqual(a.checks(1).status,'missing_variable');
        end
        function corruptedSourceFailsClosed(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            x=zeros(5,5);save(fullfile(src,'data.mat'),'x');
            a=asct_m10_audit(fullfile(snap,'snapshot.mat'));
            tc.verifyFalse(a.ok);
            tc.verifyEqual(a.checks(1).status,'blocked');
        end
        function dagHasCorrectOrder(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            spec.artifacts(2)=spec.artifacts(1);
            spec.artifacts(2).id='step10';
            spec.artifacts(2).upstream={'step9'};
            asct_m10_snapshot(spec,snap);
            g=asct_m10_provenance(fullfile(snap,'snapshot.mat'));
            tc.verifyEqual(numel(g.nodes),2);
            tc.verifyEqual(g.edges(1).from,'step9');
            tc.verifyEqual(g.edges(1).to,'step10');
        end
        function reportWritesOnlyOutsideData(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            dest=[tempname '_m10report'];
            d=onCleanup(@()rm(dest)); %#ok<NASGU>
            rep=asct_m10_report(fullfile(snap,'snapshot.mat'),dest);
            tc.verifyTrue(rep.overallOk);
            tc.verifyFalse(rep.reuseAuthorized);
            tc.verifyTrue(isfile(fullfile(dest,'report.json')));
            tc.verifyTrue(isfile(fullfile(dest,'provenance.dot')));
            tc.verifyTrue(isfile(fullfile(dest,'report.md')));
            tc.verifyError(@()asct_m10_report(fullfile(snap,'snapshot.mat'),dest), ...
                'ASCT:M10:OutputExists');
        end
        function reportWithinSourceIsRejected(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            tc.verifyError(@()asct_m10_report(fullfile(snap,'snapshot.mat'), ...
                fullfile(src,'report')),'ASCT:M10:UnsafeDestination');
        end
        function movedRootPassesAndReports(tc)
            [spec,src,snap,clean]=fixture(); %#ok<ASGLU>
            c=onCleanup(clean); %#ok<NASGU>
            asct_m10_snapshot(spec,snap);
            newRoot=[tempname '_move'];mkdir(newRoot);
            d=onCleanup(@()rm(newRoot)); %#ok<NASGU>
            copyfile(fullfile(src,'data.mat'),fullfile(newRoot,'data.mat'));
            opts.roots=struct('artifactId','step9','root',newRoot);
            a=asct_m10_audit(fullfile(snap,'snapshot.mat'),opts);
            tc.verifyTrue(a.ok);
        end
    end
end
function r=rules(sz)
r=struct('artifactId','step9','relativePath','data.mat', ...
    'variable','x','dimensions',sz);
end
function [spec,root,snapshot,cleanup]=fixture()
root=[tempname '_source'];mkdir(root);
x=ones(5,5);save(fullfile(root,'data.mat'),'x');
snapshot=[tempname '_snapshot'];
a=struct('id','step9','variantId','mv_0001','stage','ROI', ...
    'root',root,'patterns',{{'data.mat'}},'upstream',{{}}, ...
    'settings',struct('method','mock'),'expectedCount',1);
spec=asct_m10_legacy_spec('mock','rev123',struct('factor',1),a);
cleanup=@()cleanupBoth(root,snapshot);
end
function cleanupBoth(a,b)
rm(a);rm(b);
end
function rm(path)
if isfolder(path),rmdir(path,'s');end
end
