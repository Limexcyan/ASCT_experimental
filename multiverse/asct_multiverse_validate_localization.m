function loc = asct_multiverse_validate_localization(loc,changed,strict,baseline)
%ASCT_MULTIVERSE_VALIDATE_LOCALIZATION Validate effective STEP8 MNE settings.
% Only parameters actually used by sc_sourceLocalize are supported.
% strict=true enforces complete prerequisites for a real STEP8 run; false
% keeps existing mock-based M1 workflows backward compatible.
if nargin<2 || isempty(changed), changed=struct(); end
if nargin<3, strict=false; end
% A factor level equal to the original ExSetup is not a parameter change.
% This matters when norm and lambda share a Cartesian grid: the cov row
% may retain the baseline lambda without claiming it affects the model.
if nargin<4 || isempty(baseline), baseline=struct(); end
assert(isstruct(baseline) && isscalar(baseline), ...
    'ASCT:M2:InvalidLocalization','baseline must be a scalar struct');
assert(isstruct(loc) && isscalar(loc) && isstruct(changed) && isscalar(changed), ...
    'ASCT:M2:InvalidLocalization','Localization settings must be scalar structs');
assert(islogical(strict) && isscalar(strict), ...
    'ASCT:M2:InvalidLocalization','strict must be logical scalar');
if ~isfield(loc,'method') || isempty(loc.method), loc.method='mne'; end
assert(isText(loc.method) && strcmpi(char(loc.method),'mne'), ...
    'ASCT:M2:UnsupportedMethod','STEP8 multiverse currently supports only MNE');
loc.method='mne';
if ~isfield(loc,'norm') || isempty(loc.norm), loc.norm='cov'; end
assert(isText(loc.norm) && ismember(lower(char(loc.norm)),{'lambda','cov'}), ...
    'ASCT:M2:InvalidNorm','loc.norm must be lambda or cov');
loc.norm=lower(char(loc.norm));
if isfield(loc,'depthWeight')
    assert(isScalarReal(loc.depthWeight) && loc.depthWeight>=0 && loc.depthWeight<=1, ...
        'ASCT:M2:InvalidDepthWeight','loc.depthWeight must be a finite value in [0,1]');
elseif strict
    loc.depthWeight=0.5; % sc_initAnalysis default
end
if isfield(loc,'noiseLev')
    assert(isScalarReal(loc.noiseLev) && loc.noiseLev>0, ...
        'ASCT:M2:InvalidNoiseLevel','loc.noiseLev must be a positive finite scalar');
elseif strict
    error('ASCT:M2:MissingNoiseLevel', ...
        'STEP8 requires loc.noiseLev even for lambda mode (MNE noisecov)');
end
if isfield(loc,'lambda')
    assert(isScalarReal(loc.lambda) && loc.lambda>0, ...
        'ASCT:M2:InvalidLambda','loc.lambda must be a positive finite scalar');
end
if strcmp(loc.norm,'lambda')
    assert(isfield(loc,'lambda') && isScalarReal(loc.lambda) && loc.lambda>0, ...
        'ASCT:M2:MissingLambda','loc.norm=lambda requires loc.lambda>0');
elseif isfield(changed,'lambda')
    % Reject an inert *change*, not a repeated baseline factor level.
    % Without baseline provenance, reject conservatively (legacy behavior).
    if ~isfield(baseline,'lambda') || ~isequaln(loc.lambda,baseline.lambda)
        error('ASCT:M2:InertFactor', ...
            'loc.lambda has no effect when loc.norm=cov. Filter this combination with includeFcn.');
    end
end
if isfield(loc,'force_lf')
    assert(isScalarReal(loc.force_lf) || (islogical(loc.force_lf) && isscalar(loc.force_lf)), ...
        'ASCT:M2:InvalidForceLeadfield','loc.force_lf must be scalar logical/numeric');
end
end

function tf=isScalarReal(x)
tf=isnumeric(x) && isscalar(x) && isreal(x) && isfinite(x);
end

function tf=isText(x)
tf=(ischar(x) && isrow(x) && ~isempty(x)) || ...
    (isstring(x) && isscalar(x) && ~ismissing(x) && strlength(x)>0);
end
