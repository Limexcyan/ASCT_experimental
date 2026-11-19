function summary = asct_m9_paired_inference(T,groupColumns,metricColumns,nBootstrap,seed,correction,alpha)
%ASCT_M9_PAIRED_INFERENCE Bootstrap CI and sign-flip test on paired differences.
% Each row represents ONE independent simulated case after pairing the
% analytic choices. The pair difference is the sampling unit: do NOT feed
% individual trials, frequency bins or alternate analyses as replicates.
% Two-sided sign-flip p-values assume symmetric/exchangeable differences
% under the sharp null. For <=16 pairs enumerate every sign assignment;
% for larger groups use seeded Monte Carlo with a plus-one p-value.
% Holm/BH corrections apply across all tested groups, per metric.
if nargin<6 || isempty(correction),correction='holm';end
if nargin<7 || isempty(alpha),alpha=0.05;end
if isstring(groupColumns),groupColumns=cellstr(groupColumns);end
if isstring(metricColumns),metricColumns=cellstr(metricColumns);end
assert(istable(T) && iscellstr(groupColumns) && ~isempty(groupColumns) && ...
    iscellstr(metricColumns) && ~isempty(metricColumns) && ...
    all(ismember([groupColumns(:);metricColumns(:)],T.Properties.VariableNames)) && ...
    ismember('simSeed',T.Properties.VariableNames), ...
    'ASCT:M9:Paired','Paired input must include groups, metrics and simSeed');
assert(isnumeric(alpha) && isscalar(alpha) && isfinite(alpha) && ...
    alpha>0 && alpha<1,'ASCT:M9:Alpha','alpha must lie in (0,1)');
assert(isnumeric(nBootstrap) && isscalar(nBootstrap) && ...
    nBootstrap==fix(nBootstrap) && nBootstrap>=100 && nBootstrap<=1e6 && ...
    isnumeric(seed) && isscalar(seed) && seed==fix(seed) && ...
    seed>=1 && seed<=2147483646, ...
    'ASCT:M9:Options','Invalid bootstrap count or seed');
correction=lower(char(correction));
assert(ismember(correction,{'holm','bh','bonferroni','none'}), ...
    'ASCT:M9:Correction','Invalid p-value correction');

if isempty(T),summary=T([],groupColumns);return;end
[firstRow,~,rowIndex]=asct_m9_group_rows(T,groupColumns);
nGroups=numel(firstRow);
summary=T(firstRow,groupColumns);
summary.nPairs=zeros(nGroups,1);
summary.alpha=repmat(alpha,nGroups,1);
summary.pCorrection=repmat({correction},nGroups,1);
for m=1:numel(metricColumns)
    name=metricColumns{m};
    assert(isnumeric(T.(name)) && isvector(T.(name)), ...
        'ASCT:M9:Paired','Metric %s must be numeric',name);
    summary.(['mean_' name])=NaN(nGroups,1);
    summary.(['low_' name])=NaN(nGroups,1);
    summary.(['high_' name])=NaN(nGroups,1);
    summary.(['nValid_' name])=zeros(nGroups,1);
    summary.(['effectDz_' name])=NaN(nGroups,1);
    summary.(['pRaw_' name])=NaN(nGroups,1);
    summary.(['pAdjusted_' name])=NaN(nGroups,1);
    summary.(['reject_' name])=false(nGroups,1);
end
for g=1:nGroups
    ix=rowIndex{g};
    seeds=T.simSeed(ix);
    assert(isnumeric(seeds) && all(isfinite(seeds)) && ...
        numel(unique(seeds))==numel(seeds), ...
        'ASCT:M9:DuplicateReplicate', ...
        'Each paired difference requires one distinct independent seed');
    summary.nPairs(g)=numel(ix);
    for m=1:numel(metricColumns)
        name=metricColumns{m};
        v=T.(name);v=v(ix);
        assert(all(isfinite(v) | isnan(v)), ...
            'ASCT:M9:Paired','Metric %s contains infinity',name);
        v=v(isfinite(v));
        summary{g,['nValid_' name]}=numel(v);
        if numel(v)<2,continue;end
        drawSeed=mod(double(seed)+double(g)*10007+double(m)*101,2147483646)+1;
        ci=asct_m9_bootstrap(v,nBootstrap,drawSeed);
        summary{g,['mean_' name]}=ci.mean;
        summary{g,['low_' name]}=ci.ciLow;
        summary{g,['high_' name]}=ci.ciHigh;
        if numel(v)>=3 && std(v)>0
            summary{g,['effectDz_' name]}=mean(v)/std(v);
        end
        summary{g,['pRaw_' name]}=signFlipP(v,drawSeed);
    end
end
for m=1:numel(metricColumns)
    name=metricColumns{m};
    col=['pAdjusted_' name];
    summary.(col)=asct_m9_adjust_p(summary.(['pRaw_' name]),correction);
    summary.(['reject_' name])=summary.(col)<=alpha;
end
end

function p = signFlipP(v,seed)
n=numel(v);observed=abs(mean(v));
if n<=16
    % Exact randomization distribution including the observed arrangement.
    signs=2*double(bitget(uint32((0:2^n-1)'),1:n))-1;
    means=abs(signs*v(:)/n);
    p=mean(means>=observed-1e-12);
    return;
end
% Batch stochastic sign flips to cap memory; restore external RNG state.
oldRng=rng;
cleanup=onCleanup(@()rng(oldRng)); %#ok<NASGU>
rng(seed,'twister');
nPerm=9999;
count=0;
batch=max(1,floor(2e6/n));
for first=1:batch:nPerm
    countNow=min(batch,nPerm-first+1);
    signs=2*double(rand(n,countNow)>=0.5)-1;
    simulated=abs(v(:)'*signs/n);
    count=count+nnz(simulated>=observed-1e-12);
end
p=(1+count)/(1+nPerm);
end
