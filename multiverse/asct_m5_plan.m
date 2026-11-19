function plan = asct_m5_plan(specs, opts)
% Build an opt-in M5 subset plan without renumbering multiverse variants.
% The runner must separately prove support for the requested stage range.
arguments
    specs (1,:) struct
    opts struct = struct()
end
if ~isfield(opts,'selectedVariantIds') || isempty(opts.selectedVariantIds)
    selected = string({specs.id});
else
    selected = string(opts.selectedVariantIds);
end
ids = string({specs.id});
assert(numel(unique(ids))==numel(ids),'ASCT:M5:DuplicateId','Variant IDs must be unique');
assert(numel(unique(selected))==numel(selected),'ASCT:M5:DuplicateSelection','Selection contains duplicate IDs');
assert(all(ismember(selected,ids)),'ASCT:M5:UnknownVariant','Selected variant is not in the original grid');
if ~isfield(opts,'startStep'), opts.startStep=0; end
if ~isfield(opts,'stopStep'), opts.stopStep=10; end
assert(ismember(opts.startStep,[0 8 9 10]),'ASCT:M5:StartStep','Unsupported start step');
assert(ismember(opts.stopStep,[8 9 10]),'ASCT:M5:StopStep','Unsupported stop step');
assert(opts.startStep<=opts.stopStep,'ASCT:M5:InvalidRange','startStep must be <= stopStep');
plan = repmat(struct('id','','startStep',0,'stopStep',10,'spec',struct()),1,0);
for k=1:numel(specs)
    if ~ismember(string(specs(k).id),selected), continue; end
    p=struct('id',char(string(specs(k).id)), ...
        'startStep',opts.startStep,'stopStep',opts.stopStep,'spec',specs(k));
    plan(end+1)=p; %#ok<AGROW>
end
end
