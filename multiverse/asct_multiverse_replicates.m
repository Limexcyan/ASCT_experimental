function [paired, summary] = asct_multiverse_replicates(outputDir, nReplicates, nBootstrap)
% ASCT_MULTIVERSE_REPLICATES Paired wide vs narrow, independent VAR sources.
%
%   [paired, summary] = asct_multiverse_replicates(outputDir,20,2000)
%
% Creates nReplicates INDEPENDENT synthetic realizations (distinct RNG
% seeds). Each has EXACTLY two signal trials. Both analytic pathways use
% the SAME observed source signals within every replicate (paired design).
%
% Saves replicate_metrics.csv, paired_f1.csv, paired_summary.csv and
% paired_results.mat. The confidence intervals bootstrap independent
% simulation replicates, NOT the two trials or individual time samples.
%
% ORACLE SOURCE BENCHMARK ONLY: does not invoke FieldTrip, ICA, or mmultar.

if nargin < 1 || isempty(outputDir)
    outputDir = fullfile(pwd,'multiverse_replicates_results');
end
if nargin < 2 || isempty(nReplicates), nReplicates = 20; end
if nargin < 3 || isempty(nBootstrap), nBootstrap = 2000; end
assert(isnumeric(nReplicates) && isscalar(nReplicates) && isreal(nReplicates) && ...
    isfinite(nReplicates) && nReplicates==fix(nReplicates) && ...
    nReplicates>=2 && nReplicates<=10000, ...
    'ASCT:InvalidReplicates','nReplicates must be an integer from 2 to 10000');
assert(isnumeric(nBootstrap) && isscalar(nBootstrap) && isreal(nBootstrap) && ...
    isfinite(nBootstrap) && nBootstrap==fix(nBootstrap) && ...
    nBootstrap>=20 && nBootstrap<=1e6, ...
    'ASCT:InvalidBootstrap','nBootstrap must be an integer from 20 to 1e6');

study = asct_multiverse_smoke_study();
configs = asct_multiverse_grid(study);
assert(numel(configs)==2,'ASCT:ReplicatesConfiguration', ...
    'Expected exactly two analytical pathways');
bands = {configs.bandMode};
wideIndex = find(strcmp(bands,'wide'));
narrowIndex = find(strcmp(bands,'narrow'));
assert(isscalar(wideIndex) && isscalar(narrowIndex), ...
    'ASCT:ReplicatesConfiguration','Expected one wide and one narrow pathway');
assert(configs(wideIndex).simSeed == configs(narrowIndex).simSeed, ...
    'ASCT:ReplicatesUnpaired','Baseline seeds must match');

if ~isfolder(outputDir), mkdir(outputDir); end
nCases = 2*nReplicates;
replicate = zeros(nCases,1);
simSeed = zeros(nCases,1);
bandMode = cell(nCases,1);
nTrials = zeros(nCases,1);
estimatedOrder = zeros(nCases,1);
f1 = zeros(nCases,1);
precision = zeros(nCases,1);
recall = zeros(nCases,1);
falsePositiveRate = zeros(nCases,1);
tp = zeros(nCases,1); fp = zeros(nCases,1);
fn = zeros(nCases,1); tn = zeros(nCases,1);

