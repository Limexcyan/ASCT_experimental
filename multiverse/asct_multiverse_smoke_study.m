function study = asct_multiverse_smoke_study()
% ASCT_MULTIVERSE_SMOKE_STUDY Fixed, reproducible two-trial oracle design.
% Shared between the single-case smoke and independent-replicate benchmark.
% Only bandMode varies across pathways; all other factors are fixed.
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

end
