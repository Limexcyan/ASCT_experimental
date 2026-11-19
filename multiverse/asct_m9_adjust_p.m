function adjusted = asct_m9_adjust_p(pValues,method)
%ASCT_M9_ADJUST_P Holm FWER, BH FDR, Bonferroni or unadjusted p-values.
% NaN indicates an undefined hypothesis and is excluded from the family.
if nargin<2 || isempty(method),method='holm';end
method=lower(char(method));
assert(ismember(method,{'holm','bh','bonferroni','none'}), ...
    'ASCT:M9:Correction','Unknown multiplicity correction');
assert(isnumeric(pValues) && isreal(pValues) && ...
    all(isnan(pValues(:)) | (isfinite(pValues(:)) & ...
    pValues(:)>=0 & pValues(:)<=1)), ...
    'ASCT:M9:PValue','p-values must be in [0,1] or NaN');
adjusted=NaN(size(pValues));
ix=find(isfinite(pValues));
n=numel(ix);
if n==0,return;end
[p,order]=sort(pValues(ix));
switch method
    case 'none'
        q=p;
    case 'bonferroni'
        q=min(1,n*p);
    case 'holm'
        q=min(1,cummax((n-(1:n)'+1).*p(:)));
    case 'bh'
        ranks=(1:n)';
        q=flipud(cummin(flipud(n*p(:)./ranks)));
        q=min(1,q);
end
pos=ix(order);
adjusted(pos)=reshape(q,[],1);
end
