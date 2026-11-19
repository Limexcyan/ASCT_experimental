function d = asct_m8_diagnostics(data,residual,order,A)
%ASCT_M8_DIAGNOSTICS Descriptive diagnostics for a fitted pooled-trial VAR.
% No single check proves stationarity. maxLag1ResidualCorrelation is a
% screening statistic, not a significance test or a substitute for Ljung-Box.
assert(isnumeric(data) && ndims(data)<=3 && all(isfinite(data(:))), ...
    'ASCT:M8:Data','Expected finite nROI x time x trial data');
if ismatrix(data), data=reshape(data,size(data,1),size(data,2),1); end
[n,T,nTr]=size(data);
assert(order>=1 && order==fix(order) && T>order+1, ...
    'ASCT:M8:Order','Invalid order');
assert(isequal(size(residual),[n (T-order)*nTr]), ...
    'ASCT:M8:Residual','Unexpected number of residual observations');
R=reshape(residual,n,T-order,nTr);
a=R(:,1:end-1,:); b=R(:,2:end,:);
rho=zeros(n,1);
for i=1:n
    aa=reshape(a(i,:,:),1,[]);
    bb=reshape(b(i,:,:),1,[]);
    den=sqrt(sum(aa.^2)*sum(bb.^2));
    if den>0, rho(i)=sum(aa.*bb)/den; end
end
half=floor(T/2);
first=data(:,1:half,:); second=data(:,half+1:end,:);
v1=var(reshape(first,n,[]),0,2);
v2=var(reshape(second,n,[]),0,2);
varianceRatio=v2./max(v1,eps);
% Magnitude of phase-locked mean relative to overall signal RMS.
trialMean=mean(data,3);
evokedRMS=sqrt(mean(trialMean(:).^2));
wholeRMS=sqrt(mean(data(:).^2));
% Companion matrix spectral radius: >=1 is an unstable fitted VAR.
p=size(A,3);
C=zeros(n*p);
C(1:n,:)=reshape(A,n,n*p);
if p>1, C(n+1:end,1:n*(p-1))=eye(n*(p-1)); end
radius=max(abs(eig(C)));
d=struct('spectralRadius',radius,'stable',radius<1, ...
    'maxLag1ResidualCorrelation',max(abs(rho)), ...
    'residualLag1Correlation',rho, ...
    'varianceRatioSecondToFirst',varianceRatio, ...
    'maxVarianceRatio',max(max(varianceRatio,1./max(varianceRatio,eps))), ...
    'evokedRMSFraction',evokedRMS/max(wholeRMS,eps));
end
