function result = asct_m10_diff(leftFile,rightFile)
%ASCT_M10_DIFF Compare two M10.1 provenance snapshots without accessing EEG.
%   d=asct_m10_diff('/runA/snapshot.mat','/runB/snapshot.mat')
%
%   Compares reported experiment metadata, nested parameters, stage settings,
%   dependencies and file inventories. Order of independent artifacts/files,
%   manifest timestamps and absolute source roots are not semantic changes.
%   Root relocation is reported, not counted as modified data. Equal file
%   sizes WITHOUT SHA-256 on both sides mean 'unverified', never 'unchanged'.
%
%   MANIFEST-ONLY: This function does NOT check current disk contents,
%   approve M5 reuse, establish code provenance, or establish scientific QC.
%   Use asct_m10_verify independently to verify physical artifact bytes.
if nargin~=2
    error('ASCT:M10:BadDiffInput','Provide two snapshot.mat file paths');
end
l=readManifest(leftFile);
r=readManifest(rightFile);
result=struct();
result.schemaVersion=1;
result.scope='manifest_only';
result.leftDigest=l.snapshotDigest;
result.rightDigest=r.snapshotDigest;
result.experimentIdLeft=l.experimentId;
result.experimentIdRight=r.experimentId;
result.experimentChanged=~strcmp(l.experimentId,r.experimentId);
result.codeRevisionLeft=l.codeRevision;
result.codeRevisionRight=r.codeRevision;
result.codeRevisionChanged=~strcmp(l.codeRevision,r.codeRevision);
result.parameterChanges=diffValues(l.parameters,r.parameters,'parameters');
result.artifacts=emptyArtifactDiff();
result.files=emptyFileDiff();

leftIds=cellstr(string({l.artifacts.id}));
rightIds=cellstr(string({r.artifacts.id}));
ids=sort(union(leftIds,rightIds));
for k=1:numel(ids)
    id=ids{k};
    i=find(strcmp(leftIds,id),1);
    j=find(strcmp(rightIds,id),1);
    a=emptyArtifactRow();
    a.id=id;
    if isempty(i)
        a.status='added';
        result.artifacts(end+1)=a; %#ok<AGROW>
        for t=1:numel(r.artifacts(j).files)
            result.files(end+1)=fileRow(id,r.artifacts(j).files(t).relativePath, ... %#ok<AGROW>
                'added',[],r.artifacts(j).files(t));
        end
        continue
    elseif isempty(j)
        a.status='removed';
        result.artifacts(end+1)=a; %#ok<AGROW>
        for t=1:numel(l.artifacts(i).files)
            result.files(end+1)=fileRow(id,l.artifacts(i).files(t).relativePath, ... %#ok<AGROW>
                'removed',l.artifacts(i).files(t),[]);
        end
        continue
    end
    x=l.artifacts(i); y=r.artifacts(j);
    a.variantChanged=~strcmp(x.variantId,y.variantId);
    a.stageChanged=~strcmp(x.stage,y.stage);
    a.rootRelocated=~strcmp(x.sourceRoot,y.sourceRoot);
    a.expectedCountChanged=~isequaln(x.expectedCount,y.expectedCount);
    a.settingsChanges=diffValues(x.settings,y.settings,'settings');
    u=sort(cellstr(string(x.upstream)));
    v=sort(cellstr(string(y.upstream)));
    a.upstreamAdded=setdiff(v,u);
    a.upstreamRemoved=setdiff(u,v);

    fleft=x.files; fright=y.files;
    pleft=cellfun(@normalizePath,{fleft.relativePath},'UniformOutput',false);
    pright=cellfun(@normalizePath,{fright.relativePath},'UniformOutput',false);
    paths=sort(union(pleft,pright));
    fileModified=false;
    fileUnknown=false;
    for t=1:numel(paths)
        p=paths{t};
        ix=find(strcmp(pleft,p),1);
        iy=find(strcmp(pright,p),1);
        if isempty(ix)
            status='added'; row=fileRow(id,p,status,[],fright(iy));
        elseif isempty(iy)
            status='removed'; row=fileRow(id,p,status,fleft(ix),[]);
        else
            lhs=fleft(ix); rhs=fright(iy);
            if lhs.bytes~=rhs.bytes
                status='modified';
            elseif strcmp(l.hashMode,'sha256') && strcmp(r.hashMode,'sha256') && ...
                    ~isempty(lhs.sha256) && ~isempty(rhs.sha256)
                if strcmpi(lhs.sha256,rhs.sha256)
                    status='unchanged';
                else
                    status='modified';
                end
            else
                status='unverified';
            end
            row=fileRow(id,p,status,lhs,rhs);
        end
        fileModified=fileModified || ismember(status,{'added','removed','modified'});
        fileUnknown=fileUnknown || strcmp(status,'unverified');
        result.files(end+1)=row; %#ok<AGROW>
    end
    metadataChanged=a.variantChanged || a.stageChanged || ...
        a.expectedCountChanged || ~isempty(a.settingsChanges) || ...
        ~isempty(a.upstreamAdded) || ~isempty(a.upstreamRemoved);
    if metadataChanged || fileModified
        a.status='modified';
    elseif fileUnknown
        a.status='unverified';
    else
        a.status='unchanged';
    end
    result.artifacts(end+1)=a; %#ok<AGROW>
