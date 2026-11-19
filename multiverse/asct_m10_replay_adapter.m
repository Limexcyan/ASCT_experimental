function runner = asct_m10_replay_adapter(baseSetup, cfg, executeFcn)
%ASCT_M10_REPLAY_ADAPTER Stage-aware, copy-isolated M5 runner for ASCT.
% runner = asct_m10_replay_adapter(baseSetup, cfg, executeFcn)
% Used as the callback to asct_m5_run (never called during M5 dry run).
% executeFcn is an EXPLICIT function handle: @(p)asct_multiverse_execute(p,[],[])
% for a native trial, or a mock for isolated tests. There is no implicit run.
% Inputs are copied from M5-verified donor checksums into the new variant.
% STEP9 requires BOTH ICA2 and ICLOC in the single verified donor; otherwise
% it fails closed. M10 historical snapshots are NOT M5 reuse authorization.
assert(isstruct(baseSetup) && isscalar(baseSetup) && ...
    all(isfield(baseSetup,{'rc','chan','filter','seg','ar','ica','loc','con','design'})), ...
    'ASCT:M10:BadSetup','Expected complete ASCT setup struct');
assert(isstruct(cfg) && isscalar(cfg) && ...
    all(isfield(cfg,{'dataset','subjects','conditions','expectedMainFiles'})), ...
    'ASCT:M10:BadConfig','Provide dataset, subjects, conditions, expectedMainFiles');
assert(isa(executeFcn,'function_handle'), ...
    'ASCT:M10:MissingExecutor','Explicit executor callback is required');
assert(isscalar(cfg.expectedMainFiles) && isnumeric(cfg.expectedMainFiles) && ...
    isfinite(cfg.expectedMainFiles) && cfg.expectedMainFiles>=1 && ...
    cfg.expectedMainFiles==fix(cfg.expectedMainFiles), ...
    'ASCT:M10:BadConfig','expectedMainFiles must be positive integer');
for s={'dataset','subjects','conditions'}
    assert(~isempty(cfg.(s{1})), 'ASCT:M10:BadConfig', ...
        'Missing required donor identity: %s',s{1});
end
runner=@(item,donor,variantDir) runOne(item,donor,variantDir,baseSetup,cfg,executeFcn);
end

function produced=runOne(item,donor,variantDir,base,cfg,executeFcn)
assert(isstruct(item) && isscalar(item) && ...
    all(isfield(item,{'id','startStep','stopStep','spec'})), ...
    'ASCT:M10:BadPlan','Expected M5 plan entry');
assert(ismember(item.startStep,[8 9 10]) && ...
    ismember(item.stopStep,[8 9 10]) && item.startStep<=item.stopStep, ...
    'ASCT:M10:UnsupportedRange', ...
    'M10.3 supports source stages STEP8..STEP10 only');
assert(isfolder(variantDir),'ASCT:M10:MissingSandbox', ...
    'M5 must create the variant directory before execution');
assert(isstruct(donor) && isscalar(donor) && ...
    all(isfield(donor,{'root','artifact'})) && ...
    isstruct(donor.artifact) && isscalar(donor.artifact), ...
    'ASCT:M10:MissingDonor','An M5-verified donor is required');
stages={'ICA2','ICLOC','ROI'};
expectedStage=stages{item.startStep-7};
assert(strcmp(char(string(donor.artifact.stage)),expectedStage), ...
    'ASCT:M10:DonorStage','Donor stage does not match the replay input');
assert(isfield(donor.artifact,'compatibility') && ...
    isfield(donor.artifact,'checksums') && ...
    all(isfield(donor.artifact.compatibility,{'dataset','subjects','conditions'})), ...
    'ASCT:M10:DonorMetadata','Incomplete M5 donor metadata');
for s={'dataset','subjects','conditions'}
    assert(isequaln(donor.artifact.compatibility.(s{1}),cfg.(s{1})), ...
        'ASCT:M10:DonorIdentity','Donor %s differs from requested source',s{1});
end
% Defense in depth. M5_find and M5_run verify the source too.
asct_m5_registry('verify',donor.root,donor.artifact);

p=applyChanges(base,item.spec,item.startStep);
p.rc.expFolder=variantDir;
p.rc.analysisName='output';
p.rc.analysisFolder=fullfile(variantDir,'output');
p.rc.load=item.startStep;
p.rc.stop=item.stopStep;
p.rc.sim=[];
p.rc.simStats=0;
p.rc.multiverseIsolatedLeadfield=1;
% Prevent stale source-name fields from a historical setup taking precedence.
for f={'ica2Name','iclocName','sigroiName','prevFolder','usePrevFolder'}
    if isfield(p.rc,f{1}),p.rc=rmfield(p.rc,f{1});end
