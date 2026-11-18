function summary = asct_multiverse_check_conn(p)
%ASCT_MULTIVERSE_CHECK_CONN Guard STEP11 against missing connectivity files.
% Requires at least one *_mltout.mat for every requested DC and signal type.
% Does not declare statistical significance or verify subject pairing.
assert(isfield(p.con,'conName') && isfield(p.con,'contrast2test'), ...
    'ASCT:RealMultiverse:MissingStatInputs', ...
    'Statistics require con.conName and con.contrast2test');
selected=[];
for k=1:numel(p.con.contrast2test)
    pair=p.con.contrast2test{k};
    assert(isnumeric(pair) && numel(pair)==2 && all(pair>=1) && ...
        all(pair==fix(pair)), 'ASCT:RealMultiverse:InvalidContrast', ...
        'contrast2test entries must be positive integer pairs');
    selected=[selected pair(:)']; %#ok<AGROW>
end
selected=unique(selected);
mods={};
if ~isfield(p.con,'lc') || p.con.lc, mods{end+1}='lc'; end
if isfield(p.con,'unc') && p.con.unc, mods{end+1}='unc'; end
assert(~isempty(mods),'ASCT:RealMultiverse:MissingStatInputs', ...
    'Neither lc nor unc is enabled');
summary=struct('directory',{},'nFiles',{});
for m=1:numel(mods)
    for dc=selected
        directory=fullfile(p.rc.expFolder,p.rc.analysisName, ...
            '8_CONN',p.con.conName,mods{m},sprintf('DC%d',dc));
        files=dir(fullfile(directory,'*mltout.mat'));
        assert(~isempty(files), 'ASCT:RealMultiverse:MissingStatInputs', ...
            'No *_mltout.mat files in %s (STEP10 missing or incomplete)',directory);
        summary(end+1)=struct('directory',directory,'nFiles',numel(files)); %#ok<AGROW>
    end
end
end
