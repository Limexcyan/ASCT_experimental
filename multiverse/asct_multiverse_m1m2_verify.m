function report=asct_multiverse_m1m2_verify(expFolder,outputName)
%ASCT_MULTIVERSE_M1M2_VERIFY Real Flanker pilot, STEP8 -> 9 -> 10.
% This function does not execute the pipeline. It verifies 4 completed
% variants, independent localization, and actual cached ROI reuse.
if nargin<1 || isempty(expFolder)
    expFolder='/mnt/devv/Exp/LG/wprawki/flanker';
end
if nargin<2 || isempty(outputName)
    outputName='ana1_mv_flanker_m1_m2_v1';
end
root=fullfile(char(expFolder),[char(outputName) '__multiverse']);
saved=load(fullfile(root,'realdata_results.mat'),'results','specs');
assert(isfield(saved,'results') && numel(saved.results)==4, ...
    'ASCT:M2:IncompletePilot','Expected 4 saved configurations');
r=saved.results;
assert(all(strcmp({r.status},'passed')) && ...
    all(strcmp({r.connectivityStatus},'passed')), ...
    'ASCT:M2:IncompletePilot','All 4 variants must pass STEP10');
assert(isequal([r.executionStartStep],[8 8 10 10]) && ...
    isequal([r.reuseStage],[0 0 9 9]) && ...
    strcmp(r(3).reuseFrom,r(1).analysisName) && ...
    strcmp(r(4).reuseFrom,r(2).analysisName), ...
    'ASCT:M2:WrongReuse','The experiment did not reuse STEP9 in variants 3/4');
report=table('Size',[4 6], ...
    'VariableTypes',{'string','double','double','double','string','double'}, ...
    'VariableNames',{'variant','depthWeight','varNorm','startStep','reuseFrom','connFiles'});
expectedDepth=[0 0.5 0 0.5];
expectedVarNorm=[0 0 1 1];
for i=1:4
    path=fullfile(char(expFolder),r(i).analysisName,'multiverse_setup.mat');
    assert(isfile(path),'ASCT:M2:MissingSetup','Missing run setup: %s',path);
    S=load(path,'runsetup','spec');
    p=S.runsetup;
    assert(strcmp(char(p.rc.analysisName),r(i).analysisName), ...
        'ASCT:M2:WrongSetup','Variant metadata does not match directory');
    assert(p.loc.depthWeight==expectedDepth(i), ...
        'ASCT:M2:WrongDepth','Depth weight mismatch');
    assert(p.con.varNorm==expectedVarNorm(i), ...
        'ASCT:M2:WrongNorm','VAR normalization mismatch');
    if i<=2
        assert(isfield(p.rc,'multiverseIsolatedLeadfield') && ...
            p.rc.multiverseIsolatedLeadfield && p.loc.force_lf==1, ...
            'ASCT:M2:SharedLeadfield','STEP8 was not isolated');
    else
        assert(strcmp(p.rc.sigroiName,r(i).reuseFrom), ...
            'ASCT:M2:WrongReuse','STEP10 did not use the donor ROI');
    end
    validated=asct_multiverse_verify_artifacts(p);
    report.variant(i)=string(r(i).analysisName);
    report.depthWeight(i)=p.loc.depthWeight;
    report.varNorm(i)=p.con.varNorm;
    report.startStep(i)=p.rc.load;
    report.reuseFrom(i)=string(r(i).reuseFrom);
    report.connFiles(i)=validated.connFiles;
end
writetable(report,fullfile(root,'m1_m2_integration_report.csv'));
fprintf('M1 + M2 INTEGRATION PASSED: 4 variants; donor ROI reused in 2 variants.\n');
disp(report);
end
