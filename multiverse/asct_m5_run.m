function results = asct_m5_run(plan, opts, runnerFcn)
% Transactional, opt-in M5 stage execution around an explicit stage runner.
% runnerFcn(entry, donor, variantFolder) must execute ONLY entry.startStep..stopStep
% and return stage, executedStartStep, executedStopStep, files, compatibility.
% This function does NOT run sc_initAnalysis by itself.
assert(isa(runnerFcn,'function_handle'),'ASCT:M5:Runner','A stage-aware runner callback is required');
required={'outputRoot','runId','gitRevision','inputs'};
assert(all(isfield(opts,required)),'ASCT:M5:BadOptions','Missing M5 run options');
if ~isfield(opts,'dryRun'), opts.dryRun=true; end
if ~isfield(opts,'resume'), opts.resume=false; end
if ~isfield(opts,'retryFailed'), opts.retryFailed=false; end
if ~isfield(opts,'donorRoots'), opts.donorRoots={}; end
if ~isfield(opts,'gitDirty'), opts.gitDirty=false; end
if isfield(opts,'repoRoot') && ~isempty(opts.repoRoot)
    actual=asct_m5_git_identity(opts.repoRoot);
    assert(strcmp(string(actual.gitRevision),string(opts.gitRevision)), ...
        'ASCT:M5:CodeChanged','Configured revision does not match current checkout');
    assert(~actual.gitDirty,'ASCT:M5:DirtyCode','Git checkout has uncommitted changes');
end
assert(~opts.gitDirty,'ASCT:M5:DirtyCode','M5 requires a clean, committed producer revision');
assert(~strcmpi(char(string(opts.gitRevision)),'unknown'), ...
    'ASCT:M5:UnknownCode','M5 requires a known revision');
root=char(string(opts.outputRoot));
assert(~isempty(plan) && ~isempty(root),'ASCT:M5:BadOptions','Plan and output root are required');
ids=string({plan.id});
assert(numel(unique(ids))==numel(ids),'ASCT:M5:DuplicateId','Duplicate plan IDs');
results=repmat(struct('id','','status','pending','attempt',0,'error','', ...
    'reusedFrom','','artifactId',''),1,numel(plan));
for k=1:numel(plan), results(k).id=plan(k).id; end
if opts.dryRun
    for k=1:numel(plan)
        fprintf('M5 PLAN %s: STEP%d -> STEP%d\n',plan(k).id,plan(k).startStep,plan(k).stopStep);
    end
    return; % Dry run never creates output directories or registries.
end
checkpoint=fullfile(root,'m5_checkpoint.mat');
identity=struct('plan',plan,'inputs',opts.inputs,'runId',opts.runId, ...
    'gitRevision',opts.gitRevision,'gitDirty',opts.gitDirty);
if opts.resume
    assert(isfile(checkpoint),'ASCT:M5:MissingCheckpoint','Resume requires saved checkpoint');
    prev=load(checkpoint,'identity','results');
    assert(isfield(prev,'identity')&&isequaln(prev.identity,identity), ...
        'ASCT:M5:PlanChanged','Saved plan differs; use a new run ID/outputRoot');
    results=prev.results;
else
    assert(~isfile(checkpoint)&&~isfolder(root), ...
        'ASCT:M5:OutputExists','Output root exists; choose new outputRoot or resume');
    mkdir(root);
    writeCheckpoint(root,identity,results);