end

as={result.artifacts.status};
fs={result.files.status};
result.summary=struct( ...
    'artifactsAdded',sum(strcmp(as,'added')), ...
    'artifactsRemoved',sum(strcmp(as,'removed')), ...
    'artifactsModified',sum(strcmp(as,'modified')), ...
    'artifactsUnchanged',sum(strcmp(as,'unchanged')), ...
    'artifactsUnverified',sum(strcmp(as,'unverified')), ...
    'filesAdded',sum(strcmp(fs,'added')), ...
    'filesRemoved',sum(strcmp(fs,'removed')), ...
    'filesModified',sum(strcmp(fs,'modified')), ...
    'filesUnchanged',sum(strcmp(fs,'unchanged')), ...
    'filesUnverified',sum(strcmp(fs,'unverified')));
% This only means the TWO MANIFESTS carry semantically equivalent claims.
result.metadataEquivalent=~result.experimentChanged && ...
    ~result.codeRevisionChanged && isempty(result.parameterChanges) && ...
    all(strcmp(as,'unchanged'));
end

function m=readManifest(filename)
assert((ischar(filename) && isrow(filename)) || ...
    (isstring(filename) && isscalar(filename)), ...
    'ASCT:M10:BadDiffInput','Expected snapshot MAT path');
filename=char(filename);
assert(isfile(filename),'ASCT:M10:MissingSnapshot', ...
    'Snapshot does not exist: %s',filename);
s=load(filename,'manifest');
assert(isfield(s,'manifest') && isstruct(s.manifest) && ...
    isscalar(s.manifest),'ASCT:M10:BadSnapshot', ...
    'Snapshot must contain a scalar manifest');
m=s.manifest;
required={'schemaVersion','experimentId','codeRevision','parameters', ...
    'parametersFingerprint','hashMode','artifacts','snapshotDigest'};
assert(all(isfield(m,required)) && isequal(m.schemaVersion,1) && ...
    isstruct(m.parameters) && isscalar(m.parameters) && ...
    isstruct(m.artifacts) && ~isempty(m.artifacts) && ...
    any(strcmp(m.hashMode,{'sha256','size'})), ...
    'ASCT:M10:BadSnapshot','Unsupported or incomplete M10.1 snapshot');
assert(strcmp(m.snapshotDigest,asct_m5_digest(rmfield(m,'snapshotDigest'))) && ...
    strcmp(m.parametersFingerprint,asct_m5_digest(m.parameters)), ...
    'ASCT:M10:SnapshotChanged','Snapshot digest/parameters mismatch');
requiredArtifact={'id','variantId','stage','sourceRoot','upstream', ...
    'settings','settingsFingerprint','files','expectedCount'};
assert(all(isfield(m.artifacts,requiredArtifact)), ...
    'ASCT:M10:BadSnapshot','Malformed artifacts');
ids=cellstr(string({m.artifacts.id}));
assert(all(~cellfun(@isempty,ids)) && numel(unique(ids))==numel(ids), ...
    'ASCT:M10:BadSnapshot','Empty or duplicate artifact IDs');
