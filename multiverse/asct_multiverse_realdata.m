function results = asct_multiverse_realdata(setup,mv,runnerFcn)
%ASCT_MULTIVERSE_REALDATA Execute a resumable, dependency-aware ASCT multiverse.
% Compatible with existing STEP10 API. Stage reuse is OPT-IN (cacheStages).
% resume=true reuses verified completed variants; retryFailed=true archives
% unfinished variant directories before retrying. No deletion is performed.
% The execution record is a checkpoint, not a scientific quality verdict.
if nargin<3 || isempty(runnerFcn), runnerFcn=@asct_multiverse_execute; end
assert(isa(runnerFcn,'function_handle'), 'ASCT:RealMultiverse:InvalidRunner', ...
    'runnerFcn must be a function handle');
assert(isstruct(mv) && isfield(mv,'sourceAnalysis'), ...
    'ASCT:RealMultiverse:MissingSource','Specify multiverse.sourceAnalysis');
assert(ischar(mv.sourceAnalysis) || (isstring(mv.sourceAnalysis) && isscalar(mv.sourceAnalysis)), ...
    'ASCT:RealMultiverse:MissingSource','sourceAnalysis must be a folder name');
assert(~isempty(regexp(char(mv.sourceAnalysis),'^[A-Za-z0-9_.-]+$','once')) && ...
    ~ismember(char(mv.sourceAnalysis),{'.','..'}), ...
    'ASCT:RealMultiverse:InvalidSource','sourceAnalysis must be a folder name, not a path');
if ~isfield(mv,'maxRuns'), mv.maxRuns=12; end
if ~isfield(mv,'dryRun'), mv.dryRun=true; end
if ~isfield(mv,'continueOnError'), mv.continueOnError=false; end
if ~isfield(mv,'allowOverwrite'), mv.allowOverwrite=false; end
if ~isfield(mv,'runStatistics'), mv.runStatistics=false; end
if ~isfield(mv,'outputName'), mv.outputName=''; end
if ~isfield(mv,'statistics'), mv.statistics=struct(); end
if ~isfield(mv,'resume'), mv.resume=false; end
if ~isfield(mv,'retryFailed'), mv.retryFailed=false; end
if ~isfield(mv,'cacheStages'), mv.cacheStages=false; end
if ~isfield(mv,'strictArtifacts'), mv.strictArtifacts=false; end
if ~isfield(mv,'strictLocalization'), mv.strictLocalization=false; end
for n={'resume','retryFailed','cacheStages','strictArtifacts','strictLocalization', ...
        'dryRun','allowOverwrite','continueOnError','runStatistics'}
    f=n{1};
    assert(islogical(mv.(f)) && isscalar(mv.(f)), ...
        'ASCT:RealMultiverse:InvalidFlag','%s must be logical scalar',f);
end
assert(~(mv.resume && mv.allowOverwrite), ...
    'ASCT:RealMultiverse:ResumeOverwrite','resume and allowOverwrite cannot both be true');
assert(~(mv.retryFailed && ~mv.resume), ...
    'ASCT:RealMultiverse:RetryRequiresResume','retryFailed requires resume');
assert(isstruct(mv.statistics) && isscalar(mv.statistics), ...
    'ASCT:RealMultiverse:StatisticsOptions','statistics must be a scalar struct');
if isfield(mv,'fieldtripPath')
    assert((ischar(mv.fieldtripPath) || (isstring(mv.fieldtripPath) && isscalar(mv.fieldtripPath))) ...
        && isfolder(char(mv.fieldtripPath)), ...
        'ASCT:RealMultiverse:FieldTripPath','fieldtripPath must be an existing directory');
end
checkStatisticOverrides(mv.statistics);
assert(isfield(setup,'rc') && isfield(setup.rc,'expFolder') && ...
    isfield(setup.rc,'analysisName'), ...
    'ASCT:RealMultiverse:MissingSetup','Setup must include rc.expFolder and rc.analysisName');
