function summary = asct_m9_table_summary(T,groupColumns,metricColumns,nBootstrap,seed)
%ASCT_M9_TABLE_SUMMARY Bootstrap summaries of independent simulation cases.
% Each row in a group must represent one independently generated case.
% In particular, trials or alternative analyses of the same simulation
% must not be counted as additional independent replicates.
assert(istable(T),'ASCT:M9:Table','T must be a table');
if isstring(groupColumns),groupColumns=cellstr(groupColumns);end
if isstring(metricColumns),metricColumns=cellstr(metricColumns);end
assert(iscellstr(groupColumns) && iscellstr(metricColumns) && ...
    ~isempty(groupColumns) && ~isempty(metricColumns), ...
    'ASCT:M9:Table','Groups and metrics must be cell arrays of names');
assert(all(ismember([groupColumns(:);metricColumns(:)],T.Properties.VariableNames)), ...
    'ASCT:M9:Table','Missing a grouping or metric variable');
if isempty(T),summary=T([],groupColumns);return;end

% Group typed table rows, including the NaN lambda used in covariance-based
% localization; avoid ambiguous composite strings and repeated scans.
[firstRow,~,rowIndex]=asct_m9_group_rows(T,groupColumns);
nGroups=numel(firstRow);
summary=T(firstRow,groupColumns);
summary.nReplicates=zeros(nGroups,1);
for m=1:numel(metricColumns)
    name=metricColumns{m};
    assert(isnumeric(T.(name)) && isvector(T.(name)), ...
        'ASCT:M9:Metric','Metric %s must be a numeric vector',name);
    summary.(['mean_' name])=NaN(nGroups,1);
    summary.(['low_' name])=NaN(nGroups,1);
    summary.(['high_' name])=NaN(nGroups,1);
    summary.(['nValid_' name])=zeros(nGroups,1);
end

checkSeed=ismember('simSeed',T.Properties.VariableNames);
for g=1:nGroups
    ix=rowIndex{g};
    summary.nReplicates(g)=numel(ix);
    if checkSeed
        seeds=T.simSeed(ix);
        assert(numel(unique(seeds))==numel(seeds), ...
            'ASCT:M9:DuplicateReplicate', ...
            'Group %d contains repeated simSeed values; bootstrap requires independent cases',g);
    end
    for m=1:numel(metricColumns)
        name=metricColumns{m};
        metricValues=T.(name);
        values=metricValues(ix);
        values=values(isfinite(values));
        n=numel(values);
        summary{g,['nValid_' name]}=n;
        if n<2,continue;end
        drawSeed=mod(double(seed)+double(g)*10007+double(m)*101,2147483646)+1;
        stats=asct_m9_bootstrap(values,nBootstrap,drawSeed);
        summary{g,['mean_' name]}=stats.mean;
        summary{g,['low_' name]}=stats.ciLow;
        summary{g,['high_' name]}=stats.ciHigh;
    end
end
end
