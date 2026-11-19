function sim = asct_m6_generate(cfg,opts)
%ASCT_M6_GENERATE Reproducible directed VAR and geometry-dependent sensor data.
% truth(target,source) and trueA(target,source,lag) are the generating graph.
% This is a SYNTHETIC forward model, not a head model or FieldTrip output.
% Models with nSources=11..12 support the separate M8 ROI sensitivity test;
% M6 scenario studies are restricted to 3..10 by asct_m6_study.
if nargin<2 || isempty(opts)
    opts=struct('fs',128,'nSamples',384,'nTrials',12,'nSensors',24);
end
required={'nSources','distanceCm','nInteractions','strength','lag','snrDb','simSeed'};
for i=1:numel(required)
    assert(isfield(cfg,required{i}),'ASCT:M6:Config','Missing cfg.%s',required{i});
end
n=cfg.nSources;
assert(isscalar(n) && n==fix(n) && n>=3 && n<=12, ...
    'ASCT:M6:Sources','nSources must be between 3 and 12');
assert(isfinite(cfg.distanceCm) && cfg.distanceCm>0, ...
    'ASCT:M6:Distance','distanceCm must be positive');
maxEdges=n*(n-1)/2; % acyclic graph: source < target
assert(isscalar(cfg.nInteractions) && cfg.nInteractions==fix(cfg.nInteractions) && ...
    cfg.nInteractions>=0 && cfg.nInteractions<=maxEdges, ...
    'ASCT:M6:Interactions','nInteractions outside acyclic graph capacity');
assert(isscalar(cfg.strength) && isfinite(cfg.strength) && ...
    cfg.strength>=0 && cfg.strength<=0.7 && ...
    (cfg.nInteractions==0 || cfg.strength>0), ...
    'ASCT:M6:Strength','A claimed interaction must have nonzero strength');
assert(isscalar(cfg.lag) && cfg.lag==fix(cfg.lag) && cfg.lag>=1 && cfg.lag<=20, ...
    'ASCT:M6:Lag','lag must be an integer from 1 to 20');
assert(isscalar(cfg.snrDb) && isfinite(cfg.snrDb), ...
    'ASCT:M6:SNR','snrDb must be finite');
assert(isscalar(cfg.simSeed) && cfg.simSeed>=1 && cfg.simSeed==fix(cfg.simSeed) && ...
    cfg.simSeed<=2147483646,'ASCT:M6:Seed','Invalid simulation seed');
assert(all(isfield(opts,{'fs','nSamples','nTrials','nSensors'})), ...
    'ASCT:M6:Options','Require fs, nSamples, nTrials and nSensors');
fs=opts.fs; T=opts.nSamples; nTr=opts.nTrials; nSens=opts.nSensors;
assert(fs>0 && nSens>=n && fix(nSens)==nSens && ...
    T>=max(100,cfg.lag+20) && T==fix(T) && ...
    nTr>=2 && nTr==fix(nTr), 'ASCT:M6:Options','Invalid sample/trial/sensor counts');
if ~isfield(cfg,'evokedAmplitude'),cfg.evokedAmplitude=0;end
if ~isfield(cfg,'varianceDrift'),cfg.varianceDrift=0;end
assert(isfinite(cfg.evokedAmplitude) && cfg.evokedAmplitude>=0 && ...
    isfinite(cfg.varianceDrift) && cfg.varianceDrift>=0 && cfg.varianceDrift<=2, ...
    'ASCT:M6:Nonstationarity','ERP amplitude and variance drift must be non-negative');
previous=rng; cleanup=onCleanup(@()rng(previous)); %#ok<NASGU>
rng(cfg.simSeed,'twister');
% Lower triangular lag matrices and diagonal AR(1) guarantee a stable VAR
% despite substantial feed-forward coupling (no feedback cycles).
A=zeros(n,n,cfg.lag);
A(:,:,1)=0.25*eye(n);
[targets,sources]=find(tril(true(n),-1));
edgeCandidates=[targets sources];
% Keep one common ground-truth edge inside every nested 5/8/12 ROI set.
% The remaining acyclic edges are randomized per seed.
anchor=find(edgeCandidates(:,1)==2 & edgeCandidates(:,2)==1,1);
if cfg.nInteractions==0
    selection=[];
