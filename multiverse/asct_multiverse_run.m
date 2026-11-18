function results = asct_multiverse_run(study,setupFcn,outputDir,runnerFcn)
% Run a single-case multiverse with isolated ASCT output folders.
% setupFcn(cfg,sim) returns a complete ASCT setup struct. It can map the
% simulated sources/sensors to a REAL existing ASCT-supported dataset, or
% provide an already prepared case; conversion is experiment-specific.
% runnerFcn(p,cfg,sim) defaults to asct_multiverse_execute (full ASCT).
if nargin<4 || isempty(runnerFcn), runnerFcn=@asct_multiverse_execute; end
assert(isa(setupFcn,'function_handle') && isa(runnerFcn,'function_handle'), ...
    'ASCT:InvalidCallback','Expected function handles');
configs=asct_multiverse_grid(study);
if ~isfolder(outputDir), mkdir(outputDir); end
results=repmat(struct('id','','status','','config',struct(), ...
    'output',struct(),'error',''),numel(configs),1);
for i=1:numel(configs)
    c=configs(i);
    results(i).id=c.id;
    results(i).config=c;
    try
        sim=asct_multiverse_simulate(c,study.simulation);
        setup=setupFcn(c,sim);
        setup=asct_multiverse_apply(setup,c,study);
        % Note: caller must explicitly provide a dataset/ExSetup adapter.
        results(i).output=runnerFcn(setup,c,sim);
        results(i).status='passed';
    catch ME
        results(i).status='failed';
        results(i).error=sprintf('%s: %s',ME.identifier,ME.message);
    end
    oneResult=results(i); %#ok<NASGU>
    save(fullfile(outputDir,[c.id '.mat']),'oneResult');
end
save(fullfile(outputDir,'multiverse_results.mat'),'results','study');
asct_multiverse_summary(results,fullfile(outputDir,'multiverse_manifest.csv'));
end
