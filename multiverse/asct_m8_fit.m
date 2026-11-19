function fit = asct_m8_fit(data,options)
%ASCT_M8_FIT Oracle/ROI-level OLS MVAR sensitivity reference.
% Not production multar1m. AIC uses asct_mvar_aic with shared window.
% varNorm uses one global std per ROI (not multar norm1 implementation).
% A is transformed back to physical units for coefficient-error metrics;
% Adtf remains in the analyzed scale (which changes DTF under varNorm).
assert(isnumeric(data) && ndims(data)<=3 && all(isfinite(data(:))), ...
    'ASCT:M8:Data','Data must be finite nROI x time x trial');
if ismatrix(data),data=reshape(data,size(data,1),size(data,2),1);end
[n,T,nTr]=size(data);
assert(n>=2 && T>=30 && nTr>=2,'ASCT:M8:Data','Insufficient ROI data');
assert(isfield(options,'orderMode') && ...
    ismember(char(options.orderMode),{'fixed','aic'}), ...
    'ASCT:M8:Order','orderMode must be fixed or aic');
assert(isfield(options,'varNorm') && isscalar(options.varNorm) && ...
    ismember(double(options.varNorm),[0,1]), ...
    'ASCT:M8:Norm','varNorm must be 0 or 1');
assert(isfield(options,'removeERP') && isscalar(options.removeERP) && ...
    ismember(double(options.removeERP),[0,1]), ...
    'ASCT:M8:ERP','removeERP must be 0 or 1');
if options.removeERP, data=asct_remove_erp(data); end
scale=ones(n,1);
if options.varNorm
    scale=std(reshape(data,n,[]),0,2);
    assert(all(scale>eps),'ASCT:M8:Norm','ROI has zero variance');
end
x=bsxfun(@rdivide,data,reshape(scale,n,1,1));
if strcmp(char(options.orderMode),'fixed')
    assert(isfield(options,'fixedOrder') && options.fixedOrder>=1 && ...
        options.fixedOrder==fix(options.fixedOrder), ...
        'ASCT:M8:Order','Invalid fixedOrder');
    order=options.fixedOrder;
    aic=[];
else
    assert(isfield(options,'maxMvarOrder') && options.maxMvarOrder>=1, ...
        'ASCT:M8:Order','Missing maxMvarOrder');
    [order,aic]=asct_mvar_aic(x,options.maxMvarOrder);
end
[Astandardized,~,info]=asct_mvar_fit(x,order);
A=zeros(size(Astandardized));
for ell=1:order
    A(:,:,ell)=bsxfun(@times,bsxfun(@rdivide, ...
        Astandardized(:,:,ell),scale'),scale);
end
physicalResidual=bsxfun(@times,info.residual,scale);
fit=struct('A',A,'Adtf',Astandardized,'order',order,'aicValues',aic, ...
    'diagnostics',asct_m8_diagnostics(data,physicalResidual,order,A), ...
    'normalizationScale',scale,'nObservations',info.nObservations, ...
    'oracleOLS',true,'productionMultarValidated',false);
end
