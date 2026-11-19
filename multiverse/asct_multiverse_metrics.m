function T = asct_multiverse_metrics(root,plugins)
%ASCT_MULTIVERSE_METRICS Evaluate read-only, extensible metrics on saved runs.
% T=asct_multiverse_metrics(root,plugins) never executes ASCT/FieldTrip.
% 'root' is <outputName>__multiverse. Metrics are postprocessing only:
% failure never changes realdata_results.mat, stage outputs, or run status.
% Callback: values=fn(runsetup,spec,context); values must be scalar struct.
% A failed plugin produces a FAILED metric row (no silent data loss).
plugins=asct_multiverse_metrics_validate(plugins);
assert(~isempty(plugins),'ASCT:Metrics:NoPlugins','Provide at least one metric');
root=char(root);
mat=fullfile(root,'realdata_results.mat');
assert(isfile(mat),'ASCT:Metrics:MissingResults', ...
    'Missing saved ASCT results: %s',mat);
loaded=load(mat,'results','planSnapshot');
assert(isfield(loaded,'results') && isstruct(loaded.results), ...
    'ASCT:Metrics:InvalidResults','Missing saved results structure');
results=loaded.results;
parent=fileparts(root);
n=numel(results)*numel(plugins);
configId=strings(n,1);analysisName=strings(n,1);
metricName=strings(n,1);status=strings(n,1);
valuesJson=strings(n,1);errorMessage=strings(n,1);
metricResults=repmat(struct('configId','','analysisName','', ...
    'metric','','status','','values',struct(),'error',''),n,1);
for i=1:numel(results)
    r=results(i);
    analysisFolder=fullfile(parent,r.analysisName);
    setupFile=fullfile(analysisFolder,'multiverse_setup.mat');
    for j=1:numel(plugins)
        ix=(i-1)*numel(plugins)+j;
        configId(ix)=string(r.id);
        analysisName(ix)=string(r.analysisName);
        metricName(ix)=string(plugins(j).name);
        status(ix)="skipped";
        vals=struct(); err='';
        if strcmp(r.status,'passed')
            try
                assert(isfile(setupFile),'ASCT:Metrics:MissingSetup', ...
                    'Missing saved setup: %s',setupFile);
                s=load(setupFile,'runsetup','spec');
                assert(isfield(s,'runsetup') && isfield(s,'spec'), ...
                    'ASCT:Metrics:MissingSetup', ...
                    'Saved setup must contain runsetup and spec');
                ctx=struct('root',root,'analysisFolder',analysisFolder, ...
                    'result',r);
                vals=plugins(j).fn(s.runsetup,s.spec,ctx);
                assert(isstruct(vals) && isscalar(vals), ...
                    'ASCT:Metrics:BadReturn', ...
                    'Metric %s must return a scalar struct',plugins(j).name);
                % Check values are JSON serializable before committing output.
                encoded=jsonencode(vals);
                status(ix)="passed";
                valuesJson(ix)=string(encoded);
            catch ME
                status(ix)="failed";
                err=sprintf('%s: %s',ME.identifier,ME.message);
                errorMessage(ix)=string(err);
            end
        end
        metricResults(ix).configId=char(configId(ix));
        metricResults(ix).analysisName=char(analysisName(ix));
        metricResults(ix).metric=char(metricName(ix));
        metricResults(ix).status=char(status(ix));
        metricResults(ix).values=vals;
        metricResults(ix).error=err;
    end
end
T=table(configId,analysisName,metricName,status,valuesJson,errorMessage);
% Metrics are independent from execution identity and may be recomputed
% with new plugins on the same saved stage outputs. Update atomically.
partialMat=fullfile(root,'multiverse_metric_results.partial.mat');
metricFile=fullfile(root,'multiverse_metric_results.mat');
meta=struct('names',{arrayfun(@(p)char(p.name),plugins,'UniformOutput',false)}, ...
    'callbacks',{arrayfun(@(p)func2str(p.fn),plugins,'UniformOutput',false)}, ...
    'generatedAt',datestr(now,30));
if isfield(loaded,'planSnapshot') && isfield(loaded.planSnapshot,'gitRevision')
    meta.executionGitRevision=loaded.planSnapshot.gitRevision;
end
save(partialMat,'metricResults','meta');
[ok,msg]=movefile(partialMat,metricFile,'f');
assert(ok,'ASCT:Metrics:SaveFailed','Cannot save metrics MAT: %s',msg);
csv=fullfile(root,'multiverse_metric_results.csv');
partialCsv=[csv '.partial.csv'];
writetable(T,partialCsv);
[ok,msg]=movefile(partialCsv,csv,'f');
assert(ok,'ASCT:Metrics:SaveFailed','Cannot save metrics CSV: %s',msg);
end
