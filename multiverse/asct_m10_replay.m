function [plan,results] = asct_m10_replay(specs,baseSetup,opts,executeFcn)
%ASCT_M10_REPLAY Opt-in M5 planning/checkpoint wrapper with ASCT stage adapter.
% [plan,results]=asct_m10_replay(specs,setup,opts,executeFcn)
% opts.selection: M5 plan options (startStep 8/9/10, stopStep, selection).
% opts.m5: M5 run options with strict inputs, repo revision, dryRun, etc.
% opts.adapter: dataset/subjects/conditions and expectedMainFiles.
% Native execution is possible ONLY with an explicitly supplied executor:
%   @(p)asct_multiverse_execute(p,[],[])
% For dryRun, the explicit executor is still required but never invoked.
assert(isstruct(opts) && isscalar(opts) && ...
    all(isfield(opts,{'selection','m5','adapter'})), ...
    'ASCT:M10:BadOptions','Expected selection, m5 and adapter structs');
assert(isa(executeFcn,'function_handle'), ...
    'ASCT:M10:MissingExecutor','Explicit executor required');
if ~isfield(opts.m5,'dryRun') || ~opts.m5.dryRun
    assert(isfield(opts.m5,'repoRoot') && isfolder(opts.m5.repoRoot), ...
        'ASCT:M10:RepositoryRequired', ...
        'Actual replay requires M5 repoRoot to attest clean revision');
end
plan=asct_m5_plan(specs,opts.selection);
assert(~isempty(plan),'ASCT:M10:EmptyPlan','No variant selected');
for k=1:numel(plan)
    id=char(string(plan(k).id));
    assert(~isempty(regexp(id,'^[A-Za-z0-9][A-Za-z0-9_.-]*$','once')) && ...
        ~ismember(id,{'.','..'}), 'ASCT:M10:UnsafeVariant', ...
        'Variant ID must be a simple directory name (no separators)');
end
assert(all([plan.startStep]>=8), 'ASCT:M10:UnsupportedRange', ...
    'Native stage adapter starts at STEP8 or later');
runner=asct_m10_replay_adapter(baseSetup,opts.adapter,executeFcn);
results=asct_m5_run(plan,opts.m5,runner);
end