seeds = zeros(nReplicates,1);
wideF1 = zeros(nReplicates,1);
narrowF1 = zeros(nReplicates,1);
baseSeed = double(configs(1).simSeed);
for r = 1:nReplicates
    % First replicate reproduces the single-case smoke seed. Distinct
    % integer seeds for all further independently generated simulations.
    seed = mod(baseSeed-1 + (r-1)*104729,2147483646)+1;
    seeds(r) = seed;
    genCfg = configs(wideIndex);
    genCfg.simSeed = seed;
    sim = asct_multiverse_simulate(genCfg,study.simulation);
    assert(size(sim.observedSources,3)==2,'ASCT:ReplicatesTrials', ...
        'Every simulation must have exactly two trials');
    for a = 1:2
        cfg = configs(a);
        cfg.simSeed = seed;
        % IMPORTANT: feed the same sim into both pathways. Do not call the
        % simulator again for another filter, even with an identical seed.
        m = asct_multiverse_source_benchmark(cfg,study,0,sim);
        i = (r-1)*2+a;
        replicate(i) = r; simSeed(i) = seed;
        bandMode{i} = cfg.bandMode;
        nTrials(i) = size(sim.observedSources,3);
        estimatedOrder(i) = m.estimatedOrder;
        f1(i) = m.f1; precision(i) = m.precision;
        recall(i) = m.recall; falsePositiveRate(i) = m.falsePositiveRate;
        tp(i) = m.tp; fp(i) = m.fp; fn(i) = m.fn; tn(i) = m.tn;
        assert(tp(i)+fp(i)+fn(i)+tn(i)==6, ...
            'ASCT:ReplicatesEdges','Invalid 3-node directed edge count');
        if a==wideIndex
            wideF1(r) = m.f1;
        else
            narrowF1(r) = m.f1;
        end
    end
    fprintf('ASCT paired replicate %d/%d | seed=%d | wide F1=%.3f | narrow F1=%.3f\n', ...
        r,nReplicates,seed,wideF1(r),narrowF1(r));
end

deltaF1 = wideF1-narrowF1;
metrics = table(replicate,simSeed,bandMode,nTrials,estimatedOrder, ...
    tp,fp,fn,tn,precision,recall,falsePositiveRate,f1);
paired = table((1:nReplicates)',seeds,wideF1,narrowF1,deltaF1, ...
    'VariableNames',{'replicate','simSeed','wideF1','narrowF1','deltaF1'});

% Bootstrap from INDEPENDENT simulations, retaining wide/narrow pairing.
oldRng = rng;
restoreRng = onCleanup(@()rng(oldRng)); %#ok<NASGU>
rng(20261119,'twister');
bootWide = zeros(nBootstrap,1);
bootNarrow = zeros(nBootstrap,1);
bootDelta = zeros(nBootstrap,1);
for b = 1:nBootstrap
    idx = randi(nReplicates,nReplicates,1);
    bootWide(b) = mean(wideF1(idx));
    bootNarrow(b) = mean(narrowF1(idx));
    bootDelta(b) = mean(deltaF1(idx));
end
ciWide = localPercentileCI(bootWide);
ciNarrow = localPercentileCI(bootNarrow);
ciDelta = localPercentileCI(bootDelta);
summary = table(nReplicates,study.simulation.nTrials,nBootstrap, ...
    mean(wideF1),mean(narrowF1),mean(deltaF1),std(deltaF1), ...
    ciWide(1),ciWide(2),ciNarrow(1),ciNarrow(2), ...
    ciDelta(1),ciDelta(2), ...
    sum(deltaF1>0),sum(deltaF1<0),sum(deltaF1==0), ...
    'VariableNames',{'nReplicates','nTrials','nBootstrap', ...
    'meanWideF1','meanNarrowF1','meanDeltaF1','stdDeltaF1', ...
    'wideCILow','wideCIHigh','narrowCILow','narrowCIHigh', ...
    'deltaCILow','deltaCIHigh','wideWins','narrowWins','ties'});

writetable(metrics,fullfile(outputDir,'replicate_metrics.csv'));
writetable(paired,fullfile(outputDir,'paired_f1.csv'));
writetable(summary,fullfile(outputDir,'paired_summary.csv'));
save(fullfile(outputDir,'paired_results.mat'),'paired','metrics','summary', ...
    'study','configs','-v7');
fprintf('ASCT paired benchmark PASSED: %d independent simulations x 2 trials x 2 bands.\n',nReplicates);
fprintf('Mean delta F1 (wide-narrow) = %.4f [95%% bootstrap CI: %.4f, %.4f]\n', ...
    summary.meanDeltaF1,summary.deltaCILow,summary.deltaCIHigh);
fprintf('Results: %s\n',outputDir);
end

function ci = localPercentileCI(samples)
x = sort(samples(:));
n = numel(x);
ci = [x(max(1,ceil(.025*n))),x(min(n,ceil(.975*n)))];
end
