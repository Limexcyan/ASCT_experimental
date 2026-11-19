function audit=asct_m10_audit(snapshotFile,opts)
%ASCT_M10_AUDIT Physical SHA-256 integrity plus optional MAT metadata QC.
% No loading of EEG arrays; no scientific inference; no M5 donor promotion.
% opts.roots: artifactId/root mappings (as in asct_m10_verify).
% opts.rules: artifactId, relativePath, variable, dimensions (NaN = any size).
if nargin<2,opts=struct();end
if ~isfield(opts,'inspectMat'),opts.inspectMat=true;end
if ~isfield(opts,'roots'),opts.roots=struct('artifactId',{},'root',{});end
if ~isfield(opts,'rules')
    opts.rules=struct('artifactId',{},'relativePath',{},'variable',{},'dimensions',{});
end
assert(islogical(opts.inspectMat) && isscalar(opts.inspectMat), ...
    'ASCT:M10:BadAudit','inspectMat must be a scalar logical');
assert(isstruct(opts.rules) && all(isfield(opts.rules, ...
    {'artifactId','relativePath','variable','dimensions'})), ...
    'ASCT:M10:BadAudit','Invalid QC rules');
verify=asct_m10_verify(snapshotFile,struct('roots',opts.roots));
s=load(snapshotFile,'manifest');m=s.manifest;
ids=cellstr(string({m.artifacts.id}));
for q=1:numel(opts.rules)
    r=opts.rules(q); dim=r.dimensions;
    idx=find(strcmp(ids,char(string(r.artifactId))),1);
    if ~isempty(idx)
        registered=cellstr(string({m.artifacts(idx).files.relativePath}));
        assert(ismember(char(string(r.relativePath)),registered), ...
            'ASCT:M10:BadAudit','Rule targets a file absent from the snapshot');
        [~,~,e]=fileparts(char(string(r.relativePath)));
        assert(strcmpi(e,'.mat'),'ASCT:M10:BadAudit', ...
            'Variable rules must target MAT files');
    end
    assert(ismember(char(string(r.artifactId)),ids) && ...
        isnumeric(dim) && isvector(dim) && ~isempty(dim) && ...
        all(isnan(dim) | (isfinite(dim) & dim>=1 & dim==fix(dim))), ...
        'ASCT:M10:BadAudit','Invalid rule artifact/dimensions');
end
checks=struct('artifactId',{},'relativePath',{},'variable',{},'status',{},'detail',{});
rootIds=cellstr(string({opts.roots.artifactId}));
ruleIds=cellstr(string({opts.rules.artifactId}));
rulePaths=cellstr(string({opts.rules.relativePath}));
for k=1:numel(m.artifacts)
    a=m.artifacts(k);root=char(string(a.sourceRoot));
    ri=find(strcmp(rootIds,a.id),1);
    if ~isempty(ri),root=char(string(opts.roots(ri).root));end
    for j=1:numel(a.files)
        f=a.files(j); rel=char(string(f.relativePath));
        ix=find(strcmp({verify.files.artifactId},a.id) & ...
            strcmp({verify.files.relativePath},rel));
        assert(numel(ix)==1,'ASCT:M10:BadSnapshot','Ambiguous artifact file');
        if ~strcmp(verify.files(ix).status,'ok')
            checks(end+1)=item(a.id,rel,'','blocked',verify.files(ix).status); %#ok<AGROW>
            continue
        end
        [~,~,ext]=fileparts(rel);
        if ~opts.inspectMat || ~strcmpi(ext,'.mat')
            checks(end+1)=item(a.id,rel,'','not_inspected', ...
                'Not a MAT file or inspection disabled'); %#ok<AGROW>
            continue
        end
        try
            variables=whos('-file',fullfile(root,rel));
        catch ex
            checks(end+1)=item(a.id,rel,'','invalid_mat',ex.identifier); %#ok<AGROW>
            continue
        end
        relevant=find(strcmp(ruleIds,a.id) & strcmp(rulePaths,rel));
        if isempty(relevant)
            checks(end+1)=item(a.id,rel,'','metadata_ok', ...
                sprintf('%d variables',numel(variables))); %#ok<AGROW>
        end
        for t=relevant(:)'
            r=opts.rules(t);name=char(string(r.variable));
            v=find(strcmp({variables.name},name));
            if numel(v)~=1
                checks(end+1)=item(a.id,rel,name,'missing_variable', ...
                    'Variable not found'); %#ok<AGROW>
                continue
            end
            observed=double(variables(v).size);
            expected=double(r.dimensions);
            if numel(observed)==numel(expected) && ...
                    all(isnan(expected) | observed==expected)
                status='metadata_ok';
            else
                status='dimension_mismatch';
            end
            checks(end+1)=item(a.id,rel,name,status,mat2str(observed)); %#ok<AGROW>
        end
    end
end
bad=ismember({checks.status},{'blocked','invalid_mat', ...
    'missing_variable','dimension_mismatch'});
audit=struct('schemaVersion',1,'scope','integrity_and_mat_metadata', ...
    'experimentId',m.experimentId,'snapshotDigest',m.snapshotDigest, ...
    'integrity',verify,'checks',checks,'metadataPassed',~any(bad), ...
    'ok',verify.ok && ~any(bad),'scientificValidity','not_assessed', ...
    'reuseAuthorized',false);
end
function x=item(a,p,v,st,detail)
x=struct('artifactId',a,'relativePath',p,'variable',v, ...
    'status',st,'detail',detail);
end
