function result = asct_m9_discrimination(dtf,truth)
%ASCT_M9_DISCRIMINATION Threshold-free directed ROC and PR performance.
% ROC AUC uses trapezoids over distinct score ties. Average precision
% weights precision by the increase in recall at each score threshold.
% These are descriptive scores for one simulated graph, not p-values.
valid=asct_m9_edge_metrics(dtf,truth,0.5); %#ok<NASGU>
n=size(dtf,1);
mask=~eye(n);
scores=mean(dtf,3);
scores=scores(mask);
labels=logical(truth(mask));
[sorted,order]=sort(scores(:),'descend');
labels=labels(order);
nPos=nnz(labels);nNeg=numel(labels)-nPos;
% Aggregate tied score values so ranking does not depend on edge order.
if isempty(sorted)
    result=struct('auroc',NaN,'averagePrecision',NaN,'nPositive',0, ...
        'nNegative',0,'thresholds',[],'tpr',[],'fpr',[],'precision',[]);
    return;
end
isLast=[diff(sorted)~=0;true];
ix=find(isLast);
cumPos=cumsum(labels);
cumNeg=cumsum(~labels);
tp=double(cumPos(ix));fp=double(cumNeg(ix));
thresholds=sorted(ix);
recall=NaN(size(tp));fpr=NaN(size(tp));
precision=tp./max(tp+fp,1);
if nPos>0,recall=tp/nPos;end
if nNeg>0,fpr=fp/nNeg;end
auroc=NaN;averagePrecision=NaN;
if nPos>0
    averagePrecision=sum(diff([0;recall]).*precision);
end
if nPos>0 && nNeg>0
    auroc=trapz([0;fpr],[0;recall]);
end
result=struct('auroc',auroc,'averagePrecision',averagePrecision, ...
    'nPositive',nPos,'nNegative',nNeg,'thresholds',thresholds, ...
    'tpr',recall,'fpr',fpr,'precision',precision);
end
