function paired = asct_m9_paired_erp(T)
%ASCT_M9_PAIRED_ERP Compare matched ERP-kept and ERP-removed analyses.
% The two analyses must use the same simulated data, ROI set and settings.
% Positive fprReduction or f1Gain denotes improvement after subtraction.
required={'simSeed','replicate','nROIs','evokedAmplitude','varianceDrift', ...
    'orderMode','varNorm','removeERP','f1','falsePositiveRate'};
assert(istable(T) && all(ismember(required,T.Properties.VariableNames)), ...
    'ASCT:M9:Pairing','Missing expected paired ERP columns');
if isempty(T),paired=table();return;end

% Group by typed table columns instead of constructing composite strings.
% This also prevents accidentally joining cases with different factor types.
[firstRow,groupId]=asct_m9_group_rows(T,required(1:7));
nGroups=numel(firstRow);
keepIndex=find(~T.removeERP);
removeIndex=find(T.removeERP);
keepCount=accumarray(groupId(keepIndex),1,[nGroups 1]);
removeCount=accumarray(groupId(removeIndex),1,[nGroups 1]);
assert(all(keepCount==1) && all(removeCount==1), ...
    'ASCT:M9:Pairing','Each case must contain exactly one kept and one removed result');
keepIndex=accumarray(groupId(keepIndex),keepIndex,[nGroups 1],@min);
removeIndex=accumarray(groupId(removeIndex),removeIndex,[nGroups 1],@min);
paired=table(T.replicate(keepIndex),T.simSeed(keepIndex),T.nROIs(keepIndex), ...
    T.evokedAmplitude(keepIndex),T.varianceDrift(keepIndex), ...
    T.orderMode(keepIndex),T.varNorm(keepIndex), ...
    T.falsePositiveRate(keepIndex)-T.falsePositiveRate(removeIndex), ...
    T.f1(removeIndex)-T.f1(keepIndex), ...
    'VariableNames',{'replicate','simSeed','nROIs','evokedAmplitude', ...
    'varianceDrift','orderMode','varNorm','fprReduction','f1Gain'});
end