if ~isempty(mv.outputName)
    assert((ischar(mv.outputName) || (isstring(mv.outputName) && isscalar(mv.outputName))) && ...
        ~isempty(regexp(char(mv.outputName),'^[A-Za-z0-9_.-]+$','once')) && ...
        ~ismember(char(mv.outputName),{'.','..'}), ...
        'ASCT:RealMultiverse:InvalidOutputName','outputName must be a simple directory name');
    setup.rc.analysisName=char(mv.outputName);
end
assert(~strcmp(char(mv.sourceAnalysis),[char(setup.rc.analysisName) '__multiverse']), ...
    'ASCT:RealMultiverse:InvalidSource','Do not use multiverse outputs as input');
[plan,specs]=asct_multiverse_plan(setup,mv);
root=fullfile(char(setup.rc.expFolder),[char(setup.rc.analysisName) '__multiverse']);
manifest=fullfile(root,'realdata_manifest.csv');
resultFile=fullfile(root,'realdata_results.mat');
% Immutable execution identity, independent of dryRun and retry settings.
planSnapshot=struct('schemaVersion',1,'setup',setup, ...
    'sourceAnalysis',char(mv.sourceAnalysis),'specs',specs, ...
    'runStatistics',mv.runStatistics,'statistics',mv.statistics, ...
    'cacheStages',mv.cacheStages,'strictArtifacts',mv.strictArtifacts, ...
    'strictLocalization',mv.strictLocalization,'plan',plan);
if isfield(mv,'fieldtripPath'), planSnapshot.fieldtripPath=char(mv.fieldtripPath); end
[planSnapshot.gitRevision,planSnapshot.gitDirty]=detectGitRevision();
if isfield(mv,'codeVersion'), planSnapshot.codeVersion=mv.codeVersion; end
prepared=cell(numel(specs),1);
for i=1:numel(specs)
    prepared{i}=asct_multiverse_realdata_prepare(setup,mv,specs(i));
end
if ~mv.resume && ~mv.allowOverwrite
    % Prevent a blocked rerun from changing EITHER manifest or MAT checkpoint.
    for i=1:numel(prepared)
        target=fullfile(prepared{i}.rc.expFolder,prepared{i}.rc.analysisName);
        assert(~isfolder(target),'ASCT:RealMultiverse:OutputExists', ...
            'Output directory %s already exists. Existing manifest unchanged.',target);
    end
    if isfile(manifest) || isfile(resultFile)
        assert(isPlannedOnly(manifest,resultFile), ...
            'ASCT:RealMultiverse:ManifestExists', ...
            'Prior execution exists in %s. Use resume=true; no files changed.',root);
    end
end
results=emptyResults(specs,prepared,mv);
if mv.resume && (isfile(manifest) || isfile(resultFile))
    assert(isfile(resultFile), 'ASCT:RealMultiverse:MissingCheckpoint', ...
        'Manifest exists without MAT checkpoint: %s. No files changed.',root);
    saved=load(resultFile,'results','planSnapshot');
    assert(isfield(saved,'planSnapshot') && isequaln(saved.planSnapshot,planSnapshot), ...
        'ASCT:RealMultiverse:PlanChanged', ...
        'Saved execution plan differs. Use a NEW outputName; no files changed.');
    assert(isfield(saved,'results') && numel(saved.results)==numel(specs), ...
        'ASCT:RealMultiverse:BadCheckpoint','Saved result count does not match plan');
    results=saved.results;
    assert(all(isfield(results,{'id','status','connectivityStatus','statisticsStatus', ...
        'executionStartStep','reuseFrom','attempt'})), ...
        'ASCT:RealMultiverse:BadCheckpoint','Checkpoint is missing M1 fields');
