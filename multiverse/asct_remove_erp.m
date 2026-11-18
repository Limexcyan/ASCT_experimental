function cleaned = asct_remove_erp(data,trialLength)
% Remove the across-trial evoked mean at every time sample (NOT mean division).
% Supports nROI x samples x trials OR the nROI x concatenated-trials matrix
% written by ASCT into mltin. A single trial cannot support ERP subtraction.
assert(isnumeric(data) && ndims(data)<=3 && all(isfinite(data(:))), 'ASCT:InvalidSignal', ...
    'Data must be a finite numeric 2-D or 3-D array');
if ismatrix(data)
    assert(nargin>=2 && trialLength>1 && trialLength==fix(trialLength) && ...
        mod(size(data,2),trialLength)==0, 'ASCT:InvalidTrialLength', ...
        'Trial length must divide the concatenated sample count');
    sz = size(data);
    x = reshape(data,sz(1),trialLength,[]);
else
    x = data;
end
assert(size(x,3)>=2, 'ASCT:TooFewTrials', 'At least two trials are necessary to estimate ERP');
x = bsxfun(@minus,x,mean(x,3));
if ismatrix(data)
    cleaned = reshape(x,size(data));
else
    cleaned = x;
end
end
