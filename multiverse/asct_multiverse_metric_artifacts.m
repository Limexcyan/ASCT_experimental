function values = asct_multiverse_metric_artifacts(runsetup,~,ctx)
%ASCT_MULTIVERSE_METRIC_ARTIFACTS Built-in operational metric plugin.
% Counts saved files; this is an infrastructure metric, NOT a scientific
% connectivity quality score. All reads are read-only.
con=runsetup.con;
rc=runsetup.rc;
assert(isfield(con,'conName'),'ASCT:Metrics:MissingConName', ...
    'Missing con.conName in saved setup');
conn=dir(fullfile(ctx.analysisFolder,'8_CONN',char(con.conName), ...
    '**','*_mltout.mat'));
source=rc.analysisName;
if isfield(rc,'sigroiName') && ~isempty(rc.sigroiName)
    source=rc.sigroiName;
end
sigroi=fullfile(char(rc.expFolder),char(source),'7_SOURCEACT');
roi=dir(fullfile(sigroi,'DC*','*','*_sigroi_*.mat'));
icloc=dir(fullfile(ctx.analysisFolder,'7_SOURCEACT','icloc','*icloc.mat'));
values=struct('connectivityFiles',numel(conn), ...
    'connectivityBytes',sum([conn.bytes]), ...
    'roiFilesAvailable',numel(roi), ...
    'iclocFilesInVariant',numel(icloc));
end
