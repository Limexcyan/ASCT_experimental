function score = asct_m9_edge_metrics(dtf,truth,threshold)
%ASCT_M9_EDGE_METRICS Directed binary detection against known synthetic truth.
% Only off-diagonal target-by-source entries are evaluated. A zero-edge
% control has undefined recall/F1 but a well-defined false-positive rate.
if nargin<3 || isempty(threshold),threshold=0.15;end
assert(isnumeric(dtf) && isreal(dtf) && ndims(dtf)<=3 && ...
    size(dtf,1)==size(dtf,2) && size(dtf,1)>=2 && ...
    size(dtf,3)>=1 && all(isfinite(dtf(:))) && ...
    all(dtf(:)>=0) && all(dtf(:)<=1+1e-10), ...
    'ASCT:M9:DTF','DTF must be finite real normalized target x source x frequency');
n=size(dtf,1);
assert((islogical(truth) || isnumeric(truth)) && ...
    isequal(size(truth),[n,n]) && all(isfinite(double(truth(:)))) && ...
    all(ismember(double(truth(:)),[0,1])), ...
    'ASCT:M9:Truth','Truth must be a binary nROI x nROI matrix');
assert(isnumeric(threshold) && isscalar(threshold) && ...
    isfinite(threshold) && threshold>=0 && threshold<=1, ...
    'ASCT:M9:Threshold','Threshold must be a finite scalar in [0,1]');

mask=~eye(n);
actual=logical(truth) & mask;
predicted=(mean(dtf,3)>=threshold) & mask;
tp=nnz(predicted & actual);
fp=nnz(predicted & ~actual & mask);
fn=nnz(~predicted & actual);
tn=nnz(~predicted & ~actual & mask);
nPositive=tp+fn;
nNegative=tn+fp;
score=struct('tp',tp,'fp',fp,'fn',fn,'tn',tn, ...
    'nTrueEdges',nPositive,'nPredictedEdges',tp+fp, ...
    'nCandidateEdges',n*(n-1),'threshold',threshold);
score.precision=NaN;
if tp+fp>0,score.precision=tp/(tp+fp);end
score.recall=NaN;
score.f1=NaN;
if nPositive>0
    score.recall=tp/nPositive;
    score.f1=2*tp/(2*tp+fp+fn);
end
score.falsePositiveRate=NaN;
score.specificity=NaN;
if nNegative>0
    score.falsePositiveRate=fp/nNegative;
    score.specificity=tn/nNegative;
end
score.falseDiscoveryRate=NaN;
if tp+fp>0,score.falseDiscoveryRate=fp/(tp+fp);end
score.balancedAccuracy=NaN;
if nPositive>0 && nNegative>0
    score.balancedAccuracy=(score.recall+score.specificity)/2;
end
score.matthewsCorrelation=NaN;
den=sqrt(double(tp+fp)*double(tp+fn)*double(tn+fp)*double(tn+fn));
if den>0,score.matthewsCorrelation=(tp*tn-fp*fn)/den;end
score.exactGraphRecovery=(fp==0 && fn==0);
end
