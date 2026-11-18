function results = asct_multiverse_resume(setup,mv,runnerFcn)
%ASCT_MULTIVERSE_RESUME Resume an interrupted real-data multiverse safely.
% Completed variants are skipped. For unfinished folders, set mv.retryFailed
% explicitly to archive the old folder before re-execution (never delete it).
if nargin<3, runnerFcn=[]; end
mv.resume=true;
results=asct_multiverse_realdata(setup,mv,runnerFcn);
end
