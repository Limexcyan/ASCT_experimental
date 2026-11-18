function study = asct_multiverse_defaults()
% ASCT_MULTIVERSE_DEFAULTS Explicit, small single-case demonstration design.
% Increase maxRuns intentionally; never run the entire combinatorial space by accident.
study.seed = 20261116;
study.maxRuns = 16;
study.factors.nSources = [3 5];
study.factors.distanceCm = [1.5 6]; % interacting neighbours: prox vs distant
study.factors.nInteractions = [1 2];
study.factors.strength = [0.2 0.4];
study.factors.lag = [1 2];
study.factors.snrDb = [0 15];
study.factors.evokedAmplitude = [0 0.8];
study.factors.bandMode = {'wide','narrow'};
study.factors.locNorm = {'lambda','cov'};
study.factors.lambda = [0.05 0.1];
study.factors.depthWeight = [0 0.5];
study.factors.locMethod = {'mne'};
study.factors.nROIs = [5 8];
study.factors.orderMode = {'fixed','aic'};
study.factors.fixedOrder = 2;
study.factors.varNorm = [0 1];
study.factors.removeERP = [0 1];
study.wideBandHz = [1 45];
study.narrowBandHz = [8 12];
study.maxMvarOrder = 10;
study.useMultarBootstrap = false; % Requires multar bootstrap config (bootnum etc.)
study.simulation.fs = 128;
study.simulation.nSamples = 512;
study.simulation.nTrials = 16;
study.simulation.nSensors = 20;
end