end
% Reject unsafe resume BEFORE touching the checkpoint or manifest.
if mv.resume && ~mv.dryRun
    for i=1:numel(results)
        f=fullfile(prepared{i}.rc.expFolder,prepared{i}.rc.analysisName);
        if strcmp(results(i).status,'passed') && ~isfolder(f)
            error('ASCT:RealMultiverse:MissingPassedOutput', ...
                'Previously passed variant folder is missing: %s',f);
        end
        if strcmp(results(i).status,'failed') && ~mv.retryFailed
            error('ASCT:RealMultiverse:RetryRequired', ...
                'Failed variant %s needs retryFailed=true. No files changed.',results(i).id);
        end
        if ~strcmp(results(i).status,'passed') && isfolder(f) && ...
                ~mv.retryFailed
            error('ASCT:RealMultiverse:IncompleteOutput', ...
                'Unfinished folder %s needs retryFailed=true. No files changed.',f);
        end
    end
end
fprintf('ASCT real-data multiverse: %d configurations, input=%s, dryRun=%d, STEP11=%d, cache=%d, resume=%d\n', ...
    numel(specs),char(mv.sourceAnalysis),mv.dryRun,mv.runStatistics,mv.cacheStages,mv.resume);
if isfield(setup,'begId') && isfield(setup,'endId')
    fprintf('  Dataset range from setup: begId=%d, endId=%d\n',setup.begId,setup.endId);
end
if mv.dryRun
    for i=1:numel(specs)
        if strcmp(results(i).status,'passed')
            fprintf('  SKIP %s | previously passed\n',specs(i).id);
            continue;
        end
        results(i).status='planned';
        results(i).connectivityStatus='planned';
        if mv.runStatistics, results(i).statisticsStatus='planned'; end
        results(i).executionStartStep=plan(i).executionStartStep;
        results(i).reuseFrom=plan(i).reuseFrom;
        results(i).reuseStage=plan(i).reuseStage;
        fprintf('  PLAN %s | STEP%d -> STEP10',specs(i).id,plan(i).executionStartStep);
        if mv.runStatistics, fprintf(' -> STEP11'); end
        if ~isempty(plan(i).reuseFrom)
            fprintf(' | proposed reuse %s',plan(i).reuseFrom);
        end
        fprintf(' | %s | %s\n',results(i).analysisName,results(i).settings);
    end
    % Resume dry-run must never change a previously committed execution.
    if ~mv.resume || ~isfile(resultFile)
        if ~isfolder(root), mkdir(root); end
        checkpoint(root,results,mv,specs,planSnapshot);
    end
    reportFinish(results,manifest);
    return;
