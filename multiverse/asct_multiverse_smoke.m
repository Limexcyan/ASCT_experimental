function results = asct_multiverse_smoke(outputDir)
% ASCT_MULTIVERSE_SMOKE Fast, reproducible two-trial/two-pathway mockup.
%
%   results = asct_multiverse_smoke(outputDir)
%
% Uses ONE synthetic 3-source scenario with exactly TWO data trials and
% compares TWO analysis pathways (wide vs narrow frequency band). Both
% pathways see the same synthetic signal realization (paired simulation).
%
% This is an ORACLE SOURCE benchmark only. It does NOT run FieldTrip, ICA,
% source localization, or the production mmultar connectivity code. The
% real ASCT parameter mapping is still checked by asct_multiverse_run.
%
% Written outputs:
%   multiverse_manifest.csv, multiverse_results.mat, <config-id>.mat,
%   smoke_metrics.csv, smoke_settings.mat
%
% Example at the ASCT repo root:
%   addpath(fullfile(pwd,'multiverse'));
%   results = asct_multiverse_smoke(fullfile(pwd,'multiverse_smoke_results'));

if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(pwd,'multiverse_smoke_results');
end

study = asct_multiverse_defaults();
study.seed = 20261118;
study.maxRuns = 2;
study.simulation.fs = 128;
study.simulation.nSamples = 512;
study.simulation.nTrials = 2;     % Exactly two independent time-series trials.
study.simulation.nSensors = 20;

% Only bandMode varies. All simulation factors remain fixed: two pathways
% will be paired on precisely the same generated input signals.
study.factors.nSources = 3;
study.factors.distanceCm = 1.5;
study.factors.nInteractions = 1;
study.factors.strength = 0.5;
study.factors.lag = 1;
study.factors.snrDb = 15;
study.factors.evokedAmplitude = 0;
study.factors.bandMode = {'wide','narrow'};
study.factors.locNorm = {'lambda'};
study.factors.lambda = 0.1;
study.factors.depthWeight = 0;
study.factors.locMethod = {'mne'};
study.factors.nROIs = 5;
study.factors.orderMode = {'fixed'};
study.factors.fixedOrder = 2;
study.factors.varNorm = 0;
study.factors.removeERP = 0;

results = asct_multiverse_run(study, @mockSetup, outputDir, ...
    @(p,cfg,sim) oracleRunner(p,cfg,sim,study));

assert(numel(results) == 2, 'ASCT:SmokeUnexpectedRuns', ...
    'The smoke mockup must create exactly two analysis configurations');
badRun = find(~strcmp({results.status},'passed'),1);
if ~isempty(badRun)
    error('ASCT:SmokeFailed', 'Configuration %s failed: %s', ...
        results(badRun).id,results(badRun).error);
end
assert(results(1).config.simSeed == results(2).config.simSeed, ...
    'ASCT:SmokeUnpaired','The two analytical pathways must share a seed');
assert(isequal(results(1).output.signalSignature,results(2).output.signalSignature), ...
    'ASCT:SmokeUnpaired','Two configurations used different signal realizations');

configId = cell(2,1);
bandMode = cell(2,1);
nTrials = zeros(2,1);
f1 = zeros(2,1);
precision = zeros(2,1);
recall = zeros(2,1);
estimatedOrder = zeros(2,1);
for i = 1:2
    configId{i} = results(i).id;
    bandMode{i} = results(i).config.bandMode;
    nTrials(i) = results(i).output.nTrials;
    f1(i) = results(i).output.metrics.f1;
    precision(i) = results(i).output.metrics.precision;
    recall(i) = results(i).output.metrics.recall;
    estimatedOrder(i) = results(i).output.metrics.estimatedOrder;
    assert(nTrials(i) == 2, 'ASCT:SmokeUnexpectedTrials', ...
        'A mockup must contain exactly two independent trials');
    fprintf('ASCT multiverse smoke %d/2 | %s | band=%s | trials=%d | F1=%.3f\n', ...
        i,configId{i},bandMode{i},nTrials(i),f1(i));
end
metricsTable = table(configId,bandMode,nTrials,estimatedOrder,f1,precision,recall, ...
    'VariableNames',{'configuration','bandMode','nTrials','estimatedOrder', ...
                     'f1','precision','recall'});
writetable(metricsTable,fullfile(outputDir,'smoke_metrics.csv'));
save(fullfile(outputDir,'smoke_settings.mat'),'study');
fprintf('ASCT multiverse smoke PASSED: 2 configurations, 2 trials each.\n');
fprintf('Results: %s\n',outputDir);
end

function p = mockSetup(~,~)
% Minimal setup for checking ASCT parameter mapping; NOT a real data setup.
p.rc = struct('analysisName','multiverse_smoke_oracle');
p.chan = struct();
p.filter = struct();
p.seg = struct();
p.ar = struct();
p.ica = struct();
p.loc = struct('noiseLev',0.1, ...
    'ROI',repmat(struct('name','mock_roi'),1,5));
p.con = struct();
p.design = struct();
end

function output = oracleRunner(p,cfg,sim,study)
% Carry the already generated data into the source-level reference runner.
assert(size(sim.observedSources,3) == study.simulation.nTrials);
metrics = asct_multiverse_source_benchmark(cfg,study,0,sim);
signal = sim.observedSources(:);
output = struct('metrics',metrics, ...
    'signalSignature',[sum(signal),sum(signal.^2)], ...
    'oracleSourceBenchmark',true, ...
    'nTrials',size(sim.observedSources,3), ...
    'bandHz',[p.filter.HPfreq,p.filter.LPfreq]);
end
