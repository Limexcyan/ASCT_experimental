function score = asct_multiverse_score(dtf,truth,threshold)
% Binary directed edge recovery. truth(target,source); self-edges excluded.
if nargin<3, threshold=0.15; end
assert(size(dtf,3)>=1 && size(dtf,1)==size(dtf,2), 'ASCT:InvalidDTF', 'DTF must be target x source x frequency');
n=size(dtf,1);
assert(isequal(size(truth),[n n]), 'ASCT:InvalidTruth', 'Truth and estimate have incompatible ROI counts');
assert(threshold>=0 && threshold<=1,'ASCT:InvalidThreshold','Threshold must be in [0,1]');
meanDtf=mean(dtf,3);
mask=~eye(n);
pred=meanDtf>=threshold;
truth=logical(truth);
tp=nnz(pred & truth & mask);
fp=nnz(pred & ~truth & mask);
fn=nnz(~pred & truth & mask);
tn=nnz(~pred & ~truth & mask);
score.precision=tp/max(tp+fp,1);
score.recall=tp/max(tp+fn,1);
score.f1=2*tp/max(2*tp+fp+fn,1);
score.falsePositiveRate=fp/max(fp+tn,1);
score.tp=tp; score.fp=fp; score.fn=fn; score.tn=tn;
end