end
if isfield(cfg,'fieldtripPath') && ~isempty(cfg.fieldtripPath)
    p.fieldtripPath=cfg.fieldtripPath;
end

inputRoot=fullfile(variantDir,'input_donor');
materializeInput(donor.artifact.checksums,inputRoot,item.startStep);
switch item.startStep
    case 8
        p.rc.ica2Name='input_donor';
    case 9
        p.rc.ica2Name='input_donor';
        p.rc.iclocName='input_donor';
    case 10
        p.rc.sigroiName='input_donor';
end
% No stage is executed until the sandbox contains its entire prerequisite
% set; the native executor sees only the staged source through rc.*Name.
executeFcn(p);
main=mainOutputs(p,item.stopStep);
assert(numel(main)==cfg.expectedMainFiles, ...
    'ASCT:M10:OutputCoverage', ...
    'STEP%d produced %d expected primary files; required %d', ...
    item.stopStep,numel(main),cfg.expectedMainFiles);
if isfield(cfg,'expectedMainPaths') && ~isempty(cfg.expectedMainPaths)
    expected=sort(cellstr(string(cfg.expectedMainPaths)));
    observed=cell(1,numel(main));
    prefix=[p.rc.analysisFolder filesep];
    for j=1:numel(main)
        assert(startsWith(main{j},prefix),'ASCT:M10:OutputCoverage', ...
            'Stage output is outside sandbox');
        observed{j}=main{j}(numel(prefix)+1:end);
    end
    assert(isequal(sort(expected(:)),sort(observed(:))), ...
        'ASCT:M10:OutputCoverage', ...
        'Output names differ from expected variant coverage');
end
allFiles=collectOutputFiles(p,item.stopStep);
assert(~isempty(allFiles), 'ASCT:M10:NoOutput','Stage produced no registered files');

upstream=char(string(donor.artifact.artifactId));
settings=struct('rcLoad',item.startStep,'rcStop',item.stopStep, ...
    'chan',p.chan,'filter',p.filter,'seg',p.seg,'ar',p.ar, ...
    'ica',p.ica,'loc',p.loc,'con',p.con,'design',p.design);
compat=struct();
compat.dataset=cfg.dataset;
compat.subjects=cfg.subjects;
compat.conditions=cfg.conditions;
compat.stageSettings=settings;
compat.upstream={upstream};
outputs={'ICLOC','ROI','CONN'};
produced=struct('stage',outputs{item.stopStep-7}, ...
    'executedStartStep',item.startStep,'executedStopStep',item.stopStep, ...
    'files',{allFiles},'compatibility',compat, ...
    'usedDonorArtifactId',upstream);
end

function p=applyChanges(base,spec,startStep)
p=base;
assert(isstruct(spec)&&isscalar(spec),'ASCT:M10:BadPlan','Bad variant spec');
if ~isfield(spec,'changes') || isempty(spec.changes),return;end
changes=spec.changes;
assert(isstruct(changes)&&isscalar(changes),'ASCT:M10:BadChanges', ...
    'Changes must be a scalar struct');
allowed={'loc','con'};
if startStep==10,allowed={'con'};end
groups=fieldnames(changes);
assert(all(ismember(groups,allowed)),'ASCT:M10:UnsafeOverride', ...
    'Variants may not override rc, paths or execution identity');
for k=1:numel(groups)
    g=groups{k};
    assert(isstruct(changes.(g)) && isscalar(changes.(g)), ...
        'ASCT:M10:BadChanges','Each change group must be a struct');
    names=fieldnames(changes.(g));
    if startStep==10 && strcmp(g,'con')
        % STEP10 must not alter upstream ROI reconstruction parameters.
        unsafe={'decimate','removeERP','sensorLevel'};
        assert(~any(ismember(names,unsafe)), ...
            'ASCT:M10:UpstreamChange','STEP10 changes upstream ROI settings');
    end
    if startStep==9 && strcmp(g,'loc')
        assert(all(ismember(names,{'ROI'})), ...
            'ASCT:M10:UpstreamChange','STEP9 cannot change IC localization');
    end
    for j=1:numel(names)
        p.(g).(names{j})=changes.(g).(names{j});
    end
