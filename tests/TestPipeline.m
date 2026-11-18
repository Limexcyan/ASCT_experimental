classdef TestPipeline < matlab.unittest.TestCase
    % Self-contained synthetic fixture -> mock classifier smoke test.
    % Does NOT exercise the real ASCT end-to-end pipeline.
    methods (Test)
        function syntheticEEGToMockPredictions(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            addpath(root);
            out = tempname;
            cleanup = onCleanup(@() TestPipeline.removeFixture(out)); %#ok<NASGU>
            make_demo_fixture(out);
            s = load(fullfile(out,'synthetic_eeg.mat'));
            weightsFile = fullfile(out,'mock_weights.mat');
            [labels,probability] = mock_eeg_predict(s.EEG,weightsFile);
            testCase.verifySize(labels,[size(s.EEG,3),1]);
            testCase.verifySize(probability,[size(s.EEG,3),1]);
            testCase.verifyTrue(all(probability>=0 & probability<=1));
            testCase.verifyEqual(labels,double(probability>=0.5));
        end
        function missingWeightsFailsExplicitly(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            addpath(root);
            eeg = zeros(4,256,2);
            missing = [tempname '.mat'];
            testCase.verifyError(@() mock_eeg_predict(eeg,missing),'ASCT:MissingWeights');
        end
    end
    methods (Static,Access=private)
        function removeFixture(out)
            if exist(out,'dir'), rmdir(out,'s'); end
        end
    end
end
