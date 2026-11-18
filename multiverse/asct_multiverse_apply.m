function p = asct_multiverse_apply(p,cfg,study)
% Translate multiverse factors to ACTUAL sc_initAnalysis/FieldTrip/multar keys.
% p is an ASCT setup struct: rc, chan, filter, seg, ar, ica, loc, con, design.
required = {'rc','chan','filter','seg','ar','ica','loc','con','design'};
for i=1:numel(required)
    assert(isfield(p,required{i}), 'ASCT:MissingSetup', 'Missing ASCT setup field %s',required{i});
end
if strcmp(cfg.bandMode,'wide')
    band = study.wideBandHz;
elseif strcmp(cfg.bandMode,'narrow')
    band = study.narrowBandHz;
else
    error('ASCT:InvalidBand', 'Unknown band mode');
end
assert(numel(band)==2 && band(1)>0 && band(2)>band(1), 'ASCT:InvalidBand', 'Invalid frequency band');
p.filter.HPfreq = band(1);
p.filter.LPfreq = band(2);
assert(ismember(cfg.locNorm,{'lambda','cov'}), 'ASCT:InvalidNorm', 'Localization norm must be lambda or cov');
p.loc.norm = cfg.locNorm;
p.loc.lambda = cfg.lambda;
p.loc.depthWeight = cfg.depthWeight;
p.loc.method = cfg.locMethod;
% Current ASCT sc_sourceLocalize configures cfg.mne, not a generic inverse solver.
assert(strcmp(cfg.locMethod,'mne'), 'ASCT:UnsupportedLocalization', ...
    'Non-MNE methods require a separate FieldTrip method adapter');
assert(isfield(p.loc,'noiseLev') && p.loc.noiseLev>0, 'ASCT:MissingNoiseLevel', ...
    'FieldTrip MNE localization requires loc.noiseLev');
assert(isfield(p.loc,'ROI') && numel(p.loc.ROI)>=cfg.nROIs, 'ASCT:MissingROI', ...
    'At least nROIs anatomical ROIs must be provided by the setup');
p.con.chanSel = sprintf('1-%d',cfg.nROIs);
p.con.varNorm = cfg.varNorm;
p.con.removeERP = logical(cfg.removeERP);
p.con.maxMvarOrder = study.maxMvarOrder;
switch cfg.orderMode
    case 'fixed'
        assert(cfg.fixedOrder>=1 && cfg.fixedOrder==fix(cfg.fixedOrder),'ASCT:InvalidOrder', 'Fixed model order must be positive integer');
        p.con.mvarOrd = cfg.fixedOrder;
        p.con.orderSelection = 'fixed';
    case 'aic'
        p.con.mvarOrd = 0;
        p.con.orderSelection = 'aic';
    otherwise
        error('ASCT:InvalidOrder', 'Unknown model order mode');
end
% Distinct outputs prevent silent contamination/reuse of previous results.
p.rc.analysisName = [p.rc.analysisName '__' cfg.id];
% Filtering is changed: never reuse earlier preprocessed signals silently.
p.rc.load = 0;
p.rc.stop = 10;
% This runner evaluates bootstrap externally; avoids hardcoded sc_simsummary
% assumptions and the legacy sc_8_CONN simStats input filename bug.
p.rc.simStats = isfield(study,'useMultarBootstrap') && study.useMultarBootstrap;
if isfield(p.rc,'sim') && ~isempty(p.rc.sim) && p.rc.sim
    p.rc.simStatsFn = @() [];
end
end