end
for k=1:numel(plan)
    item=plan(k);
    if strcmp(results(k).status,'passed'), continue; end
    variantDir=fullfile(root,'variants',item.id);
    if isfolder(variantDir)
        assert(opts.resume&&opts.retryFailed, ...
            'ASCT:M5:IncompleteOutput','Incomplete variant needs explicit retryFailed=true');
        backup=backupName(variantDir);
        [ok,msg]=movefile(variantDir,backup);
        assert(ok,'ASCT:M5:ArchiveFailed','Could not archive %s: %s',variantDir,msg);
    end
    donor=[];
    if item.startStep>0
        stage=inputStage(item.startStep);
        ix=find(strcmp(string({opts.inputs.variantId}),string(item.id)));
        assert(numel(ix)==1,'ASCT:M5:InputRequest','Exactly one input request per selected variant');
        req=struct('stage',stage,'compatibility',opts.inputs(ix).compatibility, ...
            'gitRevision',opts.gitRevision);
        donor=asct_m5_find(opts.donorRoots,req);
    end
    mkdir(variantDir);
    results(k).status='running'; results(k).attempt=results(k).attempt+1;
    writeCheckpoint(root,identity,results);
    try
        produced=runnerFcn(item,donor,variantDir);
        assert(isstruct(produced)&&isscalar(produced)&& ...
            all(isfield(produced,{'stage','executedStartStep','executedStopStep', ...
            'files','compatibility'})), 'ASCT:M5:RunnerContract', ...
            'Runner must report range, artifact type, compatibility and files');
        assert(produced.executedStartStep==item.startStep && ...
            produced.executedStopStep==item.stopStep, ...
            'ASCT:M5:RunnerContract','Runner did not confirm the requested range');
        stage=outputStage(item.stopStep);
        assert(strcmp(string(produced.stage),string(stage)), ...
            'ASCT:M5:RunnerContract','Unexpected artifact type for stopStep');
        assert(isfield(produced.compatibility,'dataset') && ...
            all(isfield(produced.compatibility,{'subjects','conditions','stageSettings','upstream'})), ...
            'ASCT:M5:RunnerContract','Runner must report complete provenance');
        outputPaths=string(produced.files);
        assert(~isempty(outputPaths) && all(startsWith(outputPaths,string([variantDir filesep]))), ...
            'ASCT:M5:RunnerContract','Produced files must reside in this variant directory');
        if ~isempty(donor)
            assert(isfield(produced,'usedDonorArtifactId') && ...
                strcmp(string(produced.usedDonorArtifactId),string(donor.artifact.artifactId)), ...
                'ASCT:M5:RunnerContract','Runner did not confirm the selected donor');
            upstream=string(produced.compatibility.upstream);
            assert(any(upstream==string(donor.artifact.artifactId)), ...
                'ASCT:M5:RunnerContract','Output provenance must include donor artifact ID');
            asct_m5_registry('verify',donor.root,donor.artifact);
        end
        artifactId=[char(string(opts.runId)) '__' item.id '__' stage];
        artifact=struct('artifactId',artifactId,'stage',stage, ...
            'producerRunId',char(string(opts.runId)), ...
            'producerVariantId',item.id, ...
            'gitRevision',char(string(opts.gitRevision)), ...
            'gitDirty',false,'compatibility',produced.compatibility, ...
            'files',{cellstr(string(produced.files))});
        asct_m5_registry('add',root,artifact);
        results(k).status='passed'; results(k).artifactId=artifactId;
        if ~isempty(donor), results(k).reusedFrom=donor.artifact.artifactId; end
        results(k).error='';
    catch ME
        results(k).status='failed';
        results(k).error=sprintf('%s: %s',ME.identifier,ME.message);
        writeCheckpoint(root,identity,results);
        rethrow(ME);
    end
    writeCheckpoint(root,identity,results);
end
end
function s=inputStage(startStep)
switch startStep
    case 8, s='ICA2';
    case 9, s='ICLOC';
    case 10, s='ROI';
    otherwise, error('ASCT:M5:StartStep','Unsupported start step');
end
end
function s=outputStage(stopStep)
switch stopStep
    case 8, s='ICLOC';
    case 9, s='ROI';
    case 10, s='CONN';
    otherwise, error('ASCT:M5:StopStep','Unsupported stop step');
end
end
function writeCheckpoint(root,identity,results)
p=[tempname(root) '.mat'];
cleanup=onCleanup(@() removeTmp(p));
save(p,'identity','results','-v7');
[ok,msg]=movefile(p,fullfile(root,'m5_checkpoint.mat'),'f');
assert(ok,'ASCT:M5:CheckpointFailed','Could not save checkpoint: %s',msg);
end
function s=backupName(folder)
for k=1:999
    s=sprintf('%s.incomplete_backup_%04d',folder,k);
    if ~isfolder(s) && ~isfile(s), return; end
end
error('ASCT:M5:BackupFailed','No available backup suffix');
end
function removeTmp(p)
if isfile(p), delete(p); end
end
