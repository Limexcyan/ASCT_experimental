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
allowed.filter = {'HPfreq','LPfreq','resampleTo'};
allowed.loc = {'norm','lambda','noiseLev','depthWeight','method'};
allowed.con = {'mvarOrd','orderSelection','maxMvarOrder','chanSel','varNorm', ...
    'removeERP','lc','unc','useRange','timeRangeStart','timeRangeEnd','decimate'};
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
        if iscell(v)
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
        assert(all(cellfun(@(x) (ischar(x) && isrow(x)) || ...
            (isnumeric(x) && isscalar(x) && isfinite(x)) || ...
            (islogical(x) && isscalar(x)) || (isstring(x) && isscalar(x)), choices)), ...
            'ASCT:RealMultiverse:InvalidFactor','Invalid choice in %s.%s',group,name);
        fields(end+1)=struct('group',group,'name',name,'choices',{choices}); %#ok<AGROW>
    end
end
assert(~isempty(fields), 'ASCT:RealMultiverse:Factors','Specify at least one factor');
counts=arrayfun(@(f)numel(f.choices), fields);
nSpecs=prod(double(counts));
assert(isfinite(nSpecs) && nSpecs<=mv.maxRuns && nSpecs<=flintmax, ...
    'ASCT:RealMultiverse:TooManyRuns', ...
    'Requested %.0f configurations, exceeding maxRuns=%d. Reduce the grid or raise the limit.', ...
    nSpecs,mv.maxRuns);
if any(strcmp({fields.group},'filter'))
    startStep=0;
elseif any(strcmp({fields.group},'loc'))
    startStep=8;
elseif any(strcmp({fields.group},'con') & strcmp({fields.name},'decimate'))
    startStep=9;
else
    startStep=10;
end
specs=repmat(struct('id','','startStep',startStep,'changes',struct()),nSpecs,1);
for idx=1:nSpecs
    changes=struct();
    for j=1:numel(fields)
        previous=prod(double(counts(1:j-1)));
        choice=mod(floor((idx-1)/previous),counts(j))+1;
        group=fields(j).group;
        changes.(group).(fields(j).name)=fields(j).choices{choice};
    end
    specs(idx).id=sprintf('mv_%04d',idx);
    specs(idx).changes=changes;
end
end
