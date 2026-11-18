function report = asct_multiverse_flanker_preflight(setup,mv)
%ASCT_MULTIVERSE_FLANKER_PREFLIGHT Validate real Flanker ROI inputs for STEP10.
% Read-only check. Does not run FieldTrip, mmultar or statistics.
% Run after building setup from ExSetup and before asct_multiverse_realdata.
assert(isfield(setup,'rc') && isfield(setup,'con') && isfield(setup,'design'), ...
    'ASCT:Flanker:InvalidSetup','Expected rc, con and design in setup');
assert(isfield(mv,'sourceAnalysis') && ~isempty(mv.sourceAnalysis), ...
    'ASCT:Flanker:MissingSource','Set multiverse.sourceAnalysis');
assert(isfield(setup.design,'DC') && ~isempty(setup.design.DC), ...
    'ASCT:Flanker:MissingDC','Define design.DC');

base = fullfile(char(setup.rc.expFolder),char(mv.sourceAnalysis),'7_SOURCEACT');
assert(isfolder(base),'ASCT:Flanker:MissingROIs', ...
    'Missing baseline ROI directory: %s',base);
useLC = ~isfield(setup.con,'lc') || logical(setup.con.lc);
useUNC = isfield(setup.con,'unc') && logical(setup.con.unc);
assert(useLC || useUNC,'ASCT:Flanker:NoSignals', ...
    'At least one of con.lc and con.unc must be enabled');
if useLC && useUNC
    modalities={'lc','unc'};
elseif useLC
    modalities={'lc'};
else
    modalities={'unc'};
end

beg=0; last=0;
if isfield(setup,'begId'), beg=setup.begId; end
if isfield(setup,'endId'), last=setup.endId; end
assert(isscalar(beg) && isscalar(last) && isnumeric(beg) && isnumeric(last) && ...
    all(isfinite([beg last])) && all([beg last]==fix([beg last])) && ...
    ((beg==0 && last==0) || (beg>=1 && last>=beg)), ...
    'ASCT:Flanker:InvalidDatasetRange', ...
    'begId/endId must be absent, or both integers with 1 <= begId <= endId');

nDC=numel(setup.design.DC);
report=repmat(struct('dc',0,'modality','','available',0,'selected',0,'ids',{{}}), ...
    nDC*numel(modalities),1);
selectedIDs=cell(nDC,numel(modalities));
r=0;
for m=1:numel(modalities)
    mod=modalities{m};
    for dc=1:nDC
        dirPath=fullfile(base,sprintf('DC%d',dc),mod);
        assert(isfolder(dirPath),'ASCT:Flanker:MissingROIs', ...
            'Missing ROI folder: %s',dirPath);
        files=dir(fullfile(dirPath,['*_sigroi_' mod '.mat']));
        assert(~isempty(files),'ASCT:Flanker:MissingROIs', ...
            'No reconstructed ROI MAT files found in %s',dirPath);
        [~,order]=sort({files.name}); files=files(order);
        if beg>0
            assert(numel(files)>=last,'ASCT:Flanker:TooFewDatasets', ...
                'DC%d/%s contains only %d files; endId=%d',dc,mod,numel(files),last);
            filesSel=files(beg:last);
        else
            filesSel=files;
        end
        ids=cell(1,numel(filesSel));
        for i=1:numel(filesSel)
            filename=filesSel(i).name;
            variableName='data_sigroi';
            if strcmp(mod,'unc'), variableName='data_sigroi_unc'; end
            metadata=whos('-file',fullfile(dirPath,filename));
            assert(any(strcmp({metadata.name},variableName)), ...
                'ASCT:Flanker:InvalidROIFile', ...
                'Missing %s variable in %s',variableName,fullfile(dirPath,filename));
            [~,stem]=fileparts(filename);
            assert(numel(stem)>=setup.design.idPosEnd, ...
                'ASCT:Flanker:FilenameID', ...
                'Filename too short for idPosEnd: %s',filename);
            ids{i}=stem(setup.design.idPosStart:setup.design.idPosEnd);
        end
        r=r+1;
        report(r).dc=dc;
        report(r).modality=mod;
        report(r).available=numel(dir(fullfile(dirPath,['*_sigroi_' mod '.mat'])));
        report(r).selected=numel(filesSel);
        report(r).ids=ids;
        selectedIDs{dc,m}=ids;
        fprintf('  ROI DC%d/%s: %d plikow, wybrane %d, ID: %s\n', ...
            dc,mod,report(r).available,report(r).selected,strjoin(ids,', '));
    end
end

% Within-subject statistics assume one corresponding observation per ID/condition.
%% Always require paired subjects for the Flanker within-subject STEP10 pilot.
% Previously this check only ran with mv.runStatistics=true; a STEP10-only
% multiverse could silently process an unpaired subset of participants.
within=~isfield(setup.con,'testType') || strcmpi(setup.con.testType,'within');
if within
    assert(isfield(setup.con,'contrast2test') && iscell(setup.con.contrast2test), ...
        'ASCT:Flanker:MissingContrast','Set con.contrast2test');
    for m=1:numel(modalities)
        for ci=1:numel(setup.con.contrast2test)
            pair=setup.con.contrast2test{ci};
            assert(numel(pair)==2 && all(pair>=1) && all(pair<=nDC) && ...
                all(pair==fix(pair)), ...
                'ASCT:Flanker:InvalidContrast','Invalid DC contrast');
            a=selectedIDs{pair(1),m}; b=selectedIDs{pair(2),m};
            assert(numel(unique(a))==numel(a) && numel(unique(b))==numel(b), ...
                'ASCT:Flanker:DuplicateIDs', ...
                ['Repeated subject IDs in a DC. STEP11 within-subject test ' ...
                 'does not correctly model repeated sessions. Check begId/endId.']);
            assert(isequal(sort(a),sort(b)), ...
                'ASCT:Flanker:UnpairedSubjects', ...
                'DC%d and DC%d have different subject IDs (modality %s)', ...
                pair(1),pair(2),modalities{m});
        end
    end
end
fprintf('Flanker ROI preflight passed: source=%s, %d DC, %d modality.\n', ...
    base,nDC,numel(modalities));
end
