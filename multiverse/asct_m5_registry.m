function out = asct_m5_registry(action, root, entry)
% Append-only stage artifact registry with checksum validation.
% action=read|add|verify. Never writes to a donor during matching.
if nargin<3, entry=[]; end
file=fullfile(root,'m5_registry.mat');
switch lower(char(action))
    case 'read'
        out=readEntries(file);
    case 'add'
        assert(isstruct(entry)&&isscalar(entry),'ASCT:M5:BadArtifact','Artifact must be scalar struct');
        required={'artifactId','stage','producerRunId','producerVariantId', ...
            'gitRevision','gitDirty','compatibility','files'};
        assert(all(isfield(entry,required)),'ASCT:M5:BadArtifact','Required artifact fields are missing');
        assert(isstruct(entry.compatibility)&&isscalar(entry.compatibility), ...
            'ASCT:M5:BadArtifact','Compatibility must be a struct');
        assert(all(isfield(entry.compatibility,{'dataset','subjects','conditions', ...
            'stageSettings','upstream'})), 'ASCT:M5:BadArtifact', ...
            'Compatibility must include dataset, subjects, conditions, stageSettings and upstream');
        assert(~isempty(char(string(entry.gitRevision))) && ~strcmpi(string(entry.gitRevision),'unknown'), ...
            'ASCT:M5:UnknownCode','Cannot register an artifact without a known code revision');
        assert(~entry.gitDirty,'ASCT:M5:DirtyCode','Register verified artifacts from a clean checkout');
        paths=cellstr(string(entry.files));
        assert(~isempty(paths),'ASCT:M5:EmptyArtifact','Artifact must contain at least one file');
        checksums=repmat(struct('path','','bytes',0,'sha256',''),1,numel(paths));
        for i=1:numel(paths)
            p=paths{i}; d=dir(p);
            assert(isfile(p)&&numel(d)==1&&d.bytes>0,'ASCT:M5:MissingFile','Missing/empty output file: %s',p);
            checksums(i)=struct('path',p,'bytes',d.bytes,'sha256',asct_m5_digest(p));
        end
        if ~isfolder(root), mkdir(root); end
        out=readEntries(file);
        if ~isempty(out)
            assert(~any(strcmp({out.artifactId},char(string(entry.artifactId)))), ...
                'ASCT:M5:DuplicateArtifact','Artifact ID already registered');
        end
        entry.artifactId=char(string(entry.artifactId));
        entry.stage=char(string(entry.stage));
        entry.producerRunId=char(string(entry.producerRunId));
        entry.producerVariantId=char(string(entry.producerVariantId));
        entry.gitRevision=char(string(entry.gitRevision));
        entry.checksums=checksums;
        entry.compatibilityFingerprint=asct_m5_digest(entry.compatibility);
        entry.completedAt=char(datetime('now','TimeZone','UTC','Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
        entry.status='passed';
        if isempty(out), registry=entry; else, registry=[out entry]; end %#ok<AGROW>
        tmp=[tempname(root) '.mat'];
        cleanup=onCleanup(@() removeTmp(tmp));
        save(tmp,'registry','-v7');
        [ok,msg]=movefile(tmp,file,'f');
        assert(ok,'ASCT:M5:RegistryWrite','Registry replacement failed: %s',msg);
        out=entry;
    case 'verify'
        out=verifyEntry(entry);
    otherwise
        error('ASCT:M5:Action','Unknown registry action');
end
end
function entries=readEntries(file)
if ~isfile(file), entries=struct([]); return; end
r=load(file,'registry');
assert(isfield(r,'registry')&&isstruct(r.registry),'ASCT:M5:RegistryCorrupt','Malformed registry');
entries=r.registry;
end
function valid=verifyEntry(e)
valid=false;
assert(isfield(e,'checksums')&&isfield(e,'compatibility'), ...
    'ASCT:M5:RegistryCorrupt','Missing stored checksums');
assert(strcmp(asct_m5_digest(e.compatibility),e.compatibilityFingerprint), ...
    'ASCT:M5:RegistryCorrupt','Fingerprint does not match stored metadata');
for i=1:numel(e.checksums)
    x=e.checksums(i);
    d=dir(x.path);
    assert(isfile(x.path)&&numel(d)==1&&d.bytes==x.bytes, ...
        'ASCT:M5:CorruptArtifact','File missing or changed: %s',x.path);
    assert(strcmp(asct_m5_digest(x.path),x.sha256), ...
        'ASCT:M5:CorruptArtifact','Checksum mismatch: %s',x.path);
end
valid=true;
end
function removeTmp(p)
if isfile(p), delete(p); end
end
