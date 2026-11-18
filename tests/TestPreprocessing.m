classdef TestPreprocessing < matlab.unittest.TestCase
    % Reference DSP contract tests. Not yet connected to ASCT preprocessing.
    methods (Test)
        function bandSelectionPreserves10HzAndRejects40Hz(testCase)
            fs = 128;
            N = 256;
            t = (0:N-1)/fs;
            x = 2*sin(2*pi*10*t) + sin(2*pi*40*t);
            % Ideal FFT mask is a deterministic reference, not an ASCT filter.
            X = fft(x);
            f = (0:N-1)*fs/N;
            keep = (f>=8 & f<=12) | (f>=fs-12 & f<=fs-8);
            filtered = real(ifft(X .* keep));
            amp10 = 2*abs(sum(filtered.*exp(-1i*2*pi*10*t)))/N;
            amp40 = 2*abs(sum(filtered.*exp(-1i*2*pi*40*t)))/N;
            testCase.verifyEqual(size(filtered),size(x));
            testCase.verifyEqual(amp10,2,'AbsTol',1e-10);
            testCase.verifyLessThan(amp40,1e-10);
            testCase.verifyTrue(all(isfinite(filtered)));
        end
        function fixtureHasExpectedSamplingAndShape(testCase)
            root = fileparts(fileparts(mfilename('fullpath')));
            addpath(root);
            out = tempname;
            cleanup = onCleanup(@() TestPreprocessing.removeFixture(out)); %#ok<NASGU>
            make_demo_fixture(out);
            s = load(fullfile(out,'synthetic_eeg.mat'));
            testCase.verifyEqual(s.fs,128);
            testCase.verifySize(s.EEG,[4,256,12]);
            testCase.verifyTrue(all(isfinite(s.EEG(:))));
            testCase.verifyEqual(numel(s.channelLabels),4);
        end
    end
    methods (Static, Access=private)
        function removeFixture(out)
            if exist(out,'dir'), rmdir(out,'s'); end
        end
    end
end
