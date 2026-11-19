function [T,summary,erpPairs] = asct_m8_study(outputDir,opts)
%ASCT_M8_STUDY Paired ERP / drift / 5-12 ROI / MVAR factorial benchmark.
% Uses synthetic ROI signals, NOT FieldTrip STEP9 nor production multar1m.
% Same replicate seed for every ERP amplitude and analysis factor. Compare
% 5,8,12 ROI as distinct network definitions; do NOT compare raw NDTF
% matrices of different dimensions without aligning the shared ROIs.
if nargin<1 || isempty(outputDir),outputDir=fullfile(pwd,'m8_results');end
if nargin<2,opts=struct();end
assert(~isfolder(outputDir),'ASCT:Study:OutputExists', ...
    'Output directory already exists: %s',outputDir);
if ~isfield(opts,'seed'),opts.seed=20261121;end
if ~isfield(opts,'nReplicates'),opts.nReplicates=5;end
if ~isfield(opts,'nBootstrap'),opts.nBootstrap=500;end
if ~isfield(opts,'roiCounts'),opts.roiCounts=[5 8 12];end
if ~isfield(opts,'evokedAmplitudes'),opts.evokedAmplitudes=[0 1];end
if ~isfield(opts,'varianceDrifts'),opts.varianceDrifts=[0 0.7];end
if ~isfield(opts,'orderModes'),opts.orderModes={'fixed','aic'};end
if ~isfield(opts,'normModes'),opts.normModes=[0 1];end
if ~isfield(opts,'removeERPModes'),opts.removeERPModes=[false true];end
if ~isfield(opts,'fixedOrder'),opts.fixedOrder=2;end
if ~isfield(opts,'maxMvarOrder'),opts.maxMvarOrder=5;end
if ~isfield(opts,'threshold'),opts.threshold=0.15;end
if ~isfield(opts,'simulation')
    opts.simulation=struct('fs',128,'nSamples',384,'nTrials',12,'nSensors',24);
end
if ~isfield(opts,'source')
    opts.source=struct('nSources',12,'distanceCm',2,'nInteractions',12, ...
        'strength',0.35,'lag',2,'snrDb',15);
end
assert(opts.nReplicates>=2 && opts.nReplicates==fix(opts.nReplicates) && ...
    opts.nBootstrap>=100 && opts.nBootstrap==fix(opts.nBootstrap), ...
    'ASCT:M8:Runs','Need >=2 independent replicates and >=100 draws');
counts=opts.roiCounts(:)';
assert(all(counts>=5) && all(counts<=12) && ...
    all(counts==fix(counts)) && max(counts)<=opts.source.nSources, ...
    'ASCT:M8:ROI','ROI levels must be 5..12 and exist in generated data');
assert(numel(unique(opts.normModes))==numel(opts.normModes) && ...
    all(ismember(opts.normModes,[0 1])) && ...
    all(ismember(opts.removeERPModes,[0 1])), ...
    'ASCT:M8:Factors','Invalid normalization/ERP factors');
assert(all(opts.evokedAmplitudes>=0) && all(opts.varianceDrifts>=0), ...
    'ASCT:M8:Factors','ERP and drift must be non-negative');
nCases=opts.nReplicates*numel(opts.evokedAmplitudes)*numel(opts.varianceDrifts)* ...
    numel(counts)*numel(opts.orderModes)*numel(opts.normModes)*numel(opts.removeERPModes);
assert(nCases>0 && nCases<=20000,'ASCT:M8:Runs','Invalid or excessive factorial grid');
records=cell(nCases,1); k=0;
for r=1:opts.nReplicates
    for amplitude=opts.evokedAmplitudes
        for drift=opts.varianceDrifts
            cfg=opts.source;
            cfg.simSeed=mod(double(opts.seed)+r*1009,2147483646)+1;
            cfg.evokedAmplitude=amplitude;
            cfg.varianceDrift=drift;
            sim=asct_m6_generate(cfg,opts.simulation);
            freq=linspace(1,min(40,sim.fs/2),40);
            for nr=counts
                data=sim.observedSources(1:nr,:,:);
                trueA=sim.trueA(1:nr,1:nr,:);
                truth=sim.truth(1:nr,1:nr);
                for oi=1:numel(opts.orderModes)
                    orderMode=char(opts.orderModes{oi});
                    for normMode=opts.normModes
                        for removeERP=opts.removeERPModes
                            settings=struct('orderMode',orderMode,'fixedOrder',opts.fixedOrder, ...
                                'maxMvarOrder',opts.maxMvarOrder,'varNorm',normMode, ...
                                'removeERP',logical(removeERP));
                            fit=asct_m8_fit(data,settings);
                            score=asct_m9_evaluate(fit,trueA,truth,sim.fs,freq,opts.threshold);
                            k=k+1;
                            records{k}=table(r,cfg.simSeed,nr,amplitude,drift, ...
                                {orderMode},logical(normMode),logical(removeERP), ...
                                fit.order,score.nTrueEdges,score.precision,score.recall, ...
                                score.f1,score.falsePositiveRate,score.lagMAE, ...
                                score.strengthMAE,score.spectralRadius,score.stable,score.validForInference, ...
                                score.residualLag1,score.maxVarianceRatio,score.evokedRMSFraction, ...
                                'VariableNames',{'replicate','simSeed','nROIs', ...
                                'evokedAmplitude','varianceDrift','orderMode','varNorm', ...
                                'removeERP','estimatedOrder','nTrueEdges','precision', ...
                                'recall','f1','falsePositiveRate','lagMAE','strengthMAE', ...
                                'spectralRadius','stable','validForInference','residualLag1','maxVarianceRatio', ...
                                'evokedRMSFraction'});
                        end
                    end
                end
            end
        end
    end
end
assert(k==nCases,'ASCT:M8:Runs','Incomplete M8 grid');
T=vertcat(records{:});
groups={'nROIs','evokedAmplitude','varianceDrift','orderMode','varNorm','removeERP'};
summary=asct_m9_table_summary(T,groups, ...
    {'f1','falsePositiveRate','lagMAE','strengthMAE','estimatedOrder', ...
    'residualLag1','maxVarianceRatio','evokedRMSFraction'}, ...
    opts.nBootstrap,opts.seed);
erpPairs=asct_m9_paired_erp(T);
erpEffectSummary=asct_m9_paired_inference(erpPairs, ...
    {'nROIs','evokedAmplitude','varianceDrift','orderMode','varNorm'}, ...
    {'fprReduction','f1Gain'},opts.nBootstrap,opts.seed,'holm',0.05);
[robustnessCases,robustnessSummary]=asct_m9_robustness(T,opts.nBootstrap,opts.seed);
assert(~isfolder(outputDir),'ASCT:M8:OutputExists', ...
    'Use a fresh outputDir to protect previous results');
mkdir(outputDir);
writetable(T,fullfile(outputDir,'m8_cases.csv'));
writetable(summary,fullfile(outputDir,'m8_summary.csv'));
writetable(erpPairs,fullfile(outputDir,'m9_erp_pairs.csv'));
writetable(erpEffectSummary,fullfile(outputDir,'m9_erp_effect_summary.csv'));
writetable(robustnessCases,fullfile(outputDir,'m9_robustness_cases.csv'));
writetable(robustnessSummary,fullfile(outputDir,'m9_robustness_summary.csv'));
save(fullfile(outputDir,'m8_results.mat'),'T','summary','erpPairs', ...
    'erpEffectSummary','robustnessCases','robustnessSummary','opts');
end
