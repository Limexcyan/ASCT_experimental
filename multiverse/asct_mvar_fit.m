function [A,Sigma,info] = asct_mvar_fit(data,order,commonStart)
% Pooled-trial OLS MVAR. A(target, source, lag), never links trials across ends.
assert(isnumeric(data) && ndims(data)<=3 && all(isfinite(data(:))), 'ASCT:InvalidSignal', ...
    'Data must be finite nROIs x nSamples x nTrials');
if ismatrix(data), data = reshape(data,size(data,1),size(data,2),1); end
[n,T,nTrials] = size(data);
assert(order==fix(order) && order>=1 && T>order+2,'ASCT:InvalidOrder','Invalid MVAR order');
if nargin<3, commonStart = order+1; end
assert(commonStart>order && commonStart<=T, 'ASCT:InvalidOrder', 'Invalid common start index');
nObs = (T-commonStart+1)*nTrials;
assert(nObs>n*order+n, 'ASCT:InsufficientSamples', 'Not enough observations for fitted model');
X = zeros(n*order,nObs);
Y = zeros(n,nObs);
for tr=1:nTrials
    col=(tr-1)*(T-commonStart+1)+(1:(T-commonStart+1));
    Y(:,col) = data(:,commonStart:T,tr);
    for lag=1:order
        X((lag-1)*n+(1:n),col) = data(:,commonStart-lag:T-lag,tr);
    end
end
B = Y / X;
res = Y - B*X;
Sigma = (res*res') / nObs;
Sigma = (Sigma+Sigma')/2;
A = reshape(B,n,n,order);
info.nObservations = nObs;
info.residual = res;
end
