function report = asct_m9_residual_tests(residual,modelOrder,maxLag,alpha)
%ASCT_M9_RESIDUAL_TESTS Per-ROI approximate Ljung-Box residual checks.
% The residual array is ROI x time x independent trial; correlations never
% cross trial boundaries. The chi-square reference with (maxLag-order)
% degrees of freedom is an APPROXIMATION for fitted VAR residuals, not a
% validated multivariate portmanteau test. A rejection is a warning, not
% proof of nonstationarity or an automatic disqualification of a dataset.
if nargin<4 || isempty(alpha),alpha=0.05;end
assert(isnumeric(residual) && isreal(residual) && ndims(residual)<=3 && ...
    all(isfinite(residual(:))), ...
    'ASCT:M9:Residual','Require finite real ROI x time x trial residuals');
if ismatrix(residual)
    residual=reshape(residual,size(residual,1),size(residual,2),1);
end
[n,T,nTr]=size(residual);
assert(n>=1 && T>=10 && nTr>=1 && ...
    isscalar(modelOrder) && modelOrder>=0 && modelOrder==fix(modelOrder) && ...
    isscalar(maxLag) && maxLag==fix(maxLag) && maxLag>modelOrder && ...
    maxLag<T/2, ...
    'ASCT:M9:Lags','Require 0<=order<maxLag<T/2');
assert(isscalar(alpha) && isfinite(alpha) && alpha>0 && alpha<1, ...
    'ASCT:M9:Alpha','alpha must lie in (0,1)');
% Center each ROI using its pooled across-trial residual mean.
R=bsxfun(@minus,residual,reshape(mean(reshape(residual,n,[]),2),n,1,1));
q=zeros(n,1);lag1=zeros(n,1);maxAbs=zeros(n,1);
pValue=NaN(n,1);
nObs=T*nTr;
df=maxLag-modelOrder;
for roi=1:n
    x=reshape(R(roi,:,:),T,nTr);
    variance=sum(x(:).^2);
    if variance<=eps,continue;end
    rho=zeros(maxLag,1);
    for lag=1:maxLag
        a=x(1:T-lag,:);
        b=x(1+lag:T,:);
        rho(lag)=sum(a(:).*b(:))/variance;
    end
    lag1(roi)=rho(1);
    maxAbs(roi)=max(abs(rho));
    denominator=nObs-nTr*(1:maxLag)';
    q(roi)=nObs*(nObs+2)*sum(rho.^2./denominator);
    pValue(roi)=gammainc(q(roi)/2,df/2,'upper');
end
pHolm=asct_m9_adjust_p(pValue,'holm');
report=table((1:n)',lag1,maxAbs,q,repmat(df,n,1),pValue,pHolm, ...
    pHolm<=alpha,'VariableNames',{'roi','lag1Correlation', ...
    'maxAbsAutocorrelation','ljungBoxQ','degreesOfFreedom', ...
    'pApprox','pHolm','rejectApproxWhiteness'});
end
