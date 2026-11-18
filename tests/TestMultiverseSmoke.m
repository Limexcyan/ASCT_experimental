classdef TestMultiverseSmoke < matlab.unittest.TestCase
    % Small smoke test of two analytical choices on exactly two trials.
    % This tests the oracle-source reference, NOT FieldTrip or production multar.
    methods (Test)
        function twoTrialsTwoPairedPathways(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            testCase.addTeardown(@() rmpath(fullfile(root,'multiverse')));
            out = tempname;
            cleaner = onCleanup(@() localCleanup(out)); %#ok<NASGU>

            result = asct_multiverse_smoke(out);
            testCase.verifyNumElements(result,2);
            testCase.verifyEqual({result.status},{'passed','passed'});
            testCase.verifyEqual(result(1).config.simSeed, ...
                result(2).config.simSeed);
            testCase.verifyEqual(result(1).output.signalSignature, ...
                result(2).output.signalSignature);
            testCase.verifyNotEqual(result(1).config.analysisIndex, ...
                result(2).config.analysisIndex);
            testCase.verifyEqual(result(1).output.nTrials,2);
            testCase.verifyEqual(result(2).output.nTrials,2);
            testCase.verifyTrue(result(1).output.oracleSourceBenchmark);
            testCase.verifyTrue(result(2).output.oracleSourceBenchmark);
            testCase.verifyTrue(isfile(fullfile(out,'smoke_metrics.csv')));
            testCase.verifyTrue(isfile(fullfile(out,'multiverse_manifest.csv')));
            testCase.verifyTrue(isfile(fullfile(out,'multiverse_results.mat')));
            T = readtable(fullfile(out,'smoke_metrics.csv'));
            testCase.verifyEqual(height(T),2);
            testCase.verifyEqual(T.nTrials,[2;2]);
            testCase.verifyEqual(sum(strcmp(T.bandMode,'wide')),1);
            testCase.verifyEqual(sum(strcmp(T.bandMode,'narrow')),1);
            testCase.verifyTrue(all(isfinite(T.f1)));
        end
    end
end

function localCleanup(path)
if isfolder(path), rmdir(path,'s'); end
end