end
end

function materializeInput(checksums,inputRoot,startStep)
assert(isstruct(checksums) && ~isempty(checksums) && ...
    all(isfield(checksums,{'path','sha256'})), ...
    'ASCT:M10:DonorFiles','Donor has no verified files');
paths=cell(1,numel(checksums));
for j=1:numel(checksums)
    source=char(string(checksums(j).path));
    parts=regexp(source,'[/\\]','split');
    assert(~any(ismember(parts,{'.','..'})), ...
        'ASCT:M10:DonorFiles','Unsafe donor path with parent traversal');
    idx=find(strcmp(parts,'6_ICA2') | strcmp(parts,'7_SOURCEACT'),1,'last');
    assert(~isempty(idx),'ASCT:M10:DonorFiles', ...
        'Donor file is outside recognized ASCT stage directories: %s',source);
    relative=fullfile(parts{idx:end});
    paths{j}=relative;
end
assert(numel(unique(paths))==numel(paths),'ASCT:M10:DonorFiles', ...
    'Two donor files map to the same sandbox path');
hasICA=false;hasICLOC=false;hasROI=false;
for j=1:numel(paths)
    rel=paths{j}; [~,name,ext]=fileparts(rel);
    parts=regexp(rel,'[/\\]','split');
    hasICA=hasICA || (strcmp(parts{1},'6_ICA2') && ...
        endsWith([name ext],'_ica2.mat'));
    hasICLOC=hasICLOC || (numel(parts)>2 && ...
        strcmp(parts{1},'7_SOURCEACT') && strcmp(parts{2},'icloc') && ...
        endsWith([name ext],'icloc.mat'));
    hasROI=hasROI || (numel(parts)>=4 && ...
        strcmp(parts{1},'7_SOURCEACT') && startsWith(parts{2},'DC') && ...
        ismember(parts{3},{'lc','unc'}) && ...
        (endsWith([name ext],'sigroi_lc.mat') || ...
         endsWith([name ext],'sigroi_unc.mat')));
end
switch startStep
    case 8, good=hasICA;
    case 9, good=hasICA && hasICLOC;
    case 10,good=hasROI;
end
assert(good,'ASCT:M10:IncompleteDonor', ...
    'STEP%d donor lacks necessary stage input; STEP9 needs ICA2 AND ICLOC',startStep);
% Only make copies after a full dry structural check of donor file names.
for j=1:numel(paths)
    dest=fullfile(inputRoot,paths{j});
    folder=fileparts(dest);
    if ~isfolder(folder),mkdir(folder);end
    [ok,msg]=copyfile(checksums(j).path,dest,'f');
    assert(ok,'ASCT:M10:CopyFailed','Donor copy failed: %s',msg);
    assert(strcmp(asct_m5_digest(dest),checksums(j).sha256), ...
        'ASCT:M10:CopyMismatch','Staged donor differs from M5 checksum');
end
end

function files=mainOutputs(p,stopStep)
switch stopStep
    case 8
        top=fullfile(p.rc.analysisFolder,'7_SOURCEACT');
        predicate=@(x)endsWith(x,'icloc.mat');
    case 9
        top=fullfile(p.rc.analysisFolder,'7_SOURCEACT');
        predicate=@(x)endsWith(x,'sigroi_lc.mat') || endsWith(x,'sigroi_unc.mat');
    case 10
        top=fullfile(p.rc.analysisFolder,'8_CONN');
        predicate=@(x)endsWith(x,'_mltout.mat');
end
files={};
if ~isfolder(top),return;end
d=dir(fullfile(top,'**','*.mat'));
for j=1:numel(d)
    if ~d(j).isdir && d(j).bytes>0 && predicate(d(j).name)
        files{end+1}=fullfile(d(j).folder,d(j).name); %#ok<AGROW>
    end
end
files=sort(unique(files));
end
function files=collectOutputFiles(p,stopStep)
switch stopStep
    case {8,9}, top=fullfile(p.rc.analysisFolder,'7_SOURCEACT');
    case 10,top=fullfile(p.rc.analysisFolder,'8_CONN');
end
files={};
if ~isfolder(top),return;end
d=dir(fullfile(top,'**','*'));
for j=1:numel(d)
    if ~d(j).isdir && d(j).bytes>0
        files{end+1}=fullfile(d(j).folder,d(j).name); %#ok<AGROW>
    end
end
files=sort(unique(files));
end