else
    other=find((1:size(edgeCandidates,1))'~=anchor);
    picks=randperm(numel(other),cfg.nInteractions-1);
    selection=[anchor;reshape(other(picks),[],1)];
end
truth=false(n,n);
% MATLAB for-loops iterate matrix columns, not vector elements. Iterate
% selection by index so each assignment creates exactly one directed edge.
for k=1:numel(selection)
    e=selection(k);
    target=edgeCandidates(e,1); source=edgeCandidates(e,2);
    A(target,source,cfg.lag)=cfg.strength;
    truth(target,source)=true;
end
burn=300;
endogenous=zeros(n,T,nTr);
innovationScale=1+cfg.varianceDrift*linspace(0,1,T);
% Only lag 1 and the selected interaction lag contain nonzero matrices.
% Skip zero-lag multiplications without changing the generating equations.
activeLags=find(reshape(any(any(A~=0,1),2),1,[]));
for tr=1:nTr
    x=zeros(n,T+burn);
    noise=randn(n,T+burn);
    noise(:,burn+1:end)=bsxfun(@times,noise(:,burn+1:end),innovationScale);
    for t=cfg.lag+1:T+burn
        xt=noise(:,t);
        for k=1:numel(activeLags)
            ell=activeLags(k);
            xt=xt+A(:,:,ell)*x(:,t-ell);
        end
        x(:,t)=xt;
    end
    endogenous(:,:,tr)=x(:,burn+1:end);
end
% ERP is added *after* the stationary generating VAR. Therefore trueA is
% ground truth for the underlying endogenous coupling, not for observed ERP.
time=(0:T-1)/fs;
erpWave=sin(2*pi*9*time).*exp(-0.5*((time-0.75)/0.18).^2);
erp=(cfg.evokedAmplitude*linspace(0.65,1.35,n)')*erpWave;
trueSources=bsxfun(@plus,endogenous,erp);
% A distance-aware, smooth leadfield with FIXED sensor geometry for a
% fixed nSources, regardless of distanceCm. Not a biophysical head model.
positionsCm=[(0:n-1)'*cfg.distanceCm zeros(n,2)];
if ~isfield(opts,'sensorCoverageDistanceCm')
    opts.sensorCoverageDistanceCm=6; % fixed montage for paired 1.5/6 cm tests
end
assert(isnumeric(opts.sensorCoverageDistanceCm) && ...
    isscalar(opts.sensorCoverageDistanceCm) && ...
    isfinite(opts.sensorCoverageDistanceCm) && ...
    opts.sensorCoverageDistanceCm>=cfg.distanceCm, 'ASCT:M6:Sensors', ...
    'Sensor montage must cover the tested source separation');
sensorPositionsCm=[linspace(-2,(n-1)*opts.sensorCoverageDistanceCm+2,nSens)' ...
    2*sin(2*pi*(0:nSens-1)'/nSens) 2*cos(2*pi*(0:nSens-1)'/nSens)];
L=zeros(nSens,n);
for j=1:n
    d2=sum(bsxfun(@minus,sensorPositionsCm,positionsCm(j,:)).^2,2);
    L(:,j)=exp(-d2/(2*3.5^2));
end
% Preserve column amplitudes: M7 depth weighting would be inert if every
% leadfield column were normalized to unit norm.
L=L/max(sqrt(mean(sum(L.^2,1).^2)),eps);
% Matrix-multiply all trial samples together; no cross-trial mixing occurs.
sensorEndogenous=L*reshape(endogenous,n,[]);
sensorVariance=mean(sensorEndogenous(:).^2)/10^(cfg.snrDb/10);
sourceVariance=mean(endogenous(:).^2)/10^(cfg.snrDb/10);
sensors=reshape(L*reshape(trueSources,n,[]),nSens,T,nTr);
sensors=sensors+sqrt(sensorVariance)*randn(size(sensors));
observedSources=trueSources+sqrt(sourceVariance)*randn(size(trueSources));
sim=struct('trueA',A,'truth',truth,'endogenousSources',endogenous, ...
    'trueSources',trueSources,'observedSources',observedSources, ...
    'sensors',sensors,'mixing',L,'positionsCm',positionsCm, ...
    'sensorPositionsCm',sensorPositionsCm,'evoked',erp, ...
    'innovationScale',innovationScale,'fs',fs,'sensorNoiseVariance',sensorVariance, ...
    'sourceNoiseVariance',sourceVariance,'config',cfg,'syntheticForwardModel',true);
end
