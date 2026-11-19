function [T,summary] = asct_m7_study(outputDir,opts)
%ASCT_M7_STUDY Localization-factor sensitivity on a synthetic inverse proxy.
% Evaluates lambda/depth/norm interactions on PAIRED sensor observations.
% Distinct from actual FieldTrip MNE STEP8; see M6_M9_README.md.
if nargin<1 || isempty(outputDir),outputDir=fullfile(pwd,'m7_results');end
if nargin<2,opts=struct();end
assert(~isfolder(outputDir),'ASCT:Study:OutputExists', ...
    'Output directory already exists: %s',outputDir);
if ~isfield(opts,'nReplicates'),opts.nReplicates=5;end
if ~isfield(opts,'nBootstrap'),opts.nBootstrap=500;end
if ~isfield(opts,'seed'),opts.seed=20261120;end
if ~isfield(opts,'lambdas'),opts.lambdas=[0.01 0.1];end
if ~isfield(opts,'depthWeights'),opts.depthWeights=[0 0.5];end
if ~isfield(opts,'simulation')
    opts.simulation=struct('fs',128,'nSamples',384,'nTrials',12,'nSensors',24);
end
if ~isfield(opts,'source')
    opts.source=struct('nSources',5,'distanceCm',2,'nInteractions',4, ...
        'strength',0.4,'lag',2,'snrDb',10);
end
if ~isfield(opts,'mvar')
    opts.mvar=struct('orderMode','fixed','fixedOrder',2,'maxMvarOrder',6, ...
        'varNorm',false,'removeERP',false);
end
assert(opts.nReplicates>=2 && opts.nReplicates==fix(opts.nReplicates) && ...
    opts.nBootstrap>=100 && opts.nBootstrap==fix(opts.nBootstrap), ...
    'ASCT:M7:Runs','Invalid replication or bootstrap count');
assert(isnumeric(opts.lambdas) && isvector(opts.lambdas) && ...
    ~isempty(opts.lambdas) && all(opts.lambdas>0) && all(isfinite(opts.lambdas)) && ...
    isnumeric(opts.depthWeights) && isvector(opts.depthWeights) && ...
    ~isempty(opts.depthWeights) && all(isfinite(opts.depthWeights)) && ...
    all(opts.depthWeights>=0) && all(opts.depthWeights<=1), ...
    'ASCT:M7:Factors','Invalid lambda or depth factors');
lambdas=unique(opts.lambdas(:)');depths=unique(opts.depthWeights(:)');
rows=cell(opts.nReplicates*numel(depths)*(numel(lambdas)+1),1);k=0;
for r=1:opts.nReplicates
    cfg=opts.source;
    cfg.simSeed=mod(double(opts.seed)+r*1009,2147483646)+1;
    cfg.evokedAmplitude=0;cfg.varianceDrift=0;
    sim=asct_m6_generate(cfg,opts.simulation);
    freq=linspace(1,min(40,sim.fs/2),40);
    for d=depths
        for j=1:numel(lambdas)+1
            if j<=numel(lambdas)
                normMode='lambda'; lambda=lambdas(j);
            else
                normMode='cov'; lambda=NaN; % no inert lambda rows
            end
            loc=struct('norm',normMode,'depthWeight',d);
            if strcmp(normMode,'lambda'),loc.lambda=lambda;end
            [roi,info]=asct_m7_inverse_proxy(sim,loc);
            fit=asct_m8_fit(roi,opts.mvar);
            score=asct_m9_evaluate(fit,sim.trueA,sim.truth,sim.fs,freq);
            k=k+1;
            rows{k,1}=table(r,cfg.simSeed,{normMode},lambda,d,info.regularization, ...
                info.sourceRMSE,info.spatialLeakageFro,score.f1, ...
                score.falsePositiveRate,score.lagMAE,score.strengthMAE, ...
                score.spectralRadius,score.stable,score.validForInference, ...
                'VariableNames',{'replicate','simSeed','normMode','lambda','depthWeight', ...
                'effectiveRegularization','sourceRMSE','spatialLeakageFro', ...
                'f1','falsePositiveRate','lagMAE','strengthMAE', ...
                'spectralRadius','stable','validForInference'});
        end
    end
end
T=vertcat(rows{:});
summary=asct_m9_table_summary(T,{'normMode','lambda','depthWeight'}, ...
    {'sourceRMSE','spatialLeakageFro','f1','falsePositiveRate'}, ...
    opts.nBootstrap,opts.seed);
assert(~isfolder(outputDir),'ASCT:M7:OutputExists','Use a fresh outputDir');
mkdir(outputDir);
writetable(T,fullfile(outputDir,'m7_cases.csv'));
writetable(summary,fullfile(outputDir,'m7_summary.csv'));
save(fullfile(outputDir,'m7_results.mat'),'T','summary','opts');
end
