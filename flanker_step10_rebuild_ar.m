function files = flanker_step10_rebuild_ar(expFolder, outputName, sourceAnalysis, conName)
%FLANKER_STEP10_REBUILD_AR Recompute AR_summary without recalculating STEP10.
% Before rebuilding each report, make a one-time .before_hotfix.bak copy.
% To repair the previously completed two-variant pilot:
%   flanker_step10_rebuild_ar
if nargin<1 || isempty(expFolder), expFolder='/mnt/devv/Exp/LG/wprawki/flanker'; end
if nargin<2 || isempty(outputName), outputName='ana1_mv_flanker_alpha_v1'; end
if nargin<3 || isempty(sourceAnalysis), sourceAnalysis='ana1'; end
if nargin<4 || isempty(conName), conName='FPN_300_600'; end
expFolder=char(expFolder); outputName=char(outputName);
sourceAnalysis=char(sourceAnalysis); conName=char(conName);
manifest=fullfile(expFolder,[outputName '__multiverse'],'realdata_manifest.csv');
assert(isfile(manifest),'ASCT:ARHotfix:MissingManifest','Missing %s',manifest);
T=readtable(manifest,'TextType','string');
assert(all(ismember({'analysisName','connectivityStatus'}, ...
    T.Properties.VariableNames)),'ASCT:ARHotfix:Manifest','Invalid manifest');
assert(all(strcmpi(string(T.connectivityStatus),'passed')), ...
    'ASCT:ARHotfix:Incomplete','All connectivity runs must be completed first');
files=strings(height(T),1);
for k=1:height(T)
    analysisName=char(T.analysisName(k));
    rc=struct('expFolder',expFolder,'analysisName',analysisName, ...
        'sigroiName',sourceAnalysis);
    con=struct('conName',conName);
    csvPath=fullfile(expFolder,analysisName,'8_CONN',conName,'AR_summary.csv');
    if isfile(csvPath)
        backup=[csvPath '.before_hotfix.bak'];
        if ~isfile(backup)
            [ok,msg]=copyfile(csvPath,backup);
            assert(ok,'ASCT:ARHotfix:BackupFailed', ...
                'Cannot back up %s: %s',csvPath,msg);
            fprintf('Backed up %s\n',backup);
        end
    end
    sc_arstat(rc,con);
    assert(isfile(csvPath),'ASCT:ARHotfix:MissingOutput', ...
        'sc_arstat did not create %s',csvPath);
    files(k)=string(csvPath);
end
fprintf('Rebuilt %d AR_summary reports (existing NDTF/STEP11 untouched).\n',height(T));
end
