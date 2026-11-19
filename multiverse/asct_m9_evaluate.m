function score = asct_m9_evaluate(fit,trueA,truth,fs,frequencyHz,threshold)
%ASCT_M9_EVALUATE Directed-edge, lag and coefficient-magnitude errors.
% Lag and strength MAE are computed over ALL true edges (including misses).
% Truth is target x source. Self-connections are not counted as edges.
if nargin<6 || isempty(threshold), threshold=0.15; end
assert(isfield(fit,'A') && isfield(fit,'order'), ...
    'ASCT:M9:Fit','Expected fitted VAR structure');
A=fit.A;
n=size(A,1);
assert(size(A,2)==n && isequal(size(truth),[n,n]) && ...
    size(trueA,1)==n && size(trueA,2)==n, ...
    'ASCT:M9:Shape','Truth must be aligned with estimated ROIs');
assert(all(isfinite(A(:))) && all(isfinite(trueA(:))), ...
    'ASCT:M9:Nonfinite','Non-finite MVAR coefficient');
dtfCoefficients=A;
if isfield(fit,'Adtf'), dtfCoefficients=fit.Adtf; end
D=asct_mvar_dtf(dtfCoefficients,fs,frequencyHz);
assert(all(isfinite(D(:))),'ASCT:M9:InvalidDTF', ...
    'Non-finite DTF: the fitted VAR is not evaluable');
score=asct_multiverse_score(D,logical(truth),threshold);
if ~any(logical(truth(:)))
    % No actual positives: recall and F1 are undefined; FPR remains valid.
    score.recall=NaN;
    score.f1=NaN;
end
mask=logical(truth) & ~eye(n);
[targets,sources]=find(mask);
lagError=zeros(numel(targets),1);
strengthError=zeros(numel(targets),1);
for i=1:numel(targets)
    t=targets(i); s=sources(i);
    fitted=abs(reshape(A(t,s,:),[],1));
    truthValues=abs(reshape(trueA(t,s,:),[],1));
    [~,predLag]=max(fitted);
    [trueStrength,trueLag]=max(truthValues);
    lagError(i)=abs(predLag-trueLag);
    strengthError(i)=abs(fitted(predLag)-trueStrength);
end
if isempty(targets)
    score.lagMAE=NaN;
    score.strengthMAE=NaN;
else
    score.lagMAE=mean(lagError);
    score.strengthMAE=mean(strengthError);
end
score.nTrueEdges=numel(targets);
score.modelOrder=fit.order;
score.spectralRadius=fit.diagnostics.spectralRadius;
score.stable=fit.diagnostics.stable;
score.validForInference=logical(score.stable); % residual checks reported separately
score.residualLag1=fit.diagnostics.maxLag1ResidualCorrelation;
score.maxVarianceRatio=fit.diagnostics.maxVarianceRatio;
score.evokedRMSFraction=fit.diagnostics.evokedRMSFraction;
end
