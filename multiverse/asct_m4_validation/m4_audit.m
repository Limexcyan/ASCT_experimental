function report = m4_audit(experimentRoot, varargin)
% M4_AUDIT: independent, non-destructive STEP0/STEP10 real-data audit.
% Usage: m4_audit('/absolute/path/to/experiment__multiverse', ...
%                 'ExpectedVariants',4,'MinConnFiles',2)
% No ASCT internal functions are required. MATLAB R2020b+ recommended.
p = inputParser;
addRequired(p,'experimentRoot',@(x)ischar(x)||isstring(x));
addParameter(p,'ExpectedVariants',4,@(x)isnumeric(x)&&isscalar(x)&&x>=1);
addParameter(p,'MinConnFiles',2,@(x)isnumeric(x)&&isscalar(x)&&x>=0);
addParameter(p,'RequireSTEP0',true,@islogical);
addParameter(p,'RequireSTEP10',true,@islogical);
parse(p,experimentRoot,varargin{:}); opts=p.Results;
root=char(experimentRoot);
if ~isfolder(root), error('M4:MissingRoot','Experiment root missing: %s',root); end
manifest=fullfile(root,'realdata_manifest.csv');
if ~isfile(manifest), error('M4:MissingManifest','Missing manifest: %s',manifest); end
try
    T=readtable(manifest,'TextType','string','VariableNamingRule','preserve');
catch
    T=readtable(manifest,'TextType','string');
end
if height(T)<opts.ExpectedVariants
    error('M4:IncompleteGrid','Only %d variants; expected at least %d',height(T),opts.ExpectedVariants);
end
names=string(T.Properties.VariableNames);
nameCol=find(ismember(lower(names),["analysisname","analysis_name","analysis","name"]),1);
statusCol=find(ismember(lower(names),["status","state"]),1);
if isempty(nameCol)
    error('M4:Schema','Manifest lacks analysisName/name column; inspect columns before audit');
end
if isempty(statusCol)
    error('M4:Schema','Manifest lacks status column; inspect columns before audit');
end
variantNames=string(T{:,nameCol}); statuses=lower(strtrim(string(T{:,statusCol})));
if any(ismissing(variantNames)|strlength(strtrim(variantNames))==0)
    error('M4:Schema','Empty variant names');
end
if numel(unique(variantNames))~=numel(variantNames)
    error('M4:Duplicate','Duplicate variant names in manifest');
end
% Intentionally strict; do not silently count planned or failed runs.
pass=ismember(statuses,["passed","success","completed","complete","ok"]);
if ~all(pass)
    error('M4:FailedRuns','Not all variants passed: %s',strjoin(variantNames(~pass),', '));
end
% Conventional ASCT layout: experiment directory is sibling to root.
base=fileparts(root); connCount=zeros(height(T),1);
step0Present=false(height(T),1); step10Present=false(height(T),1);
for k=1:height(T)
    analysisDir=fullfile(base,char(variantNames(k)));
    if ~isfolder(analysisDir)
        error('M4:MissingOutput','Missing analysis directory: %s',analysisDir);
    end
    % STEP10 output is stored under 8_CONN in the Flanker logs.
    connDir=fullfile(analysisDir,'8_CONN');
    if isfolder(connDir)
        files=dir(fullfile(connDir,'**','*.mat'));
        connCount(k)=numel(files); step10Present(k)=connCount(k)>=opts.MinConnFiles;
    end
    % STEP0 has several possible pipeline-dependent output folder names.
    % We deliberately do not guess one here: full verification requires
    % explicit STEP0 artifact paths from the repository configuration.
    step0Present(k)=false;
    if opts.RequireSTEP10 && ~step10Present(k)
        error('M4:MissingSTEP10','Variant %s: STEP10 has %d MAT files (min %d)', ...
            variantNames(k),connCount(k),opts.MinConnFiles);
    end
end
% STEP0 validation is recorded as unverified rather than guessed.
if opts.RequireSTEP0
    warning('M4:STEP0NotVerified', ...
        'STEP0 artifact provenance is not verified. Cross-check files/configuration manually.');
end
report=table(variantNames,statuses,connCount,step10Present,step0Present, ...
    'VariableNames',{'variant','status','connMatFiles','step10Verified','step0Verified'});
out=fullfile(root,'m4_audit_summary.csv');
writetable(report,out);
fprintf('M4 audit: %d variants PASS, STEP10 MAT files checked. STEP0 provenance UNVERIFIED.\n',height(T));
fprintf('Report: %s\n',out);
end
