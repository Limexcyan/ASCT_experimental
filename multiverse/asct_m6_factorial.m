function scenarios = asct_m6_factorial(factors,maxScenarios)
%ASCT_M6_FACTORIAL Exhaustive, bounded simulation parameter design.
% Enumerates nSources, distanceCm, nInteractions, strength, lag and snrDb.
% Invalid graphs (more edges than acyclic capacity) are excluded.
if nargin<2 || isempty(maxScenarios),maxScenarios=256;end
assert(isscalar(maxScenarios) && maxScenarios==fix(maxScenarios) && ...
    maxScenarios>=1, 'ASCT:M6:Grid','Invalid maxScenarios');
fields={'nSources','distanceCm','nInteractions','strength','lag','snrDb'};
values=cell(size(fields));
counts=zeros(size(fields));
for j=1:numel(fields)
    name=fields{j};
    assert(isfield(factors,name) && isnumeric(factors.(name)) && ...
        isvector(factors.(name)) && ~isempty(factors.(name)) && ...
        all(isfinite(factors.(name))), ...
        'ASCT:M6:Grid','Invalid factor %s',name);
    v=factors.(name);
    values{j}=unique(v(:)','stable');
    counts(j)=numel(values{j});
end
nGrid=prod(double(counts));
assert(isfinite(nGrid) && nGrid<=maxScenarios && nGrid<=flintmax, ...
    'ASCT:M6:Grid','Full grid %.0f exceeds maxScenarios %d',nGrid,maxScenarios);
scenarios=repmat(struct('nSources',0,'distanceCm',0,'nInteractions',0, ...
    'strength',0,'lag',0,'snrDb',0),nGrid,1);
k=0;
for ix=0:nGrid-1
    cfg=struct();temp=ix;
    for j=1:numel(fields)
        choice=mod(temp,counts(j))+1;
        cfg.(fields{j})=values{j}(choice);
        temp=floor(temp/counts(j));
    end
    if cfg.nSources<3 || cfg.nSources>10 || cfg.nSources~=fix(cfg.nSources)
        error('ASCT:M6:Grid','M6 nSources must be integer 3..10');
    end
    if cfg.nInteractions<0 || cfg.nInteractions~=fix(cfg.nInteractions)
        error('ASCT:M6:Grid','nInteractions must be nonnegative integer');
    end
    if cfg.nInteractions>cfg.nSources*(cfg.nSources-1)/2
        continue;
    end
    assert(cfg.strength>=0 && cfg.strength<=0.7 && ...
        (cfg.nInteractions==0 || cfg.strength>0) && ...
        cfg.lag>=1 && cfg.lag<=20 && cfg.lag==fix(cfg.lag) && ...
        cfg.distanceCm>0, 'ASCT:M6:Grid','Invalid simulation levels');
    k=k+1;scenarios(k)=cfg;
end
scenarios=scenarios(1:k);
assert(~isempty(scenarios),'ASCT:M6:Grid','All combinations invalid');
end
