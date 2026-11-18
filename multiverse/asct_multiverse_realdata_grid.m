function specs = asct_multiverse_realdata_grid(mv)
%ASCT_MULTIVERSE_REALDATA_GRID Exhaustive, deterministic setup factor grid.
% Factor names follow the ordinary ExSetup structs: filter, loc, con.
% Numeric vectors enumerate choices; cells enumerate text/heterogeneous choices.
% No random sampling: an excessive number of combinations is an error.
assert(isstruct(mv) && isfield(mv,'factors') && isstruct(mv.factors), ...
    'ASCT:RealMultiverse:Factors','Provide multiverse.factors.<group>.<field>');
assert(isfield(mv,'maxRuns') && isnumeric(mv.maxRuns) && isscalar(mv.maxRuns) && ...
    isfinite(mv.maxRuns) && mv.maxRuns>=1 && fix(mv.maxRuns)==mv.maxRuns, ...
    'ASCT:RealMultiverse:Limit','maxRuns must be a positive integer');
allowed.filter = {'HPfreq','LPfreq','resampleTo','HPord','LPord','bandHz'};
allowed.loc = {'norm','lambda','noiseLev','depthWeight','method'};
allowed.con = {'mvarOrd','orderSelection','maxMvarOrder','chanSel','varNorm', ...
    'removeERP','lc','unc','useRange','timeRangeStart','timeRangeEnd','decimate'};
% bandHz is a declarative shorthand for a *paired* high/low pass band.
% Avoid crossing independent HPfreq and LPfreq choices accidentally.
if isfield(mv.factors,'filter') && isfield(mv.factors.filter,'bandHz')
    assert(~isfield(mv.factors.filter,'HPfreq') && ...
        ~isfield(mv.factors.filter,'LPfreq'), ...
        'ASCT:STEP0:ConflictingBands', ...
        'Use filter.bandHz OR filter.HPfreq/LPfreq, not both');
end
fields = struct('group',{},'name',{},'choices',{});
groups=fieldnames(mv.factors);
for gi=1:numel(groups)
    group=groups{gi};
    assert(isfield(allowed,group), 'ASCT:RealMultiverse:UnsupportedFactor', ...
        'Unsupported factor group: %s',group);
    names=fieldnames(mv.factors.(group));
    for ni=1:numel(names)
        name=names{ni};
        assert(ismember(name,allowed.(group)), 'ASCT:RealMultiverse:UnsupportedFactor', ...
            'Unsupported factor: %s.%s',group,name);
        v=mv.factors.(group).(name);
        if strcmp(group,'filter') && strcmp(name,'bandHz') && ...
                isnumeric(v) && isequal(size(v),[1 2])
            choices={v};
        elseif iscell(v)
            choices=v(:)';
        elseif isstring(v)
            choices=cellstr(v(:))';
        elseif isnumeric(v) || islogical(v)
            assert(isvector(v) && all(isfinite(double(v))), ...
                'ASCT:RealMultiverse:InvalidFactor', 'Invalid numeric factor %s.%s',group,name);
            choices=num2cell(v(:)');
        elseif ischar(v)
            choices={v};
        else
            error('ASCT:RealMultiverse:InvalidFactor', ...
                'Factor %s.%s must be numeric, logical, text, or a cell array',group,name);
        end
        assert(~isempty(choices), 'ASCT:RealMultiverse:InvalidFactor', ...
            'Empty factor %s.%s',group,name);
        if strcmp(group,'filter') && strcmp(name,'bandHz')
            assert(all(cellfun(@(x) isnumeric(x) && isreal(x) && ...
                isequal(size(x),[1 2]) && all(isfinite(x)) && ...
                x(1)>0 && x(2)>x(1), choices)), ...
                'ASCT:STEP0:InvalidBand', ...
                'Each filter.bandHz choice must be [highpass lowpass] with 0<highpass<lowpass');
        else
            assert(all(cellfun(@(x) (ischar(x) && isrow(x)) || ...
                (isnumeric(x) && isscalar(x) && isfinite(x)) || ...
                (islogical(x) && isscalar(x)) || (isstring(x) && isscalar(x)), choices)), ...
                'ASCT:RealMultiverse:InvalidFactor','Invalid choice in %s.%s',group,name);
        end
        fields(end+1)=struct('group',group,'name',name,'choices',{choices}); %#ok<AGROW>
    end
end
assert(~isempty(fields), 'ASCT:RealMultiverse:Factors','Specify at least one factor');
counts=arrayfun(@(f)numel(f.choices), fields);
nSpecs=prod(double(counts));
% The optional includeFcn prunes invalid combinations after expansion.
% Cap pre-pruning expansion to prevent accidental memory blowups.
if isfield(mv,'includeFcn') && ~isempty(mv.includeFcn)
    assert(isa(mv.includeFcn,'function_handle'), ...
        'ASCT:RealMultiverse:InvalidFilter','includeFcn must be a function handle');
    assert(isfinite(nSpecs) && nSpecs<=100000 && nSpecs<=flintmax, ...
        'ASCT:RealMultiverse:TooManyRuns','Grid too large to filter safely');
else
    assert(isfinite(nSpecs) && nSpecs<=mv.maxRuns && nSpecs<=flintmax, ...
        'ASCT:RealMultiverse:TooManyRuns', ...
        'Requested %.0f configurations, exceeding maxRuns=%d. Reduce the grid or raise the limit.', ...
        nSpecs,mv.maxRuns);
end
[startStep,~]=asct_multiverse_dependencies(mv.factors);
specs=repmat(struct('id','','startStep',startStep,'changes',struct()),nSpecs,1);
for idx=1:nSpecs
    changes=struct();
    for j=1:numel(fields)
        previous=prod(double(counts(1:j-1)));
        choice=mod(floor((idx-1)/previous),counts(j))+1;
        group=fields(j).group;
        changes.(group).(fields(j).name)=fields(j).choices{choice};
    end
    if isfield(changes,'filter') && isfield(changes.filter,'bandHz')
        band=changes.filter.bandHz;
        changes.filter=rmfield(changes.filter,'bandHz');
        changes.filter.HPfreq=band(1);
        changes.filter.LPfreq=band(2);
    end
    specs(idx).id=sprintf('mv_%04d',idx);
    specs(idx).changes=changes;
end
if isfield(mv,'includeFcn') && ~isempty(mv.includeFcn)
    keep=false(numel(specs),1);
    for idx=1:numel(specs)
        accepted=mv.includeFcn(specs(idx).changes);
        assert(islogical(accepted) && isscalar(accepted), ...
            'ASCT:RealMultiverse:InvalidFilter', ...
            'includeFcn must return a logical scalar');
        keep(idx)=accepted;
    end
    specs=specs(keep);
    assert(~isempty(specs),'ASCT:RealMultiverse:EmptyGrid', ...
        'includeFcn removed all configurations');
    assert(numel(specs)<=mv.maxRuns,'ASCT:RealMultiverse:TooManyRuns', ...
        'Filtered grid still exceeds maxRuns');
end
end
