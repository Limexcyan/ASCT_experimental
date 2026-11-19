% M10 legacy Flanker wide snapshot: READ-ONLY source; output only in HOME.
% Requires installed M10 path and existing M4 STEP9/STEP10 output directories.
% No replay, no change to M4 manifests, no M5 donor registration.
repo=fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo,'multiverse'));
root='/mnt/devv/Exp/LG/wprawki/flanker';
s9='flanker_step0_wide_narrow_m4_v2_step9__mv_0001';
s10='flanker_step0_wide_narrow_m4_v2_step10__mv_0001';
conn=fullfile('8_CONN','FPN_300_600','lc');
roiFiles={}; inputFiles={}; outputFiles={};
for dc=1:2
    roiFiles{end+1}=fullfile('7_SOURCEACT',sprintf('DC%d',dc), ...
        'lc','*sigroi_lc.mat'); %#ok<AGROW>
    inputFiles{end+1}=fullfile(conn,sprintf('DC%d',dc), ...
        '*_mltin.mat'); %#ok<AGROW>
    outputFiles{end+1}=fullfile(conn,sprintf('DC%d',dc), ...
        '*_mltout.mat'); %#ok<AGROW>
end
% Patterns are limited to known stage/condition directories.
% expectedCount=8 prevents silent import of incomplete output.
template=struct('id','','variantId','mv_0001','stage','', ...
    'root','','patterns',{{}},'upstream',{{}}, ...
    'settings',struct(),'expectedCount',0);
stages=repmat(template,1,3);
stages(1).id='step9_roi';stages(1).stage='ROI';
stages(1).root=fullfile(root,s9);stages(1).patterns=roiFiles;
stages(1).settings=struct('mode','lc');stages(1).expectedCount=8;
stages(2).id='step10_mltin';stages(2).stage='CONN_INPUT';
stages(2).root=fullfile(root,s10);stages(2).patterns=inputFiles;
stages(2).upstream={'step9_roi'};stages(2).expectedCount=8;
stages(3).id='step10_mltout';stages(3).stage='CONN_OUTPUT';
stages(3).root=fullfile(root,s10);stages(3).patterns=outputFiles;
stages(3).upstream={'step10_mltin'};stages(3).expectedCount=8;
spec=asct_m10_legacy_spec('flanker_m4_wide','46041b6b', ...
    struct('windowMs',[300 600],'mvarOrder',7,'decimate',2),stages);
out=fullfile(getenv('HOME'),'m10_m4_wide_snapshot');
manifest=asct_m10_snapshot(spec,out); %#ok<NASGU>
rules=struct('artifactId',{},'relativePath',{},'variable',{},'dimensions',{});
for stage=1:3
    artifact=manifest.artifacts(stage);
    for j=1:numel(artifact.files)
        if stage==1
            v='data_sigroi'; d=[1 1];
        elseif stage==2
            v='mltin'; d=[5 NaN];
        else
            v='NDTF'; d=[5 5 100];
        end
        rules(end+1)=struct('artifactId',artifact.id, ...
            'relativePath',artifact.files(j).relativePath, ...
            'variable',v,'dimensions',d); %#ok<AGROW>
    end
end
opts=struct('rules',rules);
report=asct_m10_report(fullfile(out,'snapshot.mat'), ...
    fullfile(getenv('HOME'),'m10_m4_wide_report'),opts);
disp(report);
