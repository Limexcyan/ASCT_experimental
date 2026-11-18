function f=asct_multiverse_validate_filter(f)
%ASCT_MULTIVERSE_VALIDATE_FILTER Validate effective STEP0 ExSetup settings.
% Keeps HPord/LPord and filter types set by ExSetup; these are NOT
% automatically inferred from passband cutoffs.
assert(isstruct(f) && isscalar(f),'ASCT:STEP0:InvalidFilter', ...
    'filter must be a scalar ExSetup struct');
for name={'HPfreq','LPfreq','resampleTo'}
    key=name{1};
    if ~isfield(f,key), continue; end
    v=f.(key);
    assert(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && v>=0, ...
        'ASCT:STEP0:InvalidFrequency','filter.%s must be a finite nonnegative scalar',key);
end
for name={'HPord','LPord'}
    key=name{1};
    if ~isfield(f,key), continue; end
    v=f.(key);
    if isempty(v), continue; end % existing ExSetup may defer FIR order
    assert(isnumeric(v) && isscalar(v) && isreal(v) && isfinite(v) && ...
        v>=1 && v==fix(v), ...
        'ASCT:STEP0:InvalidOrder','filter.%s must be a positive integer',key);
end
if isfield(f,'HPfreq') && isfield(f,'LPfreq') && ...
        f.HPfreq>0 && f.LPfreq>0
    assert(f.HPfreq<f.LPfreq, 'ASCT:STEP0:InvalidBand', ...
        'filter.HPfreq must be strictly lower than filter.LPfreq');
end
if isfield(f,'LPfreq') && isfield(f,'resampleTo') && ...
        f.LPfreq>0 && f.resampleTo>0
    assert(2*f.LPfreq<f.resampleTo, 'ASCT:STEP0:Nyquist', ...
        'filter.LPfreq must stay below resampleTo/2 to avoid aliasing');
end
end
