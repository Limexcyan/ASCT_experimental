function report = flanker_step10_audit(expFolder, outputName, sourceAnalysis, conName, saveReports, recoverManifest)
%FLANKER_STEP10_AUDIT Verify REAL ASCT STEP10 multiverse outputs against ROI.
% Reads existing outputs; never calls mmultar / STEP10 / STEP11.
% Optionally writes only into <outputName>__multiverse/step10_audit/.
% recoverManifest (6th arg, default false) is a non-destructive fallback
% for an overwritten/stale run manifest. It rebuilds the RUN LIST from
% individually saved multiverse_setup.mat files. Only a FULL file audit
% can validate the recovered run list. Original manifests stay untouched.
% Examples:
%   flanker_step10_audit
%   flanker_step10_audit('/mnt/devv/Exp/LG/wprawki/flanker', ...
%       'ana1_mv_flanker_alpha_v1','ana1','FPN_300_600')
%
% Checks: expected subjects and filenames in both DCs; NDTF, ARs.V,
% saved varNorm and MVAR order; exact ERP/no-ERP mltin vs source ROI;
% AR_summary completeness. Pairwise comparisons vary ONE factor at a time.
if nargin<1 || isempty(expFolder), expFolder='/mnt/devv/Exp/LG/wprawki/flanker'; end
if nargin<2 || isempty(outputName), outputName='ana1_mv_flanker_step10_v2'; end
if nargin<3 || isempty(sourceAnalysis), sourceAnalysis='ana1'; end
if nargin<4 || isempty(conName), conName='FPN_300_600'; end
if nargin<5 || isempty(saveReports), saveReports=true; end
if nargin<6 || isempty(recoverManifest), recoverManifest=false; end
assert(islogical(recoverManifest) && isscalar(recoverManifest), ...
    'ASCT:Audit:RecoveryFlag', 'recoverManifest must be logical scalar');
expFolder=char(expFolder); outputName=char(outputName);
sourceAnalysis=char(sourceAnalysis); conName=char(conName);
% ERP helper lives in the ASCT feature branch's multiverse folder.
addpath(fullfile(fileparts(mfilename('fullpath')),'multiverse'));
root=fullfile(expFolder,[outputName '__multiverse']);
manifestPath=fullfile(root,'realdata_manifest.csv');
if recoverManifest
    % A blocked second run can overwrite the original manifest, leaving
    % only the failed first variant and blank/pending remaining rows.
    % Never forge "passed" statuses or overwrite the execution record.
    manifest=reconstructRuns(expFolder,outputName,sourceAnalysis,conName,manifestPath);
    fprintf('RECOVERY MODE: auditing %d saved variant folders; original manifest UNCHANGED.\n',height(manifest));
else
    assert(isfile(manifestPath),'ASCT:Audit:MissingManifest', ...
        'Cannot find manifest: %s',manifestPath);
    % Force CSV header interpretation for short text-only manifests.
    manifest=readtable(manifestPath,'FileType','text','Delimiter',',', ...
        'ReadVariableNames',true,'VariableNamingRule','preserve', ...
        'TextType','string');
    required={'configId','analysisName','connectivityStatus'};
    if ~all(ismember(required,manifest.Properties.VariableNames))
        observed=strjoin(string(manifest.Properties.VariableNames),', ');
        fid=fopen(manifestPath,'r');
        firstLine='(unavailable)';
        if fid>=0, firstLine=fgetl(fid); fclose(fid); end
        error('ASCT:Audit:ManifestColumns', ...
            'Manifest missing columns. Observed: [%s]; first line: %s', ...
            char(observed),char(string(firstLine)));
    end
    assert(height(manifest)>0,'ASCT:Audit:EmptyManifest','Empty manifest');
    assert(all(strcmpi(string(manifest.connectivityStatus),'passed')), ...
        'ASCT:Audit:IncompleteRun','Some STEP10 runs have not passed');
end
assert(numel(unique(string(manifest.analysisName)))==height(manifest), ...
    'ASCT:Audit:DuplicateRun','Duplicate analysisName in manifest');

% Per-file metrics. Keep dataset identity rather than parsing condition
% suffix with underscores (FLANK_INCO, FLANK_CONG).
rows=cell(0,16);
cfg=repmat(struct('analysisName','','varNorm',NaN,'orderSelection','', ...
    'removeERP',false,'nDC',0,'nParticipants',0),height(manifest),1);
