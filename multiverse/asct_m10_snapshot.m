function manifest = asct_m10_snapshot(spec, destination, opts)
%ASCT_M10_SNAPSHOT Capture an immutable-by-convention inventory of an ASCT run.
%   manifest = asct_m10_snapshot(spec, destination)
%   A snapshot RECORDS existing artifacts; it does not execute any stage,
%   modify source files, change M1 manifests, or approve M5 cross-run reuse.
%
%   spec.experimentId: unique descriptive experiment identifier
%   spec.codeRevision: producer revision as evidenced by the caller (or 'unknown')
%   spec.parameters: JSON-compatible settings struct for the experiment
%   spec.artifacts: ordered struct array with fields:
%       id, variantId, stage, root, patterns, upstream, settings
%     patterns: relative filename or glob within root, wildcard basename only.
%     upstream: artifact IDs already declared earlier in spec.artifacts.
%
%   opts.hashMode: 'sha256' (default) or 'size'. The latter is ONLY an
%   inventory; it can never pass full integrity verification/reuse.
if nargin < 3, opts = struct(); end
assert(isstruct(spec) && isscalar(spec), 'ASCT:M10:BadSpec', ...
    'Expected a scalar experiment specification');
required={'experimentId','codeRevision','parameters','artifacts'};
assert(all(isfield(spec,required)), 'ASCT:M10:BadSpec', ...
    'Missing experimentId, codeRevision, parameters or artifacts');
assert(isstruct(spec.parameters) && isscalar(spec.parameters), ...
    'ASCT:M10:BadSpec','Experiment parameters must be a scalar struct');
assert(isstruct(spec.artifacts) && ~isempty(spec.artifacts), ...
    'ASCT:M10:BadSpec','At least one artifact is required');
assert(all(isfield(spec.artifacts, ...
    {'id','variantId','stage','root','patterns','upstream','settings'})), ...
    'ASCT:M10:BadSpec','Artifact fields are incomplete');
assert(isText(spec.experimentId) && isText(spec.codeRevision), ...
    'ASCT:M10:BadSpec','Experiment ID and revision must be nonempty text');
if ~isfield(opts,'hashMode'), opts.hashMode='sha256'; end
mode=lower(char(string(opts.hashMode)));
assert(ismember(mode,{'sha256','size'}),'ASCT:M10:BadHashMode', ...
    'hashMode must be sha256 or size');
out=char(string(destination));
assert(~isempty(strtrim(out)) && ~isfolder(out) && ~isfile(out), ...
    'ASCT:M10:OutputExists','Destination must not exist');
assert(isempty(regexp(out,'(^|[/\\])\.\.([/\\]|$)','once')), ...
    'ASCT:M10:UnsafeDestination','Parent traversal is not allowed in destination');
if ~isAbsolute(out), out=fullfile(pwd,out); end

ids=cellstr(string({spec.artifacts.id}));
assert(all(~cellfun(@isempty,ids)) && numel(unique(ids))==numel(ids), ...
    'ASCT:M10:DuplicateId','Artifact IDs must be unique and nonempty');
for k=1:numel(spec.artifacts)
    a=spec.artifacts(k);
    assert(isText(a.variantId) && isText(a.stage), ...
        'ASCT:M10:BadSpec','Every artifact requires a variant and stage');
    assert(isstruct(a.settings) && isscalar(a.settings), ...
        'ASCT:M10:BadSpec','Artifact settings must be a scalar struct');
    up=cellstr(string(a.upstream));
    assert(numel(unique(up))==numel(up) && ...
        all(ismember(up,ids(1:k-1))), 'ASCT:M10:BadDependency', ...
        'Upstream IDs must be unique and refer to preceding artifacts');
    src=char(string(a.root));
    assert(isempty(regexp(src,'(^|[/\\])\.\.([/\\]|$)','once')), ...
        'ASCT:M10:BadSpec','Parent traversal is not allowed in source roots');
    assert(isfolder(src), 'ASCT:M10:MissingRoot','Missing artifact root: %s',src);
    if ~isAbsolute(src), src=fullfile(pwd,src); end
    % Reject snapshot outputs inside an input tree (including source root).
    assert(~strcmp(out,src) && ~startsWith(out,[src filesep]), ...
        'ASCT:M10:UnsafeDestination','Destination is inside an artifact source root');
end

emptyFiles=struct('relativePath',{},'bytes',{},'sha256',{});
recordTemplate=struct('id','','variantId','','stage','','sourceRoot','', ...
    'upstream',{{}},'settings',struct(),'settingsFingerprint','', ...
    'files',{emptyFiles},'expectedCount',NaN);
