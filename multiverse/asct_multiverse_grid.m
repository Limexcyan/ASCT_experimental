function configs = asct_multiverse_grid(study)
% Paired, reproducible sampled Cartesian multiverse.
% A small set of simulation scenarios is crossed with the SAME analytical
% pathways. This ensures that comparisons share exactly the same signal.
assert(isstruct(study) && isfield(study,'factors'), 'ASCT:InvalidStudy', 'study.factors is required');
assert(isfield(study,'maxRuns') && isscalar(study.maxRuns) && study.maxRuns >= 1 && study.maxRuns == fix(study.maxRuns), ...
    'ASCT:InvalidStudy', 'maxRuns must be a positive integer');
fields = fieldnames(study.factors);
values = cell(size(fields));
counts = zeros(size(fields));
for k = 1:numel(fields)
    v = study.factors.(fields{k});
    if iscell(v)
        values{k} = v;
    elseif isnumeric(v) && isvector(v) && all(isfinite(v))
        values{k} = num2cell(v);
    else
        error('ASCT:InvalidFactor','Factor %s must be a numeric vector or cell vector',fields{k});
    end
    counts(k) = numel(values{k});
    assert(counts(k)>0,'ASCT:InvalidFactor','Empty multiverse factor');
end
simNames = {'nSources','distanceCm','nInteractions','strength','lag','snrDb','evokedAmplitude'};
isSim = ismember(fields,simNames);
simFields = find(isSim);
analysisFields = find(~isSim);
simCounts = counts(simFields);
analysisCounts = counts(analysisFields);
nSim = prod(simCounts);
nAnal = prod(analysisCounts);
assert(isfinite(nSim*nAnal) && nSim*nAnal <= flintmax, 'ASCT:TooManyConfigurations', ...
    'Factor grid is too large to index exactly');
% Reserve up to four analysis pathways for every selected simulation, and
% use identical analytical pathways for all simulation scenarios.
if nAnal==1
    nScenarios=min(nSim,study.maxRuns);
else
    nScenarios=min(nSim,max(1,floor(study.maxRuns/min(nAnal,4))));
end
nPathways=min(nAnal,floor(study.maxRuns/nScenarios));
oldRng = rng;
restoreRng = onCleanup(@() rng(oldRng)); %#ok<NASGU>
rng(study.seed,'twister');
simulationIndices = sort(randperm(nSim,nScenarios));
analysisIndices = sort(randperm(nAnal,nPathways));
configs = struct([]);
j=0;
for si=simulationIndices
    simChoices=decode(si-1,simCounts);
    for ai=analysisIndices
        anaChoices=decode(ai-1,analysisCounts);
        cfg=struct();
        for k=1:numel(simFields)
            f=simFields(k);
            cfg.(fields{f})=values{f}{simChoices(k)};
        end
        for k=1:numel(analysisFields)
            f=analysisFields(k);
            cfg.(fields{f})=values{f}{anaChoices(k)};
        end
        cfg.id=sprintf('mv_s%05d_a%05d',si,ai);
        cfg.simulationIndex=si;
        cfg.analysisIndex=ai;
        cfg.simSeed=localScenarioSeed(cfg,study.seed);
        j=j+1;
        if j==1
            configs=repmat(cfg,numel(simulationIndices)*numel(analysisIndices),1);
        else
            configs(j)=cfg;
        end
    end
end
end
function choices=decode(index,counts)
choices=zeros(1,numel(counts));
for k=1:numel(counts)
    choices(k)=mod(index,counts(k))+1;
    index=floor(index/counts(k));
end
end
function seed = localScenarioSeed(c,base)
keys = {'nSources','distanceCm','nInteractions','strength','lag','snrDb','evokedAmplitude'};
part = sprintf('%d',base);
for k=1:numel(keys)
    if isfield(c,keys{k})
        part = [part '|' keys{k} '=' num2str(c.(keys{k}),17)]; %#ok<AGROW>
    end
end
% Portable polynomial hash; exact arithmetic throughout (under 2^53).
h = 5381;
for k=1:numel(part)
    h = mod(h*33+double(part(k)), 2147483647);
end
seed = max(1,h);
end