end
if ~isfolder(root), mkdir(root); end
% Write a complete pending manifest before any runner execution. A process
% crash then leaves a resumable checkpoint rather than empty identifiers.
checkpoint(root,results,mv,specs,planSnapshot);
for i=1:numel(specs)
    spec=specs(i);
    analysisFolder=fullfile(prepared{i}.rc.expFolder,prepared{i}.rc.analysisName);
    if strcmp(results(i).status,'passed')
        assert(isfolder(analysisFolder), 'ASCT:RealMultiverse:MissingPassedOutput', ...
            'Completed variant output is missing: %s',analysisFolder);
        fprintf('  SKIP %d/%d | %s | already passed\n',i,numel(specs),spec.id);
        logEvent(root,spec.id,'SKIP','already passed');
        continue;
    end
    % Resume a STEP11 failure without touching its completed STEP10 output.
    statOnly=mv.resume && mv.runStatistics && ...
        strcmp(results(i).connectivityStatus,'passed') && ...
        ~strcmp(results(i).statisticsStatus,'passed');
    if mv.resume && strcmp(results(i).status,'failed') && ~mv.retryFailed
        error('ASCT:RealMultiverse:RetryRequired', ...
            'Variant %s previously failed. Set resume=true,retryFailed=true.',spec.id);
    end
    if statOnly && ~isfolder(analysisFolder)
        error('ASCT:RealMultiverse:MissingPassedOutput', ...
            'STEP10 output is missing for statistics resume: %s',analysisFolder);
    end
    if ~statOnly && isfolder(analysisFolder) && ~mv.allowOverwrite
        if ~mv.resume || ~mv.retryFailed
            error('ASCT:RealMultiverse:IncompleteOutput', ...
                'Unfinished variant folder exists: %s. Use resume=true,retryFailed=true to archive and retry.',analysisFolder);
        end
        backup=backupIncompleteFolder(analysisFolder);
        fprintf('  ARCHIVED %s -> %s\n',analysisFolder,backup);
        logEvent(root,spec.id,'ARCHIVE',backup);
    end
    try
        results(i).attempt=results(i).attempt+1;
        results(i).status='running';
        results(i).error='';
        logEvent(root,spec.id,'START',sprintf('attempt=%d',results(i).attempt));
        checkpoint(root,results,mv,specs,planSnapshot);
        if statOnly
            fprintf('  RESUME %d/%d | %s | STEP11 only\n',i,numel(specs),spec.id);
            logEvent(root,spec.id,'RESUME_STEP11','reuse previously passed STEP10');
            prev=load(fullfile(analysisFolder,'multiverse_setup.mat'),'runsetup');
            runsetup=prev.runsetup;
            results(i).statisticsStatus='running';
            checkpoint(root,results,mv,specs,planSnapshot);
            results(i).output.statistics=runStep11(runsetup,spec,mv,runnerFcn,i,numel(specs));
            results(i).statisticsStatus='passed';
        else
            [executionSpec,inputs,reusedFrom,reuseStage]= ...
                selectExecution(i,specs,plan,results,prepared,mv);
            runsetup=asct_multiverse_realdata_prepare(setup,mv,executionSpec,inputs);
            results(i).executionStartStep=executionSpec.startStep;
            results(i).reuseFrom=reusedFrom;
            results(i).reuseStage=reuseStage;
            if ~isfolder(analysisFolder), mkdir(analysisFolder); end
            if executionSpec.startStep==9
                reconFolder=fullfile(analysisFolder,'7_SOURCEACT');
                if ~isfolder(reconFolder), mkdir(reconFolder); end
            end
            save(fullfile(analysisFolder,'multiverse_setup.mat'),'runsetup','spec');
            checkpoint(root,results,mv,specs,planSnapshot);
            fprintf('  RUN %d/%d | %s | STEP%d -> STEP10', ...
                i,numel(specs),spec.id,executionSpec.startStep);
            if ~isempty(reusedFrom)
                fprintf(' | reuse STEP%d from %s',reuseStage,reusedFrom);
                logEvent(root,spec.id,'REUSE',sprintf('STEP%d from %s',reuseStage,reusedFrom));
            end
            fprintf('\n');
            results(i).output=runnerFcn(runsetup,spec,[]);
            if mv.strictArtifacts
                asct_multiverse_verify_artifacts(runsetup);
            end
            results(i).connectivityStatus='passed';
            checkpoint(root,results,mv,specs,planSnapshot);
            if mv.runStatistics
                results(i).statisticsStatus='running';
                checkpoint(root,results,mv,specs,planSnapshot);
                results(i).output.statistics=runStep11(runsetup,spec,mv,runnerFcn,i,numel(specs));
                results(i).statisticsStatus='passed';
            end
        end
        results(i).status='passed';
        logEvent(root,spec.id,'PASS','all requested stages passed');
    catch ME
        results(i).status='failed';
        if strcmp(results(i).statisticsStatus,'running')
            results(i).statisticsStatus='failed';
        end
        if ~strcmp(results(i).connectivityStatus,'passed')
            results(i).connectivityStatus='failed';
        end
        results(i).error=sprintf('%s: %s',ME.identifier,ME.message);
        warning('ASCT:RealMultiverse:RunFailed','%s failed: %s',spec.id,results(i).error);
        logEvent(root,spec.id,'FAIL',results(i).error);
    end
    checkpoint(root,results,mv,specs,planSnapshot);
    if strcmp(results(i).status,'failed') && ~mv.continueOnError
        error('ASCT:RealMultiverse:Stopped', ...
            'Stopping after %s. See %s',spec.id,manifest);
    end
