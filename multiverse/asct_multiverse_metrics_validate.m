function plugins = asct_multiverse_metrics_validate(plugins)
%ASCT_MULTIVERSE_METRICS_VALIDATE Validate opt-in read-only metric plugins.
% Each plugin is struct('name','my_metric','fn',@my_metric_function).
% Callback signature: values=fn(runsetup,spec,context).
assert(isstruct(plugins) && all(isfield(plugins,{'name','fn'})), ...
    'ASCT:Metrics:InvalidPlugin', ...
    'Plugins must be a struct array with name and fn fields');
names=cell(1,numel(plugins));
for k=1:numel(plugins)
    name=plugins(k).name;
    assert((ischar(name) && isrow(name)) || (isstring(name) && isscalar(name)), ...
        'ASCT:Metrics:InvalidName','Plugin names must be scalar text');
    name=char(name);
    assert(~isempty(regexp(name,'^[A-Za-z][A-Za-z0-9_]*$','once')), ...
        'ASCT:Metrics:InvalidName','Invalid metric name: %s',name);
    assert(isa(plugins(k).fn,'function_handle'), ...
        'ASCT:Metrics:InvalidPlugin','Metric %s needs a function handle',name);
    names{k}=lower(name);
end
assert(numel(unique(names))==numel(names), ...
    'ASCT:Metrics:DuplicateName','Metric names must be unique (case-insensitive)');
end
