function make_demo_fixture(outputDir)
% Create small synthetic EEG and deliberately NON-PRODUCTION classifier weights.
% EEG dimensions: channels x samples x trials. Units: microvolts.
if nargin < 1
    outputDir = fullfile(fileparts(mfilename('fullpath')), 'tests', 'fixtures');
end
if ~exist(outputDir,'dir'), mkdir(outputDir); end
rng(42,'twister');
fs = 128;
t = (0:255) / fs;
nTrials = 12;
EEG = zeros(4,numel(t),nTrials);
labels = zeros(nTrials,1);
for k = 1:nTrials
    labels(k) = mod(k,2); % balanced, arbitrary demo labels
    amp = 2 + 3*labels(k);
    for ch = 1:4
        EEG(ch,:,k) = amp*sin(2*pi*10*t + 0.1*ch) + ...
            0.4*randn(1,numel(t)) + 0.3*sin(2*pi*20*t);
    end
end
channelLabels = {'Fz','Cz','Pz','Oz'};
save(fullfile(outputDir,'synthetic_eeg.mat'),'EEG','fs','labels','channelLabels');
% Mock 2-feature logistic classifier, not fitted or validated.
W = [0.65; -0.15];
b = -2;
featureNames = {'log_rms','log_diff_rms'};
mockVersion = 1;
save(fullfile(outputDir,'mock_weights.mat'),'W','b','featureNames','mockVersion');
end