end
reportFinish(results,manifest);
if any(strcmp({results.status},'failed'))
    error('ASCT:RealMultiverse:FailedRuns', ...
        'Some configurations failed; consult %s',manifest);
end
end

function results=emptyResults(specs,prepared,mv)
results=repmat(struct('id','','startStep',0,'analysisName','', ...
    'status','pending','connectivityStatus','pending', ...
    'statisticsStatus','skipped','settings','','error','','output',struct(), ...
    'executionStartStep',0,'reuseFrom','','reuseStage',0,'attempt',0), ...
    numel(specs),1);
for i=1:numel(specs)
    results(i).id=specs(i).id;
    results(i).startStep=specs(i).startStep;
    results(i).executionStartStep=specs(i).startStep;
    results(i).analysisName=char(prepared{i}.rc.analysisName);
    results(i).settings=jsonencode(specs(i).changes);
    if mv.runStatistics, results(i).statisticsStatus='pending'; end
end
end

function tf=isPlannedOnly(manifest,resultFile)
tf=true;
if isfile(resultFile)
    saved=load(resultFile,'results');
    tf=isfield(saved,'results') && ...
        all(strcmp({saved.results.status},'planned'));
end
if tf && isfile(manifest)
    old=readtable(manifest,'FileType','text','Delimiter',',', ...
        'ReadVariableNames',true,'VariableNamingRule','preserve','TextType','string');
    tf=ismember('connectivityStatus',old.Properties.VariableNames) && ...
        all(strcmpi(string(old.connectivityStatus),'planned'));
end
end

function [executionSpec,inputs,reusedFrom,reuseStage]=selectExecution(i,specs,plan,results,prepared,mv)
executionSpec=specs(i);
inputs=struct(); reusedFrom=''; reuseStage=0;
if ~mv.cacheStages || specs(i).startStep==10, return; end
folder=char(prepared{i}.rc.expFolder);
% The closest reusable stage is preferred. Verify actual files, not just
% directories; never infer a cache hit from a planned/failed status.
for j=i-1:-1:1
    if ~strcmp(results(j).status,'passed'), continue; end
    donor=results(j).analysisName;
    if isequaln(plan(i).stageKey.step9,plan(j).stageKey.step9) && ...
            results(j).executionStartStep<=9 && hasStage(folder,donor,9,prepared{i})
        executionSpec.startStep=10;
        inputs.sigroiName=donor;
        reusedFrom=donor; reuseStage=9;
        return;
    end
end
for j=i-1:-1:1
    if ~strcmp(results(j).status,'passed'), continue; end
    donor=results(j).analysisName;
    if isequaln(plan(i).stageKey.step8,plan(j).stageKey.step8) && ...
            results(j).executionStartStep<=8 && hasStage(folder,donor,8,prepared{i})
        inputICA2=donor;
        prev=load(fullfile(folder,donor,'multiverse_setup.mat'),'runsetup');
        if isfield(prev.runsetup.rc,'ica2Name')
            inputICA2=prev.runsetup.rc.ica2Name;
        end
        if ~hasStage(folder,inputICA2,0,prepared{i}), continue; end
        executionSpec.startStep=9;
        inputs.iclocName=donor;
        inputs.ica2Name=inputICA2;
        reusedFrom=donor; reuseStage=8;
        return;
    end
end
for j=i-1:-1:1
    if ~strcmp(results(j).status,'passed'), continue; end
    donor=results(j).analysisName;
    if isequaln(plan(i).stageKey.step0,plan(j).stageKey.step0) && ...
            results(j).executionStartStep==0 && hasStage(folder,donor,0,prepared{i})
        executionSpec.startStep=8;
        inputs.ica2Name=donor;
        reusedFrom=donor; reuseStage=0;
        return;
    end
end
end

