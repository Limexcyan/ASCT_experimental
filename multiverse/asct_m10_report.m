function report=asct_m10_report(snapshotFile,destination,opts)
%ASCT_M10_REPORT Create JSON, Markdown and Graphviz provenance report.
% Audit-only operation. Never updates snapshot, EEG or M5 registry.
if nargin<3,opts=struct();end
out=char(string(destination));
assert(~isempty(strtrim(out)) && ~isfolder(out) && ~isfile(out), ...
    'ASCT:M10:OutputExists','Report destination already exists');
assert(isempty(regexp(out,'(^|[/\\])\.\.([/\\]|$)','once')), ...
    'ASCT:M10:UnsafeDestination','Parent traversal forbidden');
audit=asct_m10_audit(snapshotFile,opts);
graph=asct_m10_provenance(snapshotFile);
s=load(snapshotFile,'manifest');m=s.manifest;
if ~isfield(opts,'roots'),opts.roots=struct('artifactId',{},'root',{});end
rootIds=cellstr(string({opts.roots.artifactId}));
if ~isAbsolute(out),absoluteOut=fullfile(pwd,out);else,absoluteOut=out;end
for k=1:numel(m.artifacts)
    source=char(string(m.artifacts(k).sourceRoot));
    ix=find(strcmp(rootIds,m.artifacts(k).id),1);
    if ~isempty(ix),source=char(string(opts.roots(ix).root));end
    if ~isAbsolute(source),source=fullfile(pwd,source);end
    assert(~strcmp(absoluteOut,source) && ...
        ~startsWith(absoluteOut,[source filesep]), ...
        'ASCT:M10:UnsafeDestination','Report must be outside source trees');
end
report=struct('schemaVersion',1,'experimentId',m.experimentId, ...
    'codeRevision',m.codeRevision,'snapshotDigest',m.snapshotDigest, ...
    'integrityOk',audit.integrity.ok,'metadataOk',audit.metadataPassed, ...
    'overallOk',audit.ok,'scientificValidity','not_assessed', ...
    'reuseAuthorized',false,'artifactCount',numel(graph.nodes), ...
    'fileCount',numel(audit.integrity.files), ...
    'dependencyCount',numel(graph.edges), ...
    'audit',audit,'provenance',graph);
md=sprintf(['# ASCT M10 reproducibility report\n\n', ...
    'Experiment: `%s`  \nProducer revision: `%s`  \nSnapshot digest: `%s`\n\n', ...
    '| Check | Status |\n|---|---|\n', ...
    '| SHA-256 integrity | %s |\n', ...
    '| MAT metadata | %s |\n', ...
    '| Scientific validity | NOT ASSESSED |\n', ...
    '| Authorized for M5 reuse | NO |\n\n', ...
    'Artifacts: %d; files: %d; dependency edges: %d.\n'], ...
    safeText(m.experimentId),safeText(m.codeRevision),m.snapshotDigest, ...
    pass(audit.integrity.ok),pass(audit.metadataPassed), ...
    numel(graph.nodes),numel(audit.integrity.files),numel(graph.edges));
dot=sprintf('digraph ASCT_M10 {\n  rankdir=LR;\n');
for k=1:numel(graph.nodes)
    dot=[dot sprintf('  node%d [label="%s\\n%s"];\n',k, ...
        dotText(graph.nodes(k).id),dotText(graph.nodes(k).stage))]; %#ok<AGROW>
end
ids=cellstr(string({graph.nodes.id}));
for k=1:numel(graph.edges)
    src=find(strcmp(ids,graph.edges(k).from),1);
    dst=find(strcmp(ids,graph.edges(k).to),1);
    dot=[dot sprintf('  node%d -> node%d;\n',src,dst)]; %#ok<AGROW>
end
dot=[dot sprintf('}\n')];
[ok,msg]=mkdir(out);
assert(ok,'ASCT:M10:WriteFailed','Cannot create report folder: %s',msg);
writeText(fullfile(out,'report.json'),jsonencode(report,'PrettyPrint',true));
writeText(fullfile(out,'report.md'),md);
writeText(fullfile(out,'provenance.dot'),dot);
end
function writeText(path,value)
fid=fopen(path,'w');
assert(fid>0,'ASCT:M10:WriteFailed','Cannot open report');
c=onCleanup(@()fclose(fid)); %#ok<NASGU>
bytes=unicode2native(value,'UTF-8');
assert(fwrite(fid,bytes,'uint8')==numel(bytes), ...
    'ASCT:M10:WriteFailed','Incomplete report write');
end
function x=pass(tf)
if tf,x='PASS';else,x='FAIL';end
end
function x=safeText(value)
x=char(string(value));x=regexprep(x,'[\r\n|`]', ' ');
end
function x=dotText(value)
x=char(string(value));
x=strrep(x,'\','\\');
x=strrep(x,'"','\"');
x=regexprep(x,'[\r\n]',' ');
end
function yes=isAbsolute(p)
if ispc
    yes=~isempty(regexp(p,'^[A-Za-z]:[/\\]|^[/\\]{2}','once'));
else
    yes=startsWith(p,'/');
end
end
