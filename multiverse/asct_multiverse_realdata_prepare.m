function runsetup = asct_multiverse_realdata_prepare(base,mv,spec,input)
%ASCT_MULTIVERSE_REALDATA_PREPARE Configure REAL ASCT, reusing safe stages.
% STEP10 uses existing 7_SOURCEACT; STEP9 uses existing 6_ICA2/icloc;
% STEP8 uses existing 6_ICA2; STEP0 runs the full preprocessing pipeline.
% Optional input overrides the upstream source for safe cached stages.
if nargin<4, input=struct(); end
required={'rc','chan','filter','seg','ar','ica','loc','con','design'};
for k=1:numel(required)
    assert(isfield(base,required{k}), 'ASCT:RealMultiverse:MissingSetup', ...
        'Missing setup variable: %s',required{k});
end
assert(isfield(base.rc,'expFolder') && isfield(base.rc,'analysisName') && ...
    isfield(mv,'sourceAnalysis') && ~isempty(mv.sourceAnalysis), ...
    'ASCT:RealMultiverse:MissingSource', ...
    'Specify rc.expFolder, rc.analysisName and multiverse.sourceAnalysis');
runsetup=base;
groups=fieldnames(spec.changes);
for i=1:numel(groups)
    group=groups{i};
    names=fieldnames(spec.changes.(group));
    for j=1:numel(names)
        name=names{j};
        value=spec.changes.(group).(name);
        if isstring(value), value=char(value); end
        runsetup.(group).(name)=value;
    end
end
if spec.startStep==0
    runsetup.filter=asct_multiverse_validate_filter(runsetup.filter);
end
runsetup.rc.analysisName=[char(base.rc.analysisName) '__' spec.id];
runsetup.rc.load=spec.startStep;
runsetup.rc.stop=10; % current implementation is a single-case STEP10 study
changedLoc=struct();
if isfield(spec.changes,'loc'), changedLoc=spec.changes.loc; end
strict=false;
if isfield(mv,'strictLocalization'), strict=mv.strictLocalization; end
runsetup.loc=asct_multiverse_validate_localization(runsetup.loc,changedLoc,strict && spec.startStep<=8,base.loc);
if spec.startStep<=9
    % Neither localization nor reconstruction may modify shared MRI models.
    runsetup.rc.multiverseIsolatedLeadfield=true;
end
if spec.startStep<=8 && isfield(changedLoc,'depthWeight')
    % An existing source model may contain a leadfield for another weight.
    runsetup.loc.force_lf=1;
end
if isfield(mv,'fieldtripPath'), runsetup.fieldtripPath=char(mv.fieldtripPath); end
% Keep existing datasets intact. Reuse upstream results only when they are
% scientifically valid for the changed processing step.
for k={'ica2Name','iclocName','sigroiName'}
    if isfield(runsetup.rc,k{1})
        runsetup.rc=rmfield(runsetup.rc,k{1});
    end
end
switch spec.startStep
    case 0
        inputPath=fullfile(runsetup.rc.expFolder,runsetup.rc.dataRawFolder);
        inputLabel='raw input (STEP0)';
    case 8
        runsetup.rc.ica2Name=char(mv.sourceAnalysis);
        if isfield(input,'ica2Name'), runsetup.rc.ica2Name=char(input.ica2Name); end
        inputPath=fullfile(runsetup.rc.expFolder,runsetup.rc.ica2Name,'6_ICA2');
        inputLabel='ICA2 input (STEP8)';
    case 9
        runsetup.rc.iclocName=char(mv.sourceAnalysis);
        if isfield(input,'iclocName'), runsetup.rc.iclocName=char(input.iclocName); end
        if isfield(input,'ica2Name'), runsetup.rc.ica2Name=char(input.ica2Name); end
        inputPath=fullfile(runsetup.rc.expFolder,runsetup.rc.iclocName,'7_SOURCEACT','icloc');
        inputLabel='localized IC input (STEP9)';
    case 10
        runsetup.rc.sigroiName=char(mv.sourceAnalysis);
        if isfield(input,'sigroiName'), runsetup.rc.sigroiName=char(input.sigroiName); end
        inputPath=fullfile(runsetup.rc.expFolder,runsetup.rc.sigroiName,'7_SOURCEACT');
        inputLabel='reconstructed ROI signals (STEP10)';
    otherwise
        error('ASCT:RealMultiverse:InvalidStage','Unsupported starting stage');
end
assert(isfolder(inputPath), 'ASCT:RealMultiverse:MissingInput', ...
    'Cannot find %s at %s. Run the prerequisite singleverse stages first.',inputLabel,inputPath);
% If reconstruction starts at STEP9, it needs both ICA2 and ICLOC.
if spec.startStep==9
    if isfield(runsetup.rc,'ica2Name')
        icaSource=runsetup.rc.ica2Name;
    else
        icaSource=runsetup.rc.iclocName;
    end
    icaPath=fullfile(runsetup.rc.expFolder,icaSource,'6_ICA2');
    assert(isfolder(icaPath),'ASCT:RealMultiverse:MissingInput', ...
        'STEP9 also requires baseline 6_ICA2: %s',icaPath);
end
if isfield(runsetup.loc,'method')
    assert(strcmpi(char(runsetup.loc.method),'mne'), ...
        'ASCT:RealMultiverse:UnsupportedLocalization', ...
        'Only loc.method=mne is currently supported');
end
if isfield(runsetup.loc,'norm')
    assert(ismember(char(runsetup.loc.norm),{'lambda','cov'}), ...
        'ASCT:RealMultiverse:InvalidNorm','loc.norm must be lambda or cov');
end
if isfield(runsetup.con,'orderSelection')
    assert(ismember(lower(char(runsetup.con.orderSelection)),{'fixed','aic'}), ...
        'ASCT:RealMultiverse:InvalidOrder','orderSelection must be fixed or aic');
end
if isfield(runsetup.con,'orderSelection') && strcmpi(char(runsetup.con.orderSelection),'aic')
    runsetup.con.mvarOrd=0;
    if ~isfield(runsetup.con,'maxMvarOrder')
        runsetup.con.maxMvarOrder=10;
    end
elseif ~isfield(runsetup.con,'orderSelection')
    runsetup.con.orderSelection='fixed';
end
if strcmpi(runsetup.con.orderSelection,'fixed')
    assert(isfield(runsetup.con,'mvarOrd') && isscalar(runsetup.con.mvarOrd) && ...
        isnumeric(runsetup.con.mvarOrd) && runsetup.con.mvarOrd>=1 && ...
        runsetup.con.mvarOrd==fix(runsetup.con.mvarOrd), ...
        'ASCT:RealMultiverse:InvalidOrder','Fixed con.mvarOrd must be a positive integer');
end
if isfield(runsetup.con,'lc') && isfield(runsetup.con,'unc')
    assert(runsetup.con.lc || runsetup.con.unc, 'ASCT:RealMultiverse:NoSignal', ...
        'At least one of con.lc and con.unc must be enabled');
end
if spec.startStep~=0 && isfield(runsetup.rc,'sim')
    runsetup.rc.sim=[];
end
end