for k=1:numel(m.artifacts)
    a=m.artifacts(k);
    assert(isstruct(a.settings) && isscalar(a.settings) && ...
        strcmp(a.settingsFingerprint,asct_m5_digest(a.settings)), ...
        'ASCT:M10:SnapshotChanged','Artifact settings fingerprint mismatch');
    assert(isstruct(a.files) && ~isempty(a.files) && ...
        all(isfield(a.files,{'relativePath','bytes','sha256'})), ...
        'ASCT:M10:BadSnapshot','Malformed file inventory');
    assert(isscalar(a.expectedCount) && ...
        (isnan(a.expectedCount) || ...
        (a.expectedCount>=1 && a.expectedCount==numel(a.files))), ...
        'ASCT:M10:BadSnapshot','Inconsistent expectedCount');
    upstream=cellstr(string(a.upstream));
    assert(numel(unique(upstream))==numel(upstream) && ...
        all(ismember(upstream,ids(1:k-1))) && ...
        ~any(strcmp(upstream,a.id)), ...
        'ASCT:M10:BadSnapshot','Invalid dependencies');
    normalized=cell(1,numel(a.files));
    for j=1:numel(a.files)
        f=a.files(j);
        normalized{j}=normalizePath(f.relativePath);
        assert(~isempty(normalized{j}) && ...
            ~startsWith(normalized{j},'/') && ...
            isempty(regexp(normalized{j}, ...
            '^[A-Za-z]:|(^|/)\.\.(/|$)','once')) && ...
            isscalar(f.bytes) && isfinite(f.bytes) && f.bytes>0, ...
            'ASCT:M10:BadSnapshot','Unsafe path or invalid size');
        if strcmp(m.hashMode,'sha256')
            assert(ischar(f.sha256) && ...
                ~isempty(regexp(f.sha256,'^[0-9a-fA-F]{64}$','once')), ...
                'ASCT:M10:BadSnapshot','Invalid SHA-256 fingerprint');
        end
    end
    assert(numel(unique(normalized))==numel(normalized), ...
        'ASCT:M10:BadSnapshot','Duplicate artifact file path');
end
end

function p=normalizePath(p)
p=strrep(char(string(p)),'\','/');
end

function changes=diffValues(a,b,path)
changes=emptyChanges();
if isstruct(a) && isstruct(b) && ...
        isequal(size(a),size(b))
    if isscalar(a)
        keys=sort(union(fieldnames(a),fieldnames(b)));
        for k=1:numel(keys)
            key=keys{k};
            sub=[path '.' key];
            ina=isfield(a,key); inb=isfield(b,key);
            if ~ina
                changes(end+1)=changeRow(sub,'added',[],b.(key)); %#ok<AGROW>
            elseif ~inb
                changes(end+1)=changeRow(sub,'removed',a.(key),[]); %#ok<AGROW>
            else
                changes=[changes diffValues(a.(key),b.(key),sub)]; %#ok<AGROW>
            end
        end
    else
        for k=1:numel(a)
            changes=[changes diffValues(a(k),b(k),sprintf('%s(%d)',path,k))]; %#ok<AGROW>
        end
    end
elseif iscell(a) && iscell(b) && isequal(size(a),size(b))
    for k=1:numel(a)
        changes=[changes diffValues(a{k},b{k},sprintf('%s{%d}',path,k))]; %#ok<AGROW>
    end
elseif ~equivalentLeaf(a,b)
    changes(end+1)=changeRow(path,'changed',a,b);
end
end

function tf=equivalentLeaf(a,b)
if (ischar(a) || (isstring(a) && isscalar(a))) && ...
        (ischar(b) || (isstring(b) && isscalar(b)))
    tf=strcmp(char(string(a)),char(string(b)));
else
    tf=isequaln(a,b);
end
end

function row=changeRow(path,kind,a,b)
row=struct('path',path,'kind',kind, ...
    'before',preview(a),'after',preview(b));
end
function s=preview(x)
if isempty(x),s='';return,end
try
    s=jsonencode(x);
catch
    s=sprintf('<%s>',class(x));
end
if numel(s)>160, s=[s(1:157) '...'];end
end
function s=emptyChanges()
s=struct('path',{},'kind',{},'before',{},'after',{});
end
function s=emptyArtifactDiff()
s=repmat(emptyArtifactRow(),1,0);
end
function s=emptyArtifactRow()
s=struct('id','','status','','variantChanged',false, ...
    'stageChanged',false,'rootRelocated',false, ...
    'expectedCountChanged',false,'settingsChanges',{emptyChanges()}, ...
    'upstreamAdded',{{}},'upstreamRemoved',{{}});
end
function s=emptyFileDiff()
s=struct('artifactId',{},'relativePath',{},'status',{}, ...
    'bytesLeft',{},'bytesRight',{},'sha256Left',{},'sha256Right',{});
end
function s=fileRow(id,p,status,l,r)
leftBytes=NaN; rightBytes=NaN; leftHash=''; rightHash='';
if ~isempty(l),leftBytes=l.bytes;leftHash=l.sha256;end
if ~isempty(r),rightBytes=r.bytes;rightHash=r.sha256;end
s=struct('artifactId',id,'relativePath',normalizePath(p), ...
    'status',status,'bytesLeft',leftBytes,'bytesRight',rightBytes, ...
    'sha256Left',leftHash,'sha256Right',rightHash);
end
