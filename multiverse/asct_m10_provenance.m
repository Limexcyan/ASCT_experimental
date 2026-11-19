function graph=asct_m10_provenance(snapshotFile)
%ASCT_M10_PROVENANCE Read-only artifact DAG derived from validated manifest.
% Graph is descriptive only; neither approval for M5 reuse nor scientific QC.
assert(isfile(snapshotFile),'ASCT:M10:MissingSnapshot','Missing snapshot');
s=load(snapshotFile,'manifest');
assert(isfield(s,'manifest') && isstruct(s.manifest) && isscalar(s.manifest), ...
    'ASCT:M10:BadSnapshot','Malformed snapshot');
m=s.manifest;
assert(isfield(m,'schemaVersion') && isequal(m.schemaVersion,1) && ...
    isfield(m,'snapshotDigest') && isfield(m,'artifacts'), ...
    'ASCT:M10:BadSnapshot','Unknown snapshot schema');
assert(strcmp(m.snapshotDigest,asct_m5_digest(rmfield(m,'snapshotDigest'))), ...
    'ASCT:M10:SnapshotChanged','Manifest hash mismatch');
a=m.artifacts;ids=cellstr(string({a.id}));
assert(numel(unique(ids))==numel(ids),'ASCT:M10:BadSnapshot','Duplicate IDs');
nodes=struct('id',{},'variantId',{},'stage',{},'files',{});
edges=struct('from',{},'to',{});
for k=1:numel(a)
    nodes(end+1)=struct('id',a(k).id,'variantId',a(k).variantId, ...
        'stage',a(k).stage,'files',numel(a(k).files)); %#ok<AGROW>
    up=cellstr(string(a(k).upstream));
    assert(numel(unique(up))==numel(up) && all(ismember(up,ids(1:k-1))), ...
        'ASCT:M10:BadDependency','Missing or cyclic dependency');
    for j=1:numel(up)
        edges(end+1)=struct('from',up{j},'to',a(k).id); %#ok<AGROW>
    end
end
graph=struct('schemaVersion',1,'snapshotDigest',m.snapshotDigest, ...
    'nodes',nodes,'edges',edges,'topologicalOrder',{ids}, ...
    'isAcyclic',true,'reuseAuthorized',false);
end
