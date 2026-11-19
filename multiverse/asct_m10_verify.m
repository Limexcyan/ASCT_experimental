function report = asct_m10_verify(snapshotFile, opts)
%ASCT_M10_VERIFY Read-only integrity check of an M10 artifact snapshot.
%   report = asct_m10_verify('/path/snapshot.mat')
%   opts.roots = struct('artifactId',{'roi1'},'root',{'/new/root'})
%   supports checking copied snapshots on another machine or disk.
%   report.ok is true ONLY for complete SHA-256 verified snapshots.
%   A valid hash is NOT proof of scientific validity or stage compatibility.
if nargin<2, opts=struct(); end
if ~isfield(opts,'roots'), opts.roots=struct('artifactId',{},'root',{}); end
assert(isstruct(opts.roots) && ...
    all(isfield(opts.roots,{'artifactId','root'})), ...
    'ASCT:M10:BadRemap','opts.roots must have artifactId/root entries');
assert(isfile(snapshotFile),'ASCT:M10:MissingSnapshot','Snapshot MAT missing');
s=load(snapshotFile,'manifest');
assert(isfield(s,'manifest') && isstruct(s.manifest) && isscalar(s.manifest), ...
    'ASCT:M10:BadSnapshot','Malformed snapshot MAT');
m=s.manifest;
assert(isfield(m,'schemaVersion') && isequal(m.schemaVersion,1) && ...
    all(isfield(m,{'snapshotDigest','parametersFingerprint','parameters', ...
    'artifacts','hashMode'})), ...
    'ASCT:M10:BadSnapshot','Unknown or incomplete snapshot schema');
expected=m.snapshotDigest;
assert(strcmp(expected,asct_m5_digest(rmfield(m,'snapshotDigest'))), ...
    'ASCT:M10:SnapshotChanged','Snapshot manifest content has changed');
assert(strcmp(m.parametersFingerprint,asct_m5_digest(m.parameters)), ...
    'ASCT:M10:SnapshotChanged','Parameter fingerprint has changed');
rebaseIds=cellstr(string({opts.roots.artifactId}));
assert(numel(unique(rebaseIds))==numel(rebaseIds), ...
    'ASCT:M10:BadRemap','Duplicate artifact root override');
assert(all(ismember(rebaseIds,cellstr(string({m.artifacts.id})))), ...
    'ASCT:M10:BadRemap','Override references unknown artifact');
files=struct('artifactId',{},'stage',{},'relativePath',{},'status',{}, ...
    'bytesExpected',{},'bytesActual',{},'sha256Expected',{},'sha256Actual',{});
artifacts=struct('id',{},'stage',{},'variantId',{},'status',{},'fileCount',{});
for k=1:numel(m.artifacts)
    a=m.artifacts(k);
    assert(strcmp(a.settingsFingerprint,asct_m5_digest(a.settings)), ...
        'ASCT:M10:SnapshotChanged','Artifact settings changed');
    assert(isnan(a.expectedCount) || numel(a.files)==a.expectedCount, ...
        'ASCT:M10:BadSnapshot','Unexpected number of recorded files');
    root=a.sourceRoot;
    ix=find(strcmp(rebaseIds,a.id));
    if ~isempty(ix), root=char(string(opts.roots(ix).root)); end
    statuses=cell(1,numel(a.files));
    for j=1:numel(a.files)
        x=a.files(j);
        validateRelative(x.relativePath);
        f=fullfile(root,x.relativePath);
        status='ok';
        actualBytes=NaN;
        actualHash='';
        if ~isfile(f)
            status='missing';
        else
            d=dir(f);
            actualBytes=double(d.bytes);
            if numel(d)~=1 || d.bytes~=x.bytes || d.bytes==0
                status='size_mismatch';
            elseif strcmp(m.hashMode,'sha256')
                actualHash=asct_m5_digest(f);
                if ~strcmp(actualHash,x.sha256),status='hash_mismatch';end
            else
                status='metadata_only';
            end
        end
        statuses{j}=status;
        files(end+1)=struct('artifactId',a.id,'stage',a.stage, ... %#ok<AGROW>
            'relativePath',x.relativePath,'status',status, ...
            'bytesExpected',x.bytes,'bytesActual',actualBytes, ...
            'sha256Expected',x.sha256,'sha256Actual',actualHash);
    end
    if all(strcmp(statuses,'ok'))
        st='verified';
    elseif all(ismember(statuses,{'ok','metadata_only'}))
        st='inventory_only';
    else
        st='failed';
    end
    artifacts(end+1)=struct('id',a.id,'stage',a.stage, ... %#ok<AGROW>
        'variantId',a.variantId,'status',st,'fileCount',numel(a.files));
end
report=struct('experimentId',m.experimentId, ...
    'snapshotDigest',m.snapshotDigest,'hashMode',m.hashMode, ...
    'files',files,'artifacts',artifacts, ...
    'complete',~any(strcmp({artifacts.status},'failed')), ...
    'ok',all(strcmp({artifacts.status},'verified')));
end
function validateRelative(path)
p=char(string(path));
assert(~isempty(p) && ~startsWith(p,'/') && ...
    isempty(regexp(p,'^[A-Za-z]:|(^|[/\\])\.\.([/\\]|$)','once')), ...
    'ASCT:M10:BadSnapshot','Unsafe path in snapshot');
end
