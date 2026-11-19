function stats = asct_m9_bootstrap(values,nBootstrap,seed)
%ASCT_M9_BOOTSTRAP Percentile CI over independent simulation replicates.
% Rows are independent cases and columns are metrics. For paired contrasts,
% pass one difference per independent replicate. Random draws are batched
% to reduce loop overhead while limiting temporary memory use.
assert(isnumeric(values) && isreal(values) && ~isempty(values), ...
    'ASCT:M9:Samples','Require finite independent replicate values');
if isvector(values),values=values(:);end
assert(size(values,1)>=2 && all(isfinite(values(:))), ...
    'ASCT:M9:Samples','At least two finite independent replicates required');
assert(isscalar(nBootstrap) && nBootstrap==fix(nBootstrap) && ...
    nBootstrap>=100 && nBootstrap<=1e6, ...
    'ASCT:M9:Bootstrap','nBootstrap must be >=100');
assert(isscalar(seed) && seed>=1 && seed==fix(seed), ...
    'ASCT:M9:Seed','Seed must be positive integer');
oldRng=rng;
cleanup=onCleanup(@()rng(oldRng)); %#ok<NASGU>
rng(seed,'twister');

n=size(values,1);
nMetrics=size(values,2);
bootstrapMeans=zeros(nBootstrap,nMetrics);
% About two million indices per batch (16 MB as doubles).
batchSize=max(1,floor(2e6/n));
for first=1:batchSize:nBootstrap
    last=min(first+batchSize-1,nBootstrap);
    count=last-first+1;
    sampleIndex=randi(n,n,count);
    for metric=1:nMetrics
        % With two subscripts MATLAB returns a column for matrix indices.
        % Restore [replicate x bootstrap draw] before averaging each draw.
        draws=reshape(values(sampleIndex,metric),n,count);
        bootstrapMeans(first:last,metric)=mean(draws,1)';
    end
end
sorted=sort(bootstrapMeans,1);
lo=max(1,ceil(0.025*nBootstrap));
hi=min(nBootstrap,ceil(0.975*nBootstrap));
stats=struct('mean',mean(values,1),'ciLow',sorted(lo,:), ...
    'ciHigh',sorted(hi,:),'nReplicates',n, ...
    'nBootstrap',nBootstrap,'unit','independent simulated case');
end