records=repmat(recordTemplate,1,numel(spec.artifacts));
for k=1:numel(spec.artifacts)
    a=spec.artifacts(k);
    src=char(string(a.root));
    if ~isAbsolute(src), src=fullfile(pwd,src); end
    patterns=cellstr(string(a.patterns));
    assert(~isempty(patterns), 'ASCT:M10:BadPattern','Artifact patterns are empty');
    paths={};
    for j=1:numel(patterns)
        pattern=patterns{j};
        validatePattern(pattern);
        [parent,~,~]=fileparts(pattern);
        if isempty(parent), parent=''; end
        matches=dir(fullfile(src,pattern));
        matches=matches(~[matches.isdir]);
        assert(~isempty(matches), 'ASCT:M10:MissingPattern', ...
            'No file matches artifact %s pattern %s',char(string(a.id)),pattern);
        for m=1:numel(matches)
            relative=fullfile(parent,matches(m).name);
            assert(isfile(fullfile(src,relative)), 'ASCT:M10:MissingFile', ...
                'Disappeared during scan: %s',relative);
            paths{end+1}=relative; %#ok<AGROW>
        end
    end
    paths=sort(unique(paths));
    countExpected=NaN;
    if isfield(a,'expectedCount') && ~isempty(a.expectedCount)
        countExpected=double(a.expectedCount);
        assert(isscalar(countExpected) && isfinite(countExpected) && ...
            countExpected>=1 && countExpected==fix(countExpected), ...
            'ASCT:M10:BadSpec','expectedCount must be a positive integer');
        assert(numel(paths)==countExpected,'ASCT:M10:FileCount', ...
            'Artifact %s: expected %d files, found %d', ...
            char(string(a.id)),countExpected,numel(paths));
    end
    checks=repmat(struct('relativePath','','bytes',0,'sha256',''),1,numel(paths));
    for j=1:numel(paths)
        f=fullfile(src,paths{j});
        d=dir(f);
        assert(numel(d)==1 && ~d.isdir && d.bytes>0, ...
            'ASCT:M10:MissingFile','Missing/empty artifact: %s',f);
        digest='';
        if strcmp(mode,'sha256'), digest=asct_m5_digest(f); end
        checks(j)=struct('relativePath',paths{j},'bytes',double(d.bytes), ...
            'sha256',digest);
    end
    records(k)=struct('id',char(string(a.id)), ...
        'variantId',char(string(a.variantId)), ...
        'stage',char(string(a.stage)), 'sourceRoot',src, ...
        'upstream',{cellstr(string(a.upstream))}, ...
        'settings',a.settings, ...
        'settingsFingerprint',asct_m5_digest(a.settings), ...
        'files',{checks},'expectedCount',countExpected);
end
manifest=struct();
manifest.schemaVersion=1;
manifest.experimentId=char(string(spec.experimentId));
manifest.codeRevision=char(string(spec.codeRevision));
manifest.parameters=spec.parameters;
manifest.parametersFingerprint=asct_m5_digest(spec.parameters);
manifest.hashMode=mode;
manifest.createdAtUTC=char(datetime('now','TimeZone','UTC', ...
    'Format',"yyyy-MM-dd'T'HH:mm:ss'Z'"));
manifest.artifacts=records;
manifest.snapshotDigest=asct_m5_digest(manifest);
encoded=jsonencode(manifest,'PrettyPrint',true);

% All source checks pass before any output directory is created.
[ok,msg]=mkdir(out);
assert(ok,'ASCT:M10:WriteFailed','Cannot create snapshot folder: %s',msg);
matFile=fullfile(out,'snapshot.mat');
jsonFile=fullfile(out,'snapshot.json');
save(matFile,'manifest','-v7');
fid=fopen(jsonFile,'w');
assert(fid>0,'ASCT:M10:WriteFailed','Cannot write %s',jsonFile);
bytes=unicode2native(encoded,'UTF-8');
n=fwrite(fid,bytes,'uint8');
fclose(fid);
assert(n==numel(bytes),'ASCT:M10:WriteFailed', ...
    'Incomplete JSON snapshot');
end

function validatePattern(pattern)
assert(~isempty(pattern) && ~isAbsolute(pattern) && ...
    isempty(regexp(pattern,'(^|[/\\])\.\.([/\\]|$)','once')), ...
    'ASCT:M10:BadPattern','Only relative in-root paths are allowed');
[parent,~,~]=fileparts(pattern);
assert(~contains(parent,'*') && ~contains(parent,'?'), ...
    'ASCT:M10:BadPattern','Wildcards are supported only in filenames');
end
function yes=isText(value)
yes=(ischar(value) && isrow(value)) || ...
    (isstring(value) && isscalar(value));
if yes, yes=strlength(strtrim(string(value)))>0; end
end
function yes=isAbsolute(p)
if ispc
    yes=~isempty(regexp(p,'^[A-Za-z]:[/\\]|^[/\\]{2}','once'));
else
    yes=startsWith(p,'/');
end
end
