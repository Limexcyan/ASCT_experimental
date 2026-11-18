function n = sc_parallelWorkerLimit(rc)
%SC_PARALLELWORKERLIMIT Explicit parfor worker limit for ASCT pipeline.
% A second parfor argument of 0 executes serially and DOES NOT auto-start
% a local process pool.  In particular rc.useParallel=0 must never trigger
% MATLAB's default 32-worker Processes pool.
n=0;
if isfield(rc,'useParallel') && ~isempty(rc.useParallel)
    n=rc.useParallel;
end
assert(isnumeric(n) && isscalar(n) && isreal(n) && isfinite(n) && ...
    n>=0 && n==fix(n), 'ASCT:Parallel:InvalidWorkers', ...
    'rc.useParallel must be a nonnegative integer (0 = serial parfor)');
end
