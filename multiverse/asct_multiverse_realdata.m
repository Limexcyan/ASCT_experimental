function results = asct_multiverse_realdata(setup,mv,runnerFcn)
%ASCT_MULTIVERSE_REALDATA Run real-data multiverse from an existing ExSetup.
% Each variant has its own output directory; sourceAnalysis is read-only.
% Optional mv.runStatistics=true runs STEP11 after STEP10 for each variant.
% mv.statistics overrides statistical settings ONLY for STEP11.
% Real-data analysis does not have a known ground-truth connectivity matrix.
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
assert(islogical(mv.runStatistics) && isscalar(mv.runStatistics), ...
    'ASCT:RealMultiverse:StatisticsFlag','runStatistics must be a logical scalar');
assert(isstruct(mv.statistics) && isscalar(mv.statistics), ...
    'ASCT:RealMultiverse:StatisticsOptions','statistics must be a scalar struct');
if isfield(mv,'fieldtripPath')
    assert((ischar(mv.fieldtripPath) || (isstring(mv.fieldtripPath) && isscalar(mv.fieldtripPath))) ...
        && isfolder(char(mv.fieldtripPath)), ...
        'ASCT:RealMultiverse:FieldTripPath','fieldtripPath must be an existing directory');
end
% Check STEP11 overrides before creating any output directories.
checkStatisticOverrides(mv.statistics);
specs=asct_multiverse_realdata_grid(mv);
assert(isfield(setup,'rc') && isfield(setup.rc,'expFolder') && ...
    isfield(setup.rc,'analysisName'), ...
    'ASCT:RealMultiverse:MissingSetup','Setup must include rc.expFolder and rc.analysisName');
if ~isempty(mv.outputName)
    assert((ischar(mv.outputName) || (isstring(mv.outputName) && isscalar(mv.outputName))) && ...
        ~isempty(regexp(char(mv.outputName),'^[A-Za-z0-9_.-]+$','once')) && ...
        ~ismember(char(mv.outputName),{'.','..'}), ...
        'ASCT:RealMultiverse:InvalidOutputName', ...
        'outputName must be a simple directory name');
    setup.rc.analysisName=char(mv.outputName);
end
root=fullfile(char(setup.rc.expFolder),[char(setup.rc.analysisName) '__multiverse']);
assert(~strcmp(char(mv.sourceAnalysis),[char(setup.rc.analysisName) '__multiverse']), ...
    'ASCT:RealMultiverse:InvalidSource','Do not use multiverse outputs as input');
prepared=cell(numel(specs),1);
for i=1:numel(specs)
    prepared{i}=asct_multiverse_realdata_prepare(setup,mv,specs(i));
end
% Important: fail BEFORE writing the shared manifest or MAT results.
% Otherwise a blocked rerun can erase the prior successful execution log.
if ~mv.allowOverwrite
    for i=1:numel(prepared)
        target=fullfile(char(prepared{i}.rc.expFolder), ...
            char(prepared{i}.rc.analysisName));
        if isfolder(target)
            error('ASCT:RealMultiverse:OutputExists', ...
                'Output directory %s already exists. Refusing to overwrite. Existing manifest unchanged.',target);
        end
    end
    previousManifest=fullfile(root,'realdata_manifest.csv');
    if isfile(previousManifest)
        old=readtable(previousManifest,'FileType','text','Delimiter',',', ...
            'ReadVariableNames',true,'VariableNamingRule','preserve', ...
            'TextType','string');
        if ~ismember('connectivityStatus',old.Properties.VariableNames) || ...
                ~all(strcmpi(string(old.connectivityStatus),'planned'))
            error('ASCT:RealMultiverse:ManifestExists', ...
                'Previous execution manifest exists: %s. Existing manifest unchanged.',previousManifest);
        end
    end
end
if ~isfolder(root), mkdir(root); end
results=repmat(struct('id','','startStep',0,'analysisName','', ...
    'status','','connectivityStatus','pending','statisticsStatus','skipped', ...
    'settings','','error','','output',struct()),numel(specs),1);
fprintf('ASCT real-data multiverse: %d configurations, input=%s, dryRun=%d, STEP11=%d\n', ...
    numel(specs),char(mv.sourceAnalysis),logical(mv.dryRun),logical(mv.runStatistics));
if isfield(setup,'begId') && isfield(setup,'endId')
    fprintf('  Dataset range from setup: begId=%d, endId=%d\n',setup.begId,setup.endId);
end
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
        results(i).connectivityStatus='planned';
        if mv.runStatistics, results(i).statisticsStatus='planned'; end
        fprintf('  PLAN %s | STEP%d -> STEP10',spec.id,spec.startStep);
        if mv.runStatistics, fprintf(' -> STEP11'); end
        fprintf(' | %s | %s\n',runsetup.rc.analysisName,results(i).settings);
        continue;
    end
    try
        if isfolder(analysisFolder) && ~mv.allowOverwrite
            error('ASCT:RealMultiverse:OutputExists', ...
                'Output directory %s already exists. Refusing to overwrite.',analysisFolder);
        end
        if ~isfolder(analysisFolder), mkdir(analysisFolder); end
        if spec.startStep==9
            reconFolder=fullfile(analysisFolder,'7_SOURCEACT');
            if ~isfolder(reconFolder), mkdir(reconFolder); end
        end
        save(fullfile(analysisFolder,'multiverse_setup.mat'),'runsetup','spec');
        fprintf('  RUN %d/%d | %s | STEP%d -> STEP10\n', ...
            i,numel(specs),spec.id,spec.startStep);
        results(i).output=runnerFcn(runsetup,spec,[]);
        results(i).connectivityStatus='passed';
        if mv.runStatistics
            results(i).statisticsStatus='running';
            % STEP11 is invoked separately, so it can be diagnosed independently
            % of STEP10. This uses the variant's own 8_CONN directory.
            statSetup=runsetup;
            statSetup.rc.load=11;
            statSetup.rc.stop=11;
            statSetup.con=applyStatisticOverrides(statSetup.con,mv.statistics);
            asct_multiverse_check_conn(statSetup);
            if isfield(mv,'fieldtripPath')
                statSetup.fieldtripPath=char(mv.fieldtripPath);
            end
            fprintf('  STAT %d/%d | %s | STEP11\n',i,numel(specs),spec.id);
            results(i).output.statistics=runnerFcn(statSetup,spec,[]);
            results(i).statisticsStatus='passed';
        end
        results(i).status='passed';
    catch ME
        results(i).status='failed';
        if strcmp(results(i).statisticsStatus,'running')
            results(i).statisticsStatus='failed';
        end
        if strcmp(results(i).connectivityStatus,'pending')
            results(i).connectivityStatus='failed';
        end
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
for k=1:numel(names)
    c.(names{k})=o.(names{k});
end
end

function exportManifest(root,results)
ids=string({results.id})';
startSteps=[results.startStep]';
analysisNames=string({results.analysisName})';
statuses=string({results.status})';
connectivityStatuses=string({results.connectivityStatus})';
statisticsStatuses=string({results.statisticsStatus})';
settings=string({results.settings})';
errors=string({results.error})';
t=table(ids,startSteps,analysisNames,statuses,connectivityStatuses,statisticsStatuses,settings,errors, ...
    'VariableNames',{'configId','startStep','analysisName','status', ...
    'connectivityStatus','statisticsStatus','settingsJson','error'});
writetable(t,fullfile(root,'realdata_manifest.csv'));
end
