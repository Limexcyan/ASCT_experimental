function results = asct_multiverse_realdata(setup,mv,runnerFcn)
%ASCT_MULTIVERSE_REALDATA Run ASCT multiverse from a familiar ExSetup.
%
% Example setup-file tail (after setting rc, chan, filter, ..., design):
%   mv.mode='multi'; mv.sourceAnalysis='ana1'; mv.maxRuns=2;
%   mv.factors.con.varNorm=[0 1]; mv.dryRun=true;
%   asct_multiverse_realdata(struct('rc',rc,'chan',chan, ...),mv);
%
% Uses existing REAL datasets (never synthesizes data). No ground-truth F1 is
% computed for experimental recordings. Each run gets a separate analysisName.
if nargin<3 || isempty(runnerFcn), runnerFcn=@asct_multiverse_execute; end
assert(isa(runnerFcn,'function_handle'), 'ASCT:RealMultiverse:InvalidRunner', ...
    'runnerFcn must be a function handle');
assert(isstruct(mv) && isfield(mv,'sourceAnalysis'), ...
    'ASCT:RealMultiverse:MissingSource','Specify multiverse.sourceAnalysis');
assert(ischar(mv.sourceAnalysis) || (isstring(mv.sourceAnalysis) && isscalar(mv.sourceAnalysis)), ...
    'ASCT:RealMultiverse:MissingSource','Specify multiverse.sourceAnalysis as a folder name');
assert(~isempty(regexp(char(mv.sourceAnalysis),'^[A-Za-z0-9_.-]+$','once')) && ...
    ~ismember(char(mv.sourceAnalysis),{'.','..'}), ...
    'ASCT:RealMultiverse:InvalidSource','sourceAnalysis must be an existing folder name, not a path');
if ~isfield(mv,'maxRuns'), mv.maxRuns=12; end
if ~isfield(mv,'dryRun'), mv.dryRun=true; end
if ~isfield(mv,'continueOnError'), mv.continueOnError=false; end
if ~isfield(mv,'allowOverwrite'), mv.allowOverwrite=false; end
specs=asct_multiverse_realdata_grid(mv);
assert(isfield(setup,'rc') && isfield(setup.rc,'expFolder') && ...
    isfield(setup.rc,'analysisName'), ...
    'ASCT:RealMultiverse:MissingSetup','Setup must include rc.expFolder and rc.analysisName');
root=fullfile(char(setup.rc.expFolder),[char(setup.rc.analysisName) '__multiverse']);
assert(~strcmp(char(mv.sourceAnalysis),[char(setup.rc.analysisName) '__multiverse']), ...
    'ASCT:RealMultiverse:InvalidSource','Do not use the multiverse output folder as input');
% Prepare and validate every configuration before any ASCT run starts.
prepared=cell(numel(specs),1);
for i=1:numel(specs)
    prepared{i}=asct_multiverse_realdata_prepare(setup,mv,specs(i));
end
if ~isfolder(root), mkdir(root); end
results=repmat(struct('id','','startStep',0,'analysisName','', ...
    'status','','settings','','error','','output',struct()),numel(specs),1);
fprintf('ASCT real-data multiverse: %d configurations, input=%s, dryRun=%d\n', ...
    numel(specs),char(mv.sourceAnalysis),logical(mv.dryRun));
for i=1:numel(specs)
    spec=specs(i);
    runsetup=prepared{i};
    results(i).id=spec.id;
    results(i).startStep=spec.startStep;
    results(i).analysisName=char(runsetup.rc.analysisName);
    results(i).settings=jsonencode(spec.changes);
    analysisFolder=fullfile(runsetup.rc.expFolder,runsetup.rc.analysisName);
    if mv.dryRun
        results(i).status='planned';
        fprintf('  PLAN %s | STEP%d -> STEP10 | %s | %s\n', ...
            spec.id,spec.startStep,runsetup.rc.analysisName,results(i).settings);
        continue;
    end
    try
        if isfolder(analysisFolder) && ~mv.allowOverwrite
            error('ASCT:RealMultiverse:OutputExists', ...
                'Output directory %s already exists. Refusing to overwrite.',analysisFolder);
        end
        if ~isfolder(analysisFolder), mkdir(analysisFolder); end
        if spec.startStep==9
            mkdir(fullfile(analysisFolder,'7_SOURCEACT'));
        end
        save(fullfile(analysisFolder,'multiverse_setup.mat'),'runsetup','spec');
        fprintf('  RUN %d/%d | %s | STEP%d -> STEP10\n', ...
            i,numel(specs),spec.id,spec.startStep);
        results(i).output=runnerFcn(runsetup,spec,[]);
        results(i).status='passed';
    catch ME
        results(i).status='failed';
        results(i).error=sprintf('%s: %s',ME.identifier,ME.message);
        warning('ASCT:RealMultiverse:RunFailed','%s failed: %s',spec.id,results(i).error);
    end
    save(fullfile(root,'realdata_results.mat'),'results','mv','specs');
    exportManifest(root,results);
    if strcmp(results(i).status,'failed') && ~mv.continueOnError
        error('ASCT:RealMultiverse:Stopped', ...
            'Stopping after %s. See %s',spec.id,fullfile(root,'realdata_manifest.csv'));
    end
end
save(fullfile(root,'realdata_results.mat'),'results','mv','specs');
exportManifest(root,results);
fprintf('ASCT multiverse finished: passed=%d failed=%d planned=%d. Manifest: %s\n', ...
    sum(strcmp({results.status},'passed')),sum(strcmp({results.status},'failed')), ...
    sum(strcmp({results.status},'planned')),fullfile(root,'realdata_manifest.csv'));
if any(strcmp({results.status},'failed'))
    error('ASCT:RealMultiverse:FailedRuns', ...
        'Some real-data configurations failed; consult %s',fullfile(root,'realdata_manifest.csv'));
end
end

function exportManifest(root,results)
ids=string({results.id})';
startSteps=[results.startStep]';
analysisNames=string({results.analysisName})';
statuses=string({results.status})';
settings=string({results.settings})';
errors=string({results.error})';
t=table(ids,startSteps,analysisNames,statuses,settings,errors, ...
    'VariableNames',{'configId','startStep','analysisName','status','settingsJson','error'});
writetable(t,fullfile(root,'realdata_manifest.csv'));
end
