function metrics = asct_multiverse_source_benchmark(cfg,study,nBootstrap,sim)
% Fast single-case reference: simulate sources -> reference bandpass -> OLS MVAR -> DTF.
% NOT FieldTrip source localization or ASCT's multar; do not interpret its
% localization factors as experimentally tested here.
if nargin<3, nBootstrap=0; end
if nargin<4 || isempty(sim), sim=asct_multiverse_simulate(cfg,study.simulation); end
data=sim.observedSources;
if strcmp(cfg.bandMode,'wide')
    band=study.wideBandHz;
else
    band=study.narrowBandHz;
end
data=asct_multiverse_bandpass(data,sim.fs,band);
if cfg.removeERP, data=asct_remove_erp(data); end
if cfg.varNorm
    scale=std(data,0,2);
    assert(all(scale(:)>0),'ASCT:ZeroVariance','Cannot normalize constant channel');
    data=bsxfun(@rdivide,data,scale);
end
if strcmp(cfg.orderMode,'aic')
    order=asct_mvar_aic(data,study.maxMvarOrder);
else
    order=cfg.fixedOrder;
end
A=asct_mvar_fit(data,order);
freq=linspace(band(1),band(2),50);
dtf=asct_mvar_dtf(A,sim.fs,freq);
metrics=asct_multiverse_score(dtf,sim.truth);
metrics.estimatedOrder=order;
metrics.oracleSourceBenchmark=true;
metrics.snrDb=cfg.snrDb;
metrics.nSources=cfg.nSources;
metrics.simSeed=cfg.simSeed;
if nBootstrap>0
    assert(nBootstrap==fix(nBootstrap) && nBootstrap>=2,'ASCT:InvalidBootstrap','Need >=2 bootstrap draws');
    oldRng=rng;
    restoreRng=onCleanup(@() rng(oldRng)); %#ok<NASGU>
    rng(mod(cfg.simSeed+719,2147483647),'twister');
    scores=zeros(nBootstrap,1);
    for b=1:nBootstrap
        trialIdx=randi(size(data,3),1,size(data,3));
        Ab=asct_mvar_fit(data(:,:,trialIdx),order);
        db=asct_mvar_dtf(Ab,sim.fs,freq);
        bs=asct_multiverse_score(db,sim.truth);
        scores(b)=bs.f1;
    end
    sorted=sort(scores);
    metrics.bootstrapF1CI=[sorted(max(1,ceil(.025*nBootstrap))),sorted(min(nBootstrap,ceil(.975*nBootstrap)))];
end
end
