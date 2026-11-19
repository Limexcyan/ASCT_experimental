function sc_arstat(rc, con)


% Saves a combined report on no of trials and the mean of AR model residual variance:
%   - nTrials        from <rc.expFolder>/<rc.analysisName>/7_SOURCEACT/
%                         DC*/lc/*_sigroi_lc.mat
%   - avgVr      from <rc.expFolder>/<rc.analysisName>/8_CONN/
%                         <con.conName>/lc/DC*/*_mltout.mat
%   Discovers all DC* folders automatically.
%   Output: <rc.expFolder>/<rc.analysisName>/8_CONN/<con.conName>/
%               AR_summary.csv


% fprintf('rc.expFolder    = %s\n', rc.expFolder);
% fprintf('rc.analysisName = %s\n', rc.analysisName);
% fprintf('con.conName     = %s\n', con.conName);

disp([newline 'preparing AR statistics....' newline])

% --- Paths ---
trialRoot = fullfile(rc.expFolder, rc.analysisName, '7_SOURCEACT');
% STEP10-only multiverse stores ROI signals in the source analysis.
if isfield(rc,'sigroiName') && ~isempty(rc.sigroiName)
    trialRoot = fullfile(rc.expFolder, rc.sigroiName, '7_SOURCEACT');
end
covRoot   = fullfile(rc.expFolder, rc.analysisName, '8_CONN', ...
    con.conName, 'lc');
outDir    = fullfile(rc.expFolder, rc.analysisName, '8_CONN', con.conName);
if ~exist(outDir, 'dir'), mkdir(outDir); end
outCSV = fullfile(outDir, 'AR_summary.csv');

fprintf('Trial root:      %s\n', trialRoot);
fprintf('Covariance root: %s\n', covRoot);

% =====================================================================
% TASK A: trial counts from 7_SOURCEACT/DC*/lc/*_sigroi_lc.mat
% =====================================================================
fprintf('\n--- Scanning %s for trial counts ---\n', trialRoot);

trialFiles = dir(fullfile(trialRoot, 'DC*', 'lc', '*_sigroi_lc.mat'));
fprintf('  Found %d file(s)\n', numel(trialFiles));

nT = numel(trialFiles);
subT    = strings(nT,1);
dcT     = strings(nT,1);
fileT   = strings(nT,1);
nTrials = nan(nT,1);
keepT   = false(nT,1);

for i = 1:nT
    fpath = fullfile(trialFiles(i).folder, trialFiles(i).name);

    [parentOfLc, ~] = fileparts(trialFiles(i).folder);
    [~, dcName]     = fileparts(parentOfLc);
    dcT(i) = string(dcName);

    tok = regexp(trialFiles(i).name, '^(.*)_sigroi_lc\.mat$', ...
        'tokens', 'once');
    if ~isempty(tok), subT(i) = string(tok{1}); else, subT(i) = "unknown"; end
    fileT(i) = string(trialFiles(i).name);

    try
        S = load(fpath);
        if ~isfield(S, 'data_sigroi'), continue; end
        ds = S.data_sigroi;

        % Find the condition subfield that has .signal and .trialen
        subFields = fieldnames(ds);
        mul = [];
        for k = 1:numel(subFields)
            if isstruct(ds.(subFields{k})) && ...
                    isfield(ds.(subFields{k}), 'signal') && ...
                    isfield(ds.(subFields{k}), 'trialen')
                mul = ds.(subFields{k});
                break;
            end
        end
        if isempty(mul), continue; end

        tl = double(mul.trialen);
        if tl <= 0, continue; end

        nTrials(i) = size(mul.signal, 2) / tl;
        keepT(i)   = true;

    catch
        continue;
    end
end

% Dedup (Subject, DC) — take first occurrence
keyT  = subT + "|" + dcT;
keepT = dedupKeepSimple(keyT, keepT);

% =====================================================================
% TASK B: avgVr from 8_CONN/<con.conName>/lc/DC*/*_mltout.mat
% =====================================================================
fprintf('\n--- Scanning %s for residual covariance diagonals ---\n', covRoot);

if ~exist(covRoot, 'dir')
    error('Covariance root does not exist: %s', covRoot);
end

dcDirs = dir(fullfile(covRoot, 'DC*'));
dcDirs = dcDirs([dcDirs.isdir]);
fprintf('  Found %d DC folder(s): %s\n', numel(dcDirs), ...
    strjoin({dcDirs.name}, ', '));