function tf=hasStage(folder,name,stage,p)
% Conservative artifact check: at least the requested participants in each
% available DC, with real, nonempty files. Status and fingerprints are
% checked by the caller before this filesystem check.
root=fullfile(folder,char(name));
expected=1;
if isfield(p,'begId') && isfield(p,'endId') && ...
        isscalar(p.begId) && isscalar(p.endId) && ...
        p.begId>0 && p.endId>=p.begId
    expected=p.endId-p.begId+1;
end
switch stage
    case 0
        files=dir(fullfile(root,'6_ICA2','*_ica2.mat'));
        tf=enough(files,expected);
    case 8
        files=dir(fullfile(root,'7_SOURCEACT','icloc','*icloc.mat'));
        tf=enough(files,expected);
    case 9
        con=p.con;
        mods={};
        if ~isfield(con,'lc') || con.lc, mods{end+1}='lc'; end
        if isfield(con,'unc') && con.unc, mods{end+1}='unc'; end
        dc=dir(fullfile(root,'7_SOURCEACT','DC*'));
        dc=dc([dc.isdir]);
        tf=~isempty(mods) && ~isempty(dc);
        if isfield(p,'design') && isfield(p.design,'DC') && ~isempty(p.design.DC)
            % Never reuse a donor with missing design conditions.
            expectedNames=arrayfun(@(n)sprintf('DC%d',n), ...
                1:numel(p.design.DC),'UniformOutput',false);
            if ~all(ismember(expectedNames,{dc.name})), tf=false; return; end
        end
        for d=1:numel(dc)
            for m=1:numel(mods)
                files=dir(fullfile(dc(d).folder,dc(d).name,mods{m}, ...
                    ['*_sigroi_' mods{m} '.mat']));
                if ~enough(files,expected), tf=false; return; end
            end
        end
    otherwise
        tf=false;
end
end

function tf=enough(files,expected)
tf=numel(files)>=expected && all([files.bytes]>0);
end

function output=runStep11(runsetup,spec,mv,runnerFcn,i,n)
statSetup=runsetup;
statSetup.rc.load=11;
statSetup.rc.stop=11;
statSetup.con=applyStatisticOverrides(statSetup.con,mv.statistics);
asct_multiverse_check_conn(statSetup);
if isfield(mv,'fieldtripPath'), statSetup.fieldtripPath=char(mv.fieldtripPath); end
fprintf('  STAT %d/%d | %s | STEP11\n',i,n,spec.id);
output=runnerFcn(statSetup,spec,[]);
end

function backup=backupIncompleteFolder(folder)
for i=1:9999
    backup=sprintf('%s.incomplete_backup_%04d',folder,i);
    if ~isfolder(backup) && ~isfile(backup)
        [ok,msg]=movefile(folder,backup);
        assert(ok,'ASCT:RealMultiverse:BackupFailed', ...
            'Cannot archive incomplete folder %s: %s',folder,msg);
        return;
    end
end
error('ASCT:RealMultiverse:BackupFailed','No available backup name for %s',folder);
end

function checkpoint(root,results,mv,specs,planSnapshot)
% Write each file via a temporary sibling and rename. The MAT checkpoint is
% authoritative for resume if the process terminates between the two moves.
mat=fullfile(root,'realdata_results.mat');
partial=fullfile(root,'realdata_results.partial.mat');
save(partial,'results','mv','specs','planSnapshot');
[ok,msg]=movefile(partial,mat,'f');
assert(ok,'ASCT:RealMultiverse:CheckpointFailed','Cannot save MAT checkpoint: %s',msg);
ids=string({results.id})';
startSteps=[results.startStep]';
analysisNames=string({results.analysisName})';
statuses=string({results.status})';
connectivityStatuses=string({results.connectivityStatus})';
statisticsStatuses=string({results.statisticsStatus})';
settings=string({results.settings})';
errors=string({results.error})';
executionStartSteps=[results.executionStartStep]';
reusedFrom=string({results.reuseFrom})';
reuseStages=[results.reuseStage]';
attempts=[results.attempt]';
codeRevision=repmat(string(planSnapshot.gitRevision),numel(results),1);
codeDirty=repmat(logical(planSnapshot.gitDirty),numel(results),1);
t=table(ids,startSteps,analysisNames,statuses,connectivityStatuses,statisticsStatuses, ...
    settings,errors,executionStartSteps,reusedFrom,reuseStages,attempts,codeRevision,codeDirty, ...
    'VariableNames',{'configId','startStep','analysisName','status', ...
    'connectivityStatus','statisticsStatus','settingsJson','error', ...
    'executionStartStep','reusedFrom','reuseStage','attempt','gitRevision','gitDirty'});
