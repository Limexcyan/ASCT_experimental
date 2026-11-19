function donor = asct_m5_find(roots, request)
% Find an explicitly compatible passed artifact across read-only donor roots.
% Fail closed on missing compatibility, code mismatch, or corruption.
required={'stage','compatibility','gitRevision'};
assert(isstruct(request)&&all(isfield(request,required)), ...
    'ASCT:M5:BadRequest','stage, compatibility, gitRevision are required');
assert(isfield(request.compatibility,'dataset') && ...
    all(isfield(request.compatibility,{'subjects','conditions','stageSettings','upstream'})), ...
    'ASCT:M5:BadRequest','Incomplete compatibility context');
if ~iscell(roots), roots=cellstr(string(roots)); end
fp=asct_m5_digest(request.compatibility);
donor=[];
for k=1:numel(roots)
    entries=asct_m5_registry('read',roots{k});
    for j=1:numel(entries)
        e=entries(j);
        if ~strcmp(string(e.stage),string(request.stage)) || ...
           ~strcmp(string(e.compatibilityFingerprint),string(fp)) || ...
           ~strcmp(string(e.gitRevision),string(request.gitRevision)) || ...
           ~strcmp(string(e.status),'passed') || logical(e.gitDirty)
            continue;
        end
        % A nominally compatible but corrupt donor must not silently fall back.
        asct_m5_registry('verify',roots{k},e);
        donor=struct('root',roots{k},'artifact',e);
        return;
    end
end
error('ASCT:M5:NoCompatibleDonor', ...
    'No verified artifact matches stage, complete context and exact code revision');
end