covFiles = [];
for d = 1:numel(dcDirs)
    f = dir(fullfile(covRoot, dcDirs(d).name, '*_mltout.mat'));
    covFiles = [covFiles; f]; %#ok<AGROW>
end
fprintf('  Total covariance files: %d\n', numel(covFiles));

nC = numel(covFiles);
subC  = strings(nC,1);
dcC   = strings(nC,1);
winC  = strings(nC,1);
fileC = strings(nC,1);
avgD  = nan(nC,1);
keepC = false(nC,1);

for i = 1:nC
    fpath = fullfile(covFiles(i).folder, covFiles(i).name);

    [~, dcName] = fileparts(covFiles(i).folder);
    dcC(i)  = string(dcName);
    winC(i) = string(con.conName);

    % Filename: <subject>_<condition>_mltout.mat
    % Output file: <dataset>_<condition>_mltout.mat. Flanker condition
    % FLANK_INCO contains an underscore, so splitting on the LAST
    % underscore would truncate the dataset ID incorrectly. Match against
    % known baseline ROI dataset stems for this DC instead.
    base = string(regexprep(covFiles(i).name, '_mltout\.mat$', ''));
    % startsWith(base, patternArray) returns ONE scalar indicating whether
    % ANY pattern matches. Pairing it with a vector of DC labels would
    % incorrectly select the first subject (typically A1) for every file.
    % Compare each ROI stem individually to preserve the correct subject ID.
    withinDC = find(dcT == dcC(i) & keepT);
    candidates = zeros(0,1);
    for ci = reshape(withinDC,1,[])
        if startsWith(base, subT(ci) + "_")
            candidates(end+1,1) = ci; %#ok<AGROW>
        end
    end
    if ~isempty(candidates)
        [~,longest] = max(strlength(subT(candidates)));
        subC(i) = subT(candidates(longest));
    else
        % Legacy fallback when the original ROI file is not available.
        tok = regexp(char(base), '^(.*)_(stay|shift)_([^_]+)$', 'tokens', 'once');
        if ~isempty(tok)
            subC(i) = string(tok{1});
        else
            und = find(char(base) == '_', 1, 'last');
            if ~isempty(und)
                subC(i) = extractBefore(base,und);
            else
                subC(i) = base;
            end
        end
    end
    fileC(i) = string(covFiles(i).name);

    try
        S = load(fpath);
        if ~isfield(S, 'ARs') || ~isfield(S.ARs, 'V') || isempty(S.ARs.V)
            continue;
        end
        V = S.ARs.V;
        if ~ismatrix(V) || size(V,1) ~= size(V,2), continue; end
        avgD(i)  = mean(diag(V));
        keepC(i) = true;
    catch
        continue;
    end
end

keyC  = subC + "|" + dcC;
keepC = dedupKeepSimple(keyC, keepC);

% =====================================================================
% Merge A and B on (Subject, DC)
% =====================================================================
A = table(subT(keepT), dcT(keepT), nTrials(keepT), ...
    'VariableNames', {'Subject','DC','nTrials'});

B = table(subC(keepC), winC(keepC), dcC(keepC), avgD(keepC), ...
    'VariableNames', {'Subject','Window','DC','avgVr'});

T = outerjoin(B, A, 'Keys', {'Subject','DC'}, ...
    'MergeKeys', true, 'Type', 'left');

T = T(:, {'Subject','Window','DC','nTrials','avgVr'});
T = sortrows(T, {'Window','Subject','DC'});

% Preserve full precision in CSV: raw ROI residual variance may be
% much smaller than 0.005, so rounding to two decimals would make it 0.
if nnz(keepC) ~= nC
    warning('ASCT:ARSummary:MissingCovariance', ...
        'Only %d/%d connectivity files contain a valid ARs.V matrix.', nnz(keepC), nC);
end
if height(T) ~= nnz(keepC)
    warning('ASCT:ARSummary:UnexpectedRows', ...
        'Unexpected report row count: %d rows for %d valid covariance files.', ...
        height(T), nnz(keepC));
end
disp(T);

writetable(T, outCSV);
fprintf('\nSaved: %s\n', outCSV);

end

% Local helper
    function keep = dedupKeepSimple(key, keep)
        keepNew  = false(size(keep));
        uniqKeys = unique(key(keep));
        for u = 1:numel(uniqKeys)
            idx = find(key == uniqKeys(u) & keep, 1, 'first');
            if ~isempty(idx)
                keepNew(idx) = true;
            end
        end
        keep = keepNew;
    end

