function results = asct_multiverse_source_demo(outputDir)
% Executable first-phase demonstration with oracle ROI signals (NOT full ASCT).
if nargin<1, outputDir=fullfile(tempdir,'asct_multiverse_source_demo'); end
study=asct_multiverse_defaults();
study.maxRuns=8;
configs=asct_multiverse_grid(study);
if ~isfolder(outputDir), mkdir(outputDir); end
results=repmat(struct('id','','config',struct(),'metrics',struct()),numel(configs),1);
for i=1:numel(configs)
    results(i).id=configs(i).id;
    results(i).config=configs(i);
    results(i).metrics=asct_multiverse_source_benchmark(configs(i),study,20);
end
save(fullfile(outputDir,'oracle_source_results.mat'),'results','study');
asct_multiverse_summary(results,fullfile(outputDir,'oracle_source_manifest.csv'));
end
