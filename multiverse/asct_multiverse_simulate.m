function sim = asct_multiverse_simulate(cfg,options)
% Reproducible single-case directed VAR simulation and sensor mixing.
% Directed chain: source i -> target i+1, with source spacing distanceCm.
% The sensor mixing is deliberately synthetic, not a FieldTrip head model.
if nargin<2, options=asct_multiverse_defaults(); options=options.simulation; end
n=cfg.nSources; T=options.nSamples; nTr=options.nTrials; fs=options.fs;
assert(n>=3 && n<=10 && n==fix(n),'ASCT:InvalidSources','nSources must be 3..10');
assert(cfg.distanceCm>=1.5,'ASCT:InvalidDistance','Use at least 1.5 cm spacing');
assert(cfg.nInteractions>=0 && cfg.nInteractions<=n-1 && cfg.nInteractions==fix(cfg.nInteractions), ...
    'ASCT:InvalidInteractions','This chain simulator supports 0..nSources-1 interactions');
assert(cfg.lag>=1 && cfg.lag==fix(cfg.lag) && cfg.lag<=20, 'ASCT:InvalidLag','Invalid lag');
assert(cfg.strength>=0 && cfg.strength<1, 'ASCT:InvalidStrength','Strength must be in [0,1)');
assert(isfinite(cfg.snrDb),'ASCT:InvalidSNR','SNR must be finite');
assert(T>cfg.lag+20 && nTr>=2 && options.nSensors>=n,'ASCT:InvalidSimulation','Insufficient sample/trial/sensor count');
priorRng=rng;
restoreRng=onCleanup(@() rng(priorRng)); %#ok<NASGU>
rng(cfg.simSeed,'twister');
A=zeros(n,n,cfg.lag);
A(:,:,1)=0.35*eye(n);
truth=false(n);
for e=1:cfg.nInteractions
    A(e+1,e,cfg.lag) = cfg.strength;
    truth(e+1,e)=true;
end
burn=250;
src=zeros(n,T,nTr);
for tr=1:nTr
    x=zeros(n,T+burn);
    epsnoise=randn(n,T+burn);
    for t=cfg.lag+1:T+burn
        x(:,t)=epsnoise(:,t);
        for ell=1:cfg.lag
            x(:,t)=x(:,t)+A(:,:,ell)*x(:,t-ell);
        end
    end
    src(:,:,tr)=x(:,burn+1:end);
end
% Phase-locked evoked response (a non-stationary confound in MVAR).
time=(0:T-1)/fs;
erp=sin(2*pi*9*time).*exp(-0.5*((time-1.0)/0.2).^2);
weights=linspace(0.5,1.5,n)';
for tr=1:nTr
    src(:,:,tr)=src(:,:,tr)+cfg.evokedAmplitude*(weights*erp);
end
[Q,~]=qr(randn(options.nSensors,n),0);
mix=Q;
sensorClean=zeros(options.nSensors,T,nTr);
for tr=1:nTr, sensorClean(:,:,tr)=mix*src(:,:,tr); end
noisePower=mean(sensorClean(:).^2)/10^(cfg.snrDb/10);
sensorNoisy=sensorClean+sqrt(noisePower)*randn(size(sensorClean));
% Simplified ROI measurement noise is ONLY for source-level benchmark runs.
sourceNoisePower=mean(src(:).^2)/10^(cfg.snrDb/10);
srcObserved=src+sqrt(sourceNoisePower)*randn(size(src));
sim.trueSources=src;
sim.observedSources=srcObserved;
sim.sensors=sensorNoisy;
sim.mixing=mix;
sim.trueA=A;
sim.truth=truth;
sim.positionsCm=[(0:n-1)'*cfg.distanceCm zeros(n,2)];
sim.fs=fs;
sim.snrDb=cfg.snrDb;
sim.simSeed=cfg.simSeed;
end
