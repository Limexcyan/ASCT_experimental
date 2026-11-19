function [sources,info] = asct_m7_inverse_proxy(sim,loc)
%ASCT_M7_INVERSE_PROXY Regularized geometric inverse, NOT FieldTrip MNE.
% loc.norm='cov' uses known synthetic sensor-noise variance as a ridge term.
% This is a diagnostic proxy, not the per-component SNR mode in
% MNE_functions/sc_sourceLocalize.m; do not extrapolate to real MNE.
assert(isstruct(sim) && isfield(sim,'mixing') && isfield(sim,'sensors') && ...
    isfield(sim,'sensorNoiseVariance'),'ASCT:M7:Input','Missing synthetic data');
assert(isfield(loc,'norm') && ismember(char(loc.norm),{'lambda','cov'}) && ...
    isfield(loc,'depthWeight') && isfinite(loc.depthWeight) && ...
    loc.depthWeight>=0 && loc.depthWeight<=1, ...
    'ASCT:M7:Loc','Invalid normalization or depth weighting');
L=sim.mixing;
assert(size(L,1)==size(sim.sensors,1),'ASCT:M7:Shape','Sensor dimensions differ');
energy=sum(L.^2,1);
assert(all(energy>eps),'ASCT:M7:Leadfield','Zero-norm leadfield column');
weights=energy.^(-loc.depthWeight/2);
G=bsxfun(@times,L,weights);
if strcmp(char(loc.norm),'lambda')
    assert(isfield(loc,'lambda') && isscalar(loc.lambda) && ...
        isfinite(loc.lambda) && loc.lambda>0, ...
        'ASCT:M7:Lambda','Positive lambda required');
    reg=loc.lambda*trace(G'*G)/size(G,2);
else
    reg=max(sim.sensorNoiseVariance,1e-10);
end
% Solve one source-space ridge system, then apply it to all time points.
% Do not form an explicit inverse or a large diagonal weighting matrix.
W=bsxfun(@times, ...
    (G'*G+reg*eye(size(G,2)))\G',weights(:));
[nSens,T,nTrials]=size(sim.sensors);
flat=reshape(sim.sensors,nSens,[]);
sources=reshape(W*flat,size(L,2),T,nTrials);
resolution=W*L;
leakage=resolution-diag(diag(resolution));
info=struct('regularization',reg,'depthWeight',loc.depthWeight, ...
    'norm',char(loc.norm),'spatialLeakageFro',norm(leakage,'fro'), ...
    'resolutionDiagonal',diag(resolution), ...
    'sourceRMSE',sqrt(mean((sources(:)-sim.trueSources(:)).^2)), ...
    'inverseProxy',true);
end