fileSets=cell(height(manifest),2);
for vi=1:height(manifest)
    analysisName=char(manifest.analysisName(vi));
    runFolder=fullfile(expFolder,analysisName);
    metadata=fullfile(runFolder,'multiverse_setup.mat');
    assert(isfile(metadata),'ASCT:Audit:MissingSetup','Missing %s',metadata);
    M=load(metadata,'runsetup','spec');
    assert(isfield(M,'runsetup') && isfield(M,'spec'), ...
        'ASCT:Audit:MissingSetup','runsetup/spec missing in %s',metadata);
    p=M.runsetup;
    assert(strcmp(char(p.rc.analysisName),analysisName), ...
        'ASCT:Audit:SetupMismatch','runsetup mismatch in %s',metadata);
    assert(strcmp(char(p.rc.sigroiName),sourceAnalysis), ...
        'ASCT:Audit:SourceMismatch','Unexpected source analysis in %s',metadata);
    assert(isfield(p.con,'lc') && logical(p.con.lc) && ...
        isfield(p.con,'unc') && ~logical(p.con.unc), ...
        'ASCT:Audit:Modality','This Flanker audit expects lc=1, unc=0');
    assert(strcmp(char(p.con.conName),conName), ...
        'ASCT:Audit:ConName','Connection name mismatch in %s',metadata);
    assert(isfield(p.design,'DC') && numel(p.design.DC)==2, ...
        'ASCT:Audit:Design','Expected two Flanker DC conditions');
    varNorm=double(p.con.varNorm);
    assert(ismember(varNorm,[0 1]),'ASCT:Audit:VarNorm','Invalid varNorm');
    if ~isfield(p.con,'orderSelection'), p.con.orderSelection='fixed'; end
    orderMode=lower(char(p.con.orderSelection));
    assert(ismember(orderMode,{'fixed','aic'}), ...
        'ASCT:Audit:OrderSelection','Unknown orderSelection: %s',orderMode);
    rmERP=isfield(p.con,'removeERP') && logical(p.con.removeERP);
    cfg(vi).analysisName=analysisName;
    cfg(vi).varNorm=varNorm;
    cfg(vi).orderSelection=orderMode;
    cfg(vi).removeERP=rmERP;
    cfg(vi).nDC=2;
    fprintf('\nRUN %d/%d %s | varNorm=%d order=%s removeERP=%d\n', ...
        vi,height(manifest),analysisName,varNorm,orderMode,rmERP);
    ids=cell(1,2);
    for dc=1:2
        inDir=fullfile(expFolder,sourceAnalysis,'7_SOURCEACT', ...
            sprintf('DC%d',dc),'lc');
        files=dir(fullfile(inDir,'*_sigroi_lc.mat'));
        [~,ord]=sort({files.name}); files=files(ord);
        assert(~isempty(files),'ASCT:Audit:MissingROI','No ROI files in %s',inDir);
        if isfield(p,'begId') && isfield(p,'endId') && ...
                p.begId>0 && p.endId>0
            assert(numel(files)>=p.endId && p.begId<=p.endId, ...
                'ASCT:Audit:InputRange','Invalid data range in %s',inDir);
            files=files(p.begId:p.endId);
        end
        outDir=fullfile(runFolder,'8_CONN',conName,'lc',sprintf('DC%d',dc));
        actual=dir(fullfile(outDir,'*_mltout.mat'));
        actualNames=sort(string({actual.name}));
        expectedNames=strings(1,numel(files));
        ids{dc}=cell(1,numel(files));
        for fi=1:numel(files)
            roiPath=fullfile(inDir,files(fi).name);
            inp=load(roiPath,'data_sigroi');
            assert(isfield(inp,'data_sigroi') && isstruct(inp.data_sigroi), ...
                'ASCT:Audit:ROIContent','Invalid data_sigroi in %s',roiPath);
            condNames=fieldnames(inp.data_sigroi);
            assert(numel(condNames)==1,'ASCT:Audit:ROIContent', ...
                'Expected exactly one condition in %s',roiPath);
            sig=inp.data_sigroi.(condNames{1});
            assert(isstruct(sig) && isfield(sig,'signal') && ...
                isfield(sig,'trialen') && isnumeric(sig.signal) && ...
                ismatrix(sig.signal) && all(isfinite(sig.signal(:))), ...
                'ASCT:Audit:ROIContent','Invalid source ROI data: %s',roiPath);
            tl=double(sig.trialen);
            assert(isscalar(tl) && tl>1 && tl==fix(tl) && ...
                mod(size(sig.signal,2),tl)==0, ...
                'ASCT:Audit:TrialLength','Invalid trial length: %s',roiPath);
            nTrials=size(sig.signal,2)/tl;
            base=regexprep(files(fi).name,'_sigroi_lc\.mat$','');
            expectedNames(fi)=string([base '_' condNames{1} '_mltout.mat']);
            assert(numel(base)>=p.design.idPosEnd, ...
                'ASCT:Audit:SubjectId','Source basename too short: %s',base);
            ids{dc}{fi}=base(p.design.idPosStart:p.design.idPosEnd);
            outputPath=fullfile(outDir,char(expectedNames(fi)));
            assert(isfile(outputPath),'ASCT:Audit:MissingOutput', ...
                'Missing connectivity file %s',outputPath);
            o=load(outputPath,'NDTF','ARs','mv');
            assert(isfield(o,'NDTF') && isnumeric(o.NDTF) && ...
                ndims(o.NDTF)==3 && size(o.NDTF,1)==size(sig.signal,1) && ...
                size(o.NDTF,2)==size(sig.signal,1) && ...
                all(isfinite(o.NDTF(:))), ...
                'ASCT:Audit:InvalidNDTF','Invalid NDTF: %s',outputPath);
            assert(isfield(o,'ARs') && isstruct(o.ARs) && ...
                isfield(o.ARs,'V') && isnumeric(o.ARs.V) && ...
                isequal(size(o.ARs.V),[size(sig.signal,1),size(sig.signal,1)]) && ...
                all(isfinite(o.ARs.V(:))), ...
                'ASCT:Audit:InvalidCov','Invalid ARs.V: %s',outputPath);
            assert(isfield(o,'mv') && isfield(o.mv,'pord') && ...
                isfield(o.mv,'norm1'), ...
                'ASCT:Audit:MissingMVAR','Missing saved MVAR parameters: %s',outputPath);
            order=double(o.mv.pord);
            assert(isscalar(order) && isfinite(order) && order>=1 && order==fix(order), ...
                'ASCT:Audit:InvalidOrder','Invalid model order: %s',outputPath);
            assert(isequal(double(o.mv.norm1),varNorm), ...
                'ASCT:Audit:WrongVarNorm','norm1 inconsistent: %s',outputPath);
            % Independently inspect the fitted VAR coefficients, not only
            % the saved pord. A finite NDTF alone does not prove stability.
            assert(isfield(o.ARs,'coefs') && isnumeric(o.ARs.coefs) && ...
                size(o.ARs.coefs,1)==size(sig.signal,1) && ...
                size(o.ARs.coefs,2)==size(sig.signal,1) && ...
                size(o.ARs.coefs,3)==order && all(isfinite(o.ARs.coefs(:))), ...
                'ASCT:Audit:InvalidCoefficients', ...
                'Missing/invalid MVAR coefficients: %s',outputPath);
            nroi=size(sig.signal,1);
            companion=zeros(nroi*order);
            companion(1:nroi,:)=reshape(double(o.ARs.coefs),nroi,[]);
            if order>1
                companion(nroi+1:end,1:nroi*(order-1))=eye(nroi*(order-1));
            end
            spectralRadius=max(abs(eig(companion)));
            isStable=spectralRadius<1;
            V=double(o.ARs.V);
            minCovEigen=min(real(eig((V+V')/2)));
            assert(minCovEigen>=-1e-7*max(norm(V,'fro'),1e-12), ...
                'ASCT:Audit:InvalidCov', ...
                'Negative residual covariance eigenvalue: %s',outputPath);
            if ~isStable
                warning('ASCT:Audit:UnstableMVAR', ...
                    'MVAR spectral radius %.6g >= 1 for %s',spectralRadius,outputPath);
            end
            if strcmp(orderMode,'fixed')
                assert(order==p.con.mvarOrd,'ASCT:Audit:WrongOrder', ...
                    'Expected fixed order %d, got %d: %s',p.con.mvarOrd,order,outputPath);
            else
                assert(order<=p.con.maxMvarOrder,'ASCT:Audit:WrongOrder', ...
                    'AIC order exceeds maxMvarOrder: %s',outputPath);
            end
            inMLT=fullfile(outDir,strrep(char(expectedNames(fi)),'_mltout.mat','_mltin.mat'));
            assert(isfile(inMLT),'ASCT:Audit:MissingMLTin','Missing %s',inMLT);
            m=load(inMLT,'mltin');
            assert(isfield(m,'mltin') && isequal(size(m.mltin),size(sig.signal)) && ...
                all(isfinite(m.mltin(:))), ...
                'ASCT:Audit:MLTinContent','Invalid mltin in %s',inMLT);
            if rmERP
                expected=asct_remove_erp(sig.signal,tl);
            else
                expected=sig.signal;
            end
            maxDiff=max(abs(double(m.mltin(:))-double(expected(:))));
            signalScale=max([max(abs(double(sig.signal(:)))),1e-12]);
            assert(maxDiff<=5e-10*signalScale, ...
                'ASCT:Audit:ERPInputMismatch', ...
                'mltin does not match removeERP=%d (max deviation %.8g): %s', ...
                rmERP,maxDiff,inMLT);
            avgVr=mean(diag(double(o.ARs.V)));
            rows(end+1,:)={string(analysisName),string(ids{dc}{fi}), ...
                string(base),dc,varNorm,string(orderMode),rmERP,order, ...
                nTrials,size(sig.signal,1),size(o.NDTF,3),avgVr,maxDiff, ...
                spectralRadius,isStable,minCovEigen}; %#ok<AGROW>
        end
        assert(isequal(actualNames,sort(expectedNames)), ...
            'ASCT:Audit:ExtraOrMissing','Unexpected STEP10 filenames in %s',outDir);
        assert(numel(unique(string(ids{dc})))==numel(ids{dc}), ...
            'ASCT:Audit:DuplicateId','Repeated subject IDs within DC%d',dc);
        fileSets{vi,dc}=expectedNames;
    end
    assert(isequal(sort(string(ids{1})),sort(string(ids{2}))), ...
        'ASCT:Audit:Unpaired','DC1/DC2 are not paired for %s',analysisName);
    cfg(vi).nParticipants=numel(ids{1});
    arPath=fullfile(runFolder,'8_CONN',conName,'AR_summary.csv');
    assert(isfile(arPath),'ASCT:Audit:MissingARSummary', ...
        'Missing %s (apply sc_arstat.m hotfix then regenerate)',arPath);
    ar=readtable(arPath, 'FileType','text','Delimiter',',', ...
        'ReadVariableNames',true,'VariableNamingRule','preserve', ...
        'TextType','string');
    assert(height(ar)==numel(ids{1})+numel(ids{2}) && ...
        all(ismember({'Subject','DC','nTrials','avgVr'},ar.Properties.VariableNames)), ...
        'ASCT:Audit:BadARSummary', ...
        'AR_summary needs %d complete rows in %s; apply hotfix v2', ...
        numel(ids{1})+numel(ids{2}),arPath);
    assert(all(isfinite(ar.nTrials)) && all(isfinite(ar.avgVr)), ...
        'ASCT:Audit:BadARSummary','AR_summary has NaN/Inf in %s',arPath);
    for dc=1:2
        rowsDC=ar(strcmp(string(ar.DC),sprintf('DC%d',dc)),:);
        sourceHere=string(rows(strcmp(string(rows(:,1)),analysisName) & ...
            cell2mat(rows(:,4))==dc,3));
        assert(height(rowsDC)==numel(ids{dc}) && ...
            isequal(sort(string(rowsDC.Subject)),sort(sourceHere)), ...
            'ASCT:Audit:BadARSummary', ...
            'AR_summary subject rows mismatch in %s DC%d',arPath,dc);
        % Match numerical report values back to the actual MAT contents.
        selectedRows=find(strcmp(string(rows(:,1)),analysisName) & ...
            cell2mat(rows(:,4))==dc);
        for ai=1:height(rowsDC)
            match=find(string(rows(selectedRows,3))==string(rowsDC.Subject(ai)));
            assert(numel(match)==1,'ASCT:Audit:BadARSummary', ...
                'Missing or duplicated report dataset %s',string(rowsDC.Subject(ai)));
            ri=selectedRows(match);
            realN=double(rows{ri,9});
            realV=double(rows{ri,12});
            csvV=double(rowsDC.avgVr(ai));
            tolerance=max(1e-12,1e-8*abs(realV));
            assert(double(rowsDC.nTrials(ai))==realN && ...
                abs(csvV-realV)<=tolerance, ...
                'ASCT:Audit:BadARSummary', ...
                'AR_summary values disagree with ROI/ARs.V for %s DC%d', ...
                string(rowsDC.Subject(ai)),dc);
        end
    end
    fprintf('  verified %d participants x 2 DC, NDTF, MVAR order, ERP input, AR_summary\n', ...
        cfg(vi).nParticipants);
end

perFile=cell2table(rows,'VariableNames',{'analysisName','subjectId','dataset', ...
    'DC','varNorm','orderSelection','removeERP','selectedOrder','nTrials', ...
    'nROI','nFreq','avgResidualVariance','maxInputDeviation', ...
    'mvarSpectralRadius','mvarStable','minResidualEigenvalue'});
perFile.analysisName=string(perFile.analysisName);
perFile.subjectId=string(perFile.subjectId);
perFile.dataset=string(perFile.dataset);
perFile.orderSelection=string(perFile.orderSelection);
for f={'DC','varNorm','selectedOrder','nTrials','nROI','nFreq', ...
        'avgResidualVariance','maxInputDeviation','mvarSpectralRadius', ...
        'minResidualEigenvalue'}
    col=perFile.(f{1});
    if iscell(col), col=cell2mat(col); end
    perFile.(f{1})=double(col);
end
col=perFile.removeERP;
if iscell(col), col=cell2mat(col); end
perFile.removeERP=logical(col);
col=perFile.mvarStable;
if iscell(col), col=cell2mat(col); end
perFile.mvarStable=logical(col);

% Compare ONE-factor-at-a-time pairs; do not require differences to be > 0:
% normalized network quantities can be invariant under some scalings.
pairs=cell(0,6);
for ia=1:numel(cfg)
    for ib=ia+1:numel(cfg)
        differences=[cfg(ia).varNorm~=cfg(ib).varNorm, ...
            ~strcmp(cfg(ia).orderSelection,cfg(ib).orderSelection), ...
            cfg(ia).removeERP~=cfg(ib).removeERP];
        if nnz(differences)~=1, continue; end
        labels={'varNorm','orderSelection','removeERP'};
        changed=labels{find(differences,1)};
        absSum=0; numValues=0; maxValue=0; nFiles=0;
        for dc=1:2
            assert(isequal(fileSets{ia,dc},fileSets{ib,dc}), ...
                'ASCT:Audit:DifferentDatasets','Variant comparison has different data');
            for fi=1:numel(fileSets{ia,dc})
                fname=char(fileSets{ia,dc}(fi));
                aPath=fullfile(expFolder,cfg(ia).analysisName,'8_CONN',conName, ...
                    'lc',sprintf('DC%d',dc),fname);
                bPath=fullfile(expFolder,cfg(ib).analysisName,'8_CONN',conName, ...
                    'lc',sprintf('DC%d',dc),fname);
                a=load(aPath,'NDTF'); b=load(bPath,'NDTF');
                assert(isequal(size(a.NDTF),size(b.NDTF)), ...
                    'ASCT:Audit:ShapeMismatch','NDTF dimensions differ: %s',fname);
                dd=abs(double(a.NDTF(:))-double(b.NDTF(:)));
                absSum=absSum+sum(dd); numValues=numValues+numel(dd);
                maxValue=max(maxValue,max(dd)); nFiles=nFiles+1;
            end
        end
        pairs(end+1,:)={string(cfg(ia).analysisName),string(cfg(ib).analysisName), ...
            string(changed),maxValue,absSum/numValues,nFiles}; %#ok<AGROW>
        fprintf('COMPARE %s vs %s [%s]: max|dNDTF|=%.9g mean|dNDTF|=%.9g\n', ...
            cfg(ia).analysisName,cfg(ib).analysisName,changed,maxValue,absSum/numValues);
    end
end
if isempty(pairs)
    pairwise=table('Size',[0 6], ...
        'VariableTypes',{'string','string','string','double','double','double'}, ...
        'VariableNames',{'variantA','variantB','changedFactor', ...
        'maxAbsNDTF','meanAbsNDTF','nFiles'});
else
    pairwise=cell2table(pairs,'VariableNames',{'variantA','variantB', ...
        'changedFactor','maxAbsNDTF','meanAbsNDTF','nFiles'});
    for f={'variantA','variantB','changedFactor'}
        pairwise.(f{1})=string(pairwise.(f{1}));
    end
    for f={'maxAbsNDTF','meanAbsNDTF','nFiles'}
        col=pairwise.(f{1});
        if iscell(col), col=cell2mat(col); end
        pairwise.(f{1})=double(col);
    end
end
report=struct('perFile',perFile,'pairwise',pairwise,'configuration',cfg, ...
    'recoveredFromSavedSetups',logical(recoverManifest), ...
    'originalManifestPath',string(manifestPath));
if saveReports
    auditFolder=fullfile(root,'step10_audit');
    if ~isfolder(auditFolder), mkdir(auditFolder); end
    writetable(perFile,fullfile(auditFolder,'step10_per_file.csv'));
    writetable(pairwise,fullfile(auditFolder,'step10_pairwise_ndtf.csv'));
    save(fullfile(auditFolder,'step10_audit.mat'),'report');
    if recoverManifest
        recovered=manifest;
        recovered.connectivityStatus(:)="audited_from_files";
        writetable(recovered,fullfile(auditFolder,'recovered_manifest_audited.csv'));
        fprintf('Original execution manifest was NOT changed: %s\n',manifestPath);
    end
    fprintf('Saved audit CSV/MAT in %s\n',auditFolder);
end
fprintf('STEP10 AUDIT PASSED: %d variants, %d verified outputs, %d one-factor comparisons\n', ...
    numel(cfg),height(perFile),height(pairwise));
end

function manifest=reconstructRuns(expFolder,outputName,sourceAnalysis,conName,manifestPath)
% Rebuild candidate run list only from individual, independently saved
% run metadata. This is NOT a reconstruction of the execution history.
expectedCount=NaN;
if isfile(manifestPath)
    previous=readtable(manifestPath,'FileType','text','Delimiter',',', ...
        'ReadVariableNames',true,'VariableNamingRule','preserve','TextType','string');
    expectedCount=height(previous);
end
candidates=dir(fullfile(expFolder,[outputName '__mv_*']));
candidates=candidates([candidates.isdir]);
pattern=['^' regexptranslate('escape',outputName) '__mv_[0-9]{4}$'];
valid=false(numel(candidates),1);
for i=1:numel(candidates)
    valid(i)=~isempty(regexp(candidates(i).name,pattern,'once'));
end
candidates=candidates(valid);
names=sort(string({candidates.name}));
assert(~isempty(names),'ASCT:Audit:RecoveryNoRuns', ...
    'No variant directories for %s',outputName);
if isfinite(expectedCount)
    assert(numel(names)==expectedCount, 'ASCT:Audit:RecoveryCount', ...
        'Found %d variant folders, but damaged manifest expects %d runs', ...
        numel(names),expectedCount);
end
configId=strings(numel(names),1);
analysisName=strings(numel(names),1);
connectivityStatus=repmat("unverified_from_saved_setup",numel(names),1);
for i=1:numel(names)
    target=string(sprintf('%s__mv_%04d',outputName,i));
    assert(names(i)==target,'ASCT:Audit:RecoveryGap', ...
        'Nonconsecutive variant directories: expected %s, found %s', ...
        char(target),char(names(i)));
    configId(i)=string(sprintf('mv_%04d',i));
    analysisName(i)=names(i);
    setupFile=fullfile(expFolder,char(names(i)),'multiverse_setup.mat');
    assert(isfile(setupFile),'ASCT:Audit:RecoveryMissingSetup', ...
        'Missing original configuration file: %s',setupFile);
    M=load(setupFile,'runsetup','spec');
    assert(isfield(M,'runsetup') && isfield(M,'spec') && ...
        isfield(M.runsetup,'rc') && isfield(M.runsetup.rc,'analysisName') && ...
        isfield(M.runsetup.rc,'sigroiName') && isfield(M.runsetup,'con') && ...
        isfield(M.runsetup.con,'conName') && isfield(M.spec,'id') && ...
        strcmp(char(M.spec.id),char(configId(i))) && ...
        strcmp(char(M.runsetup.rc.analysisName),char(analysisName(i))) && ...
        strcmp(char(M.runsetup.rc.sigroiName),sourceAnalysis) && ...
        strcmp(char(M.runsetup.con.conName),conName), ...
        'ASCT:Audit:RecoverySetupMismatch', ...
        'Saved variant metadata is inconsistent: %s',setupFile);
end
manifest=table(configId,analysisName,connectivityStatus);
end
