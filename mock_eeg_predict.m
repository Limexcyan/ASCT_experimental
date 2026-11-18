function [predictedLabels, probability] = mock_eeg_predict(EEG, weightsFile)
% Mock classifier only: NOT the real ASCT model or an accuracy benchmark.
% Input: channels x samples x trials; output: trials x 1.
validateattributes(EEG, {'numeric'}, {'real','nonempty','3d'});
if ~all(isfinite(EEG(:))), error('ASCT:NonFinite','EEG contains NaN or Inf'); end
if size(EEG,2) < 2, error('ASCT:TooShort','At least 2 samples required'); end
if ~isfile(weightsFile), error('ASCT:MissingWeights','Missing mock weights: %s',weightsFile); end
m = load(weightsFile,'W','b');
if ~isfield(m,'W') || ~isfield(m,'b') || ~isequal(size(m.W),[2,1]) || ~isscalar(m.b)
    error('ASCT:BadWeights','Invalid mock weights');
end
nTrials = size(EEG,3);
features = zeros(nTrials,2);
for k = 1:nTrials
    trial = double(EEG(:,:,k));
    features(k,1) = log(sqrt(mean(trial(:).^2)) + eps);
    delta = diff(trial,1,2);
    features(k,2) = log(sqrt(mean(delta(:).^2)) + eps);
end
z = features*m.W + m.b;
probability = 1./(1+exp(-z));
predictedLabels = double(probability >= 0.5);
end