csv=fullfile(root,'realdata_manifest.csv');
partialCsv=[csv '.partial.csv'];
writetable(t,partialCsv);
[ok,msg]=movefile(partialCsv,csv,'f');
assert(ok,'ASCT:RealMultiverse:CheckpointFailed','Cannot save CSV manifest: %s',msg);
end

function [revision,dirty]=detectGitRevision()
% Record code provenance when ASCT resides in a Git checkout. Git is not
% required in offline deployments; in that case revision is 'unknown'.
revision='unknown'; dirty=false;
repo=fileparts(fileparts(mfilename('fullpath')));
repo=strrep(repo,'"','\"');
if ispc, suppress='2>NUL'; else, suppress='2>/dev/null'; end
[ok,out]=system(sprintf('git -C "%s" rev-parse HEAD %s',repo,suppress));
if ok==0
    sha=strtrim(out);
    if ~isempty(regexp(sha,'^[0-9a-fA-F]{40,64}$','once'))
        revision=sha;
    end
end
[ok,out]=system(sprintf('git -C "%s" status --porcelain --untracked-files=no %s', ...
    repo,suppress));
if ok==0, dirty=~isempty(strtrim(out)); end
end

function logEvent(root,id,event,detail)
% Append-only operational event stream (not a scientific interpretation).
file=fullfile(root,'realdata_events.csv');
new=~isfile(file);
fid=fopen(file,'a');
assert(fid~=-1,'ASCT:RealMultiverse:EventLog','Cannot append event log: %s',file);
clean=@(x) ['"' strrep(strrep(strrep(char(x),'"','""'),sprintf('\n'),' '),sprintf('\r'),' ') '"'];
if new, fprintf(fid,'timestamp,configId,event,detail\n'); end
fprintf(fid,'%s,%s,%s,%s\n',clean(datestr(now,'yyyy-mm-ddTHH:MM:SS')), ...
    clean(id),clean(event),clean(detail));
fclose(fid);
end

function reportFinish(results,manifest)
fprintf('ASCT multiverse finished: passed=%d failed=%d planned=%d. Manifest: %s\n', ...
    sum(strcmp({results.status},'passed')),sum(strcmp({results.status},'failed')), ...
    sum(strcmp({results.status},'planned')),manifest);
end

function checkStatisticOverrides(o)
valid={'freqRange','subTitle','pThresh','iqr','contrast2test','oneTailed','testType'};
names=fieldnames(o);
for k=1:numel(names)
    assert(ismember(names{k},valid), 'ASCT:RealMultiverse:UnknownStatistic', ...
        'Unsupported multiverse.statistics.%s',names{k});
end
if xor(isfield(o,'freqRange'),isfield(o,'subTitle'))
    error('ASCT:RealMultiverse:StatisticBands', ...
        'Specify both statistics.freqRange and statistics.subTitle');
end
if isfield(o,'freqRange')
    assert(iscell(o.freqRange) && iscell(o.subTitle) && ...
        numel(o.freqRange)==numel(o.subTitle) && ~isempty(o.freqRange), ...
        'ASCT:RealMultiverse:StatisticBands', ...
        'freqRange and subTitle must be equally sized nonempty cell arrays');
end
end

function c=applyStatisticOverrides(c,o)
names=fieldnames(o);
for k=1:numel(names), c.(names{k})=o.(names{k}); end
end
