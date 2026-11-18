classdef TestMultiverseReplicates < matlab.unittest.TestCase
    % Independent simulations, paired analytical paths, proper CI unit.
    methods (Test)
        function replicatesArePairedIndependentAndDeterministic(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            testCase.addTeardown(@()rmpath(fullfile(root,'multiverse')));
            out = tempname; out2 = tempname;
            cleaner = onCleanup(@()localCleanup(out,out2)); %#ok<NASGU>
            rngBefore = rng;
            [paired,summary] = asct_multiverse_replicates(out,3,40);
            testCase.verifyEqual(rng,rngBefore);
            testCase.verifyEqual(height(paired),3);
            testCase.verifyEqual(summary.nReplicates,3);
            testCase.verifyEqual(summary.nTrials,2);
            testCase.verifyEqual(summary.nBootstrap,40);
            testCase.verifyEqual(numel(unique(paired.simSeed)),3);
            testCase.verifyEqual(paired.deltaF1,paired.wideF1-paired.narrowF1, ...
                'AbsTol',1e-12);
            testCase.verifyTrue(all(paired.wideF1>=0 & paired.wideF1<=1));
            testCase.verifyTrue(all(paired.narrowF1>=0 & paired.narrowF1<=1));
            testCase.verifyLessThanOrEqual(summary.deltaCILow,summary.deltaCIHigh);
            testCase.verifyTrue(isfile(fullfile(out,'paired_results.mat')));
            testCase.verifyTrue(isfile(fullfile(out,'replicate_metrics.csv')));
            testCase.verifyTrue(isfile(fullfile(out,'paired_f1.csv')));
            testCase.verifyTrue(isfile(fullfile(out,'paired_summary.csv')));
            metrics = readtable(fullfile(out,'replicate_metrics.csv'));
            testCase.verifyEqual(height(metrics),6);
            testCase.verifyEqual(metrics.tp+metrics.fp+metrics.fn+metrics.tn, ...
                6*ones(6,1));
            testCase.verifyEqual(metrics.nTrials,2*ones(6,1));
            testCase.verifyEqual(metrics.simSeed(1:2:end), ...
                metrics.simSeed(2:2:end));
            [pairedAgain,summaryAgain] = asct_multiverse_replicates(out2,3,40);
            testCase.verifyEqual(paired,pairedAgain);
            testCase.verifyEqual(summary,summaryAgain);
        end
        function invalidReplicateCountRejected(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'multiverse'));
            testCase.addTeardown(@()rmpath(fullfile(root,'multiverse')));
            testCase.verifyError(@()asct_multiverse_replicates(tempname,1,40), ...
                'ASCT:InvalidReplicates');
        end
    end
end

function localCleanup(varargin)
for i=1:nargin
    if isfolder(varargin{i}),rmdir(varargin{i},'s'); end
end
end
