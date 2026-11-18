classdef TestMockEEG < matlab.unittest.TestCase
    properties
        Root
        FixtureDir
    end
    methods (TestMethodSetup)
        function setup(testCase)
            testCase.Root = fileparts(fileparts(mfilename('fullpath')));
            addpath(testCase.Root);
            testCase.FixtureDir = fullfile(testCase.Root,'tests','fixtures');
            make_demo_fixture(testCase.FixtureDir);
        end
    end
    methods (Test)
        function eegDimensionsAndReproducibility(testCase)
            d = load(fullfile(testCase.FixtureDir,'synthetic_eeg.mat'));
            testCase.verifySize(d.EEG,[4 256 12]);
            testCase.verifyEqual(d.fs,128);
            testCase.verifyTrue(all(isfinite(d.EEG(:))));
            testCase.verifyEqual(numel(d.labels),12);
            original = d.EEG;
            make_demo_fixture(testCase.FixtureDir);
            d2 = load(fullfile(testCase.FixtureDir,'synthetic_eeg.mat'));
            testCase.verifyEqual(d2.EEG, original);
        end
        function mockPredictionsAreValid(testCase)
            d = load(fullfile(testCase.FixtureDir,'synthetic_eeg.mat'));
            weights = fullfile(testCase.FixtureDir,'mock_weights.mat');
            [y,p] = mock_eeg_predict(d.EEG,weights);
            testCase.verifySize(y,[12 1]);
            testCase.verifySize(p,[12 1]);
            testCase.verifyTrue(all(p >= 0 & p <= 1));
            testCase.verifyTrue(all(y == 0 | y == 1));
            [y2,p2] = mock_eeg_predict(d.EEG,weights);
            testCase.verifyEqual(y2,y);
            testCase.verifyEqual(p2,p);
        end
        function wrongInputRaisesError(testCase)
            weights = fullfile(testCase.FixtureDir,'mock_weights.mat');
            testCase.verifyError(@()mock_eeg_predict(NaN(4,256,2),weights), 'ASCT:NonFinite');
            testCase.verifyError(@()mock_eeg_predict(rand(4,1,2),weights), 'ASCT:TooShort');
            testCase.verifyError(@()mock_eeg_predict(rand(4,256,2),fullfile(testCase.Root,'missing.mat')), 'ASCT:MissingWeights');
        end
        function regressionMeanAmplitude(testCase)
            % Controlled scientific/processing invariant for this fixture.
            d = load(fullfile(testCase.FixtureDir,'synthetic_eeg.mat'));
            rmsPerTrial = squeeze(sqrt(mean(mean(d.EEG.^2,1),2)));
            testCase.verifyGreaterThan(mean(rmsPerTrial(d.labels==1)),mean(rmsPerTrial(d.labels==0)));
        end
    end
end
