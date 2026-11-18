function [bestOrder,aicValues] = asct_mvar_aic(data,maxOrder)
% Headless AIC with common evaluation window for all candidate orders.
% Eliminates multar's estimateModelOrder GUI dependency in CI/simulations.
if nargin<2 || isempty(maxOrder), maxOrder = 10; end
assert(isnumeric(data) && all(isfinite(data(:))) && ndims(data)<=3, ...
    'ASCT:InvalidSignal','Finite MVAR data required');
if ismatrix(data), data=reshape(data,size(data,1),size(data,2),1); end
[n,T,nTrials]=size(data);
assert(maxOrder>=1 && maxOrder==fix(maxOrder),'ASCT:InvalidOrder','maxOrder must be positive integer');
maxOrder=min(maxOrder, T-3);
nObs=(T-maxOrder)*nTrials;
maxOrder=min(maxOrder, floor((nObs-n-1)/n));
nObs=(T-maxOrder)*nTrials;
assert(maxOrder>=1,'ASCT:InsufficientSamples','Not enough samples to select MVAR order');
startAt=maxOrder+1;
aicValues=inf(1,maxOrder);
for p=1:maxOrder
    try
        [~,S]=asct_mvar_fit(data,p,startAt);
        d=eig(S);
        if any(d<=0) || any(~isfinite(d)), continue; end
        logdet=sum(log(d));
        % -2 log-likelihood up to a shared additive constant.
        nParams=n*n*p+n*(n+1)/2;
        aicValues(p)=nObs*logdet+2*nParams;
    catch ME
        if ~strcmp(ME.identifier,'ASCT:InsufficientSamples'), rethrow(ME); end
    end
end
[~,bestOrder]=min(aicValues);
assert(isfinite(aicValues(bestOrder)), 'ASCT:UnestimableModel', 'Cannot estimate any stable covariance');
end
