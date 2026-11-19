% M10 read-only acceptance, no output writes and no EEG rerun.
% Set ASCT_M10_SNAPSHOT in the environment to an existing snapshot.mat.
repo=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo,'multiverse'));
f=getenv('ASCT_M10_SNAPSHOT');
assert(~isempty(f) && isfile(f),'ASCT:M10:NoSnapshot', ...
    'Set ASCT_M10_SNAPSHOT to the manifest MAT');
checks=asct_m10_audit(f);
dag=asct_m10_provenance(f);
fprintf('M10 integrity: %d; MAT metadata: %d; artifacts: %d; edges: %d\n', ...
    checks.integrity.ok,checks.metadataPassed,numel(dag.nodes),numel(dag.edges));
fprintf('Scientific validity: %s; M5 reuse authorized: %d\n', ...
    checks.scientificValidity,checks.reuseAuthorized);
assert(checks.ok,'ASCT:M10:AcceptanceFailed','Integrity or metadata failed');
