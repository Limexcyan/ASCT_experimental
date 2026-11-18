function [plan,specs] = asct_multiverse_plan(setup,mv)
%ASCT_MULTIVERSE_PLAN Build deterministic, read-only real-data execution plan.
% Planning neither creates directories nor assumes donor outputs are complete.
% Cached donors are PROPOSALS; the runner verifies files before using them.
assert(isstruct(setup) && isfield(setup,'rc'), ...
    'ASCT:Multiverse:MissingSetup','Provide an ExSetup struct');
if ~isfield(mv,'maxRuns'), mv.maxRuns=12; end
if ~isfield(mv,'cacheStages'), mv.cacheStages=false; end
specs=asct_multiverse_realdata_grid(mv);
base=setup;
if isfield(mv,'outputName') && ~isempty(mv.outputName)
    base.rc.analysisName=char(mv.outputName);
end
keys=cell(numel(specs),1);
plan=repmat(struct('id','','analysisName','','requiredStartStep',0, ...
    'executionStartStep',0,'reuseFrom','','reuseStage',0,'inputICA2','', ...
    'reason','','stageKey',struct()),numel(specs),1);
for i=1:numel(specs)
    s=specs(i);
    p=base;
    groups=fieldnames(s.changes);
    for g=1:numel(groups)
        f=fieldnames(s.changes.(groups{g}));
        for j=1:numel(f)
            p.(groups{g}).(f{j})=s.changes.(groups{g}).(f{j});
        end
    end
    changedLoc=struct();
    if isfield(s.changes,'loc'), changedLoc=s.changes.loc; end
    % Validate effective settings while planning, before any files are written.
    p.loc=asct_multiverse_validate_localization(p.loc,changedLoc,false,base.loc);
    keys{i}=stageKeys(p,mv.sourceAnalysis);
    plan(i).id=s.id;
    plan(i).analysisName=[char(base.rc.analysisName) '__' s.id];
    plan(i).requiredStartStep=s.startStep;
    plan(i).executionStartStep=s.startStep;
    plan(i).reason='baseline';
    plan(i).stageKey=keys{i};
    if ~mv.cacheStages || s.startStep==10, continue; end
    % Prefer the closest validated upstream product: ROI > ICLOC > ICA2.
    for j=i-1:-1:1
        if isequaln(keys{i}.step9,keys{j}.step9) && ...
                plan(j).executionStartStep<=9
            plan(i).executionStartStep=10;
            plan(i).reuseStage=9;
            plan(i).reuseFrom=plan(j).analysisName;
            plan(i).reason='reconstructed ROI signals';
            break;
        end
    end
    if plan(i).reuseStage~=0, continue; end
    for j=i-1:-1:1
        if isequaln(keys{i}.step8,keys{j}.step8) && ...
                plan(j).executionStartStep<=8
            plan(i).executionStartStep=9;
            plan(i).reuseStage=8;
            plan(i).reuseFrom=plan(j).analysisName;
            plan(i).reason='localized ICA components';
            % STEP8 variants often reuse ICA2 from the original analysis.
            plan(i).inputICA2=char(mv.sourceAnalysis);
            break;
        end
    end
    if plan(i).reuseStage~=0, continue; end
    for j=i-1:-1:1
        if isequaln(keys{i}.step0,keys{j}.step0) && ...
                plan(j).executionStartStep==0
            plan(i).executionStartStep=8;
            plan(i).reuseStage=0;
            plan(i).reuseFrom=plan(j).analysisName;
            plan(i).reason='ICA2 signals';
            break;
        end
    end
end
end

function keys=stageKeys(p,source)
% Keys include upstream pipeline configuration, never run output names.
% Base ExSetup must describe the same baseline as sourceAnalysis.
rc=p.rc;
context=struct('sourceAnalysis',char(source));
for n={'dataRawFolder','dataFormat','mriRawFolder','mriPrefix','mriExt', ...
        'headTemplate','indivHSmodels'}
    if isfield(rc,n{1}), context.(n{1})=rc.(n{1}); end
end
step0=struct('rc',context,'chan',p.chan,'filter',p.filter, ...
    'seg',p.seg,'ar',p.ar,'ica',p.ica,'design',p.design);
step8=struct('step0',step0,'loc',p.loc);
recon=struct();
for n={'decimate','lc','unc'}
    if isfield(p.con,n{1}), recon.(n{1})=p.con.(n{1}); end
end
step9=struct('step8',step8,'reconstruction',recon);
keys=struct('step0',step0,'step8',step8,'step9',step9);
end
