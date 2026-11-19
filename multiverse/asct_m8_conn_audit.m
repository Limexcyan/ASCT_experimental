function report = asct_m8_conn_audit(multiverseRoot)
%ASCT_M8_CONN_AUDIT Read-only STEP10 audit for an executed real-data grid.
% Validates effective ROI dimensions, order, normalization, coefficient
% stability, covariance, and output labels. NO ground truth on real EEG.
assert(isfolder(multiverseRoot),'ASCT:M8:MissingRoot','Missing multiverse root');
manifestFile=fullfile(multiverseRoot,'realdata_manifest.csv');
assert(isfile(manifestFile),'ASCT:M8:MissingManifest','Missing realdata_manifest.csv');
manifest=readtable(manifestFile,'TextType','string');
needed={'analysisName','configId','status'};
assert(all(ismember(needed,manifest.Properties.VariableNames)), ...
    'ASCT:M8:Manifest','Manifest missing required columns');
expFolder=fileparts(multiverseRoot);
rows={};k=0;
for i=1:height(manifest)
    if ~strcmp(char(manifest.status(i)),'passed'),continue;end
    analysisName=char(manifest.analysisName(i));
    assert(~isempty(regexp(analysisName,'^[A-Za-z0-9_.-]+$','once')), ...
        'ASCT:M8:Manifest','Unsafe analysisName in manifest');
    folder=fullfile(expFolder,analysisName);
    setupFile=fullfile(folder,'multiverse_setup.mat');
    assert(isfile(setupFile),'ASCT:M8:MissingSetup','Missing setup for %s',analysisName);
    p=load(setupFile,'runsetup');
    assert(isfield(p,'runsetup') && isfield(p.runsetup,'con') && ...
        isfield(p.runsetup,'loc'),'ASCT:M8:MissingSetup','Invalid saved runsetup');
    c=p.runsetup.con;
    assert(isfield(c,'conName') && isfield(c,'chanSel') && ...
        isfield(c,'varNorm') && isfield(c,'mvarOrd'), ...
        'ASCT:M8:MissingSetup','Connectivity settings missing');
    nInput=numel(p.runsetup.loc.ROI);
    expected=nSelected(c.chanSel,nInput);
    directory=fullfile(folder,'8_CONN',char(c.conName));
    files=dir(fullfile(directory,'**','*_mltout.mat'));
    files=files(~contains({files.name},'_stat_'));
    assert(~isempty(files),'ASCT:M8:MissingOutput','No STEP10 output for %s',analysisName);
    for j=1:numel(files)
        path=fullfile(files(j).folder,files(j).name);
        o=load(path,'NDTF','ARs','mv');
        assert(isfield(o,'NDTF') && isnumeric(o.NDTF) && ...
            size(o.NDTF,1)==expected && size(o.NDTF,2)==expected && ...
            all(isfinite(o.NDTF(:))), 'ASCT:M8:InvalidDTF', ...
            'NDTF mismatch; expected %d ROI in %s',expected,path);
        assert(isfield(o,'ARs') && isstruct(o.ARs) && ...
            isfield(o.ARs,'coefs') && isfield(o.ARs,'V') && ...
            isfield(o,'mv') && isfield(o.mv,'pord') && isfield(o.mv,'norm1'), ...
            'ASCT:M8:InvalidMVAR','Missing MVAR output fields in %s',path);
        order=double(o.mv.pord);
        assert(isscalar(order) && order==fix(order) && order>=1 && ...
            size(o.ARs.coefs,1)==expected && size(o.ARs.coefs,2)==expected && ...
            size(o.ARs.coefs,3)==order && all(isfinite(o.ARs.coefs(:))), ...
            'ASCT:M8:InvalidOrder','Wrong MVAR coefficients in %s',path);
        assert(double(o.mv.norm1)==double(c.varNorm), ...
            'ASCT:M8:InvalidNorm','Wrong normalization flag in %s',path);
        if isfield(c,'orderSelection') && strcmpi(char(c.orderSelection),'aic')
            assert(order<=c.maxMvarOrder,'ASCT:M8:InvalidOrder', ...
                'AIC selected an order beyond maxMvarOrder');
        else
            assert(order==c.mvarOrd,'ASCT:M8:InvalidOrder', ...
                'Fixed model order mismatch');
        end
        V=o.ARs.V;
        assert(isnumeric(V) && isequal(size(V),[expected expected]) && ...
            all(isfinite(V(:))), 'ASCT:M8:InvalidCov', ...
            'Missing residual covariance in %s',path);
        symV=(V+V')/2;
        minEig=min(real(eig(symV)));
        assert(minEig>=-1e-7*max(norm(V,'fro'),1e-12), ...
            'ASCT:M8:InvalidCov','Invalid residual covariance in %s',path);
        A=double(o.ARs.coefs);
        companion=zeros(expected*order);
        companion(1:expected,:)=reshape(A,expected,[]);
        if order>1
            companion(expected+1:end,1:expected*(order-1))= ...
                eye(expected*(order-1));
        end
        radius=max(abs(eig(companion)));
        assert(isfinite(radius),'ASCT:M8:InvalidMVAR','Non-finite VAR roots');
        % The output's mv.descfil should match the selected channels.
        labelsVerified=false;
        if isfield(o.mv,'descfil') && isfile(char(o.mv.descfil))
            raw=fileread(char(o.mv.descfil));
            labels=regexp(strtrim(raw),'\r?\n','split');
            labelsVerified=(numel(labels)==expected);
        end
        k=k+1;
        rows{k,1}=table(manifest.configId(i),string(analysisName), ...
            string(files(j).name),expected,order,logical(c.varNorm), ...
            radius,radius<1,minEig,labelsVerified, ...
            'VariableNames',{'configId','analysisName','file','nROIs', ...
            'estimatedOrder','varNorm','spectralRadius','stableVAR', ...
            'minCovEigenvalue','labelsVerified'});
    end
end
assert(~isempty(rows),'ASCT:M8:NoPassedVariants','No passed STEP10 variants');
report=vertcat(rows{:});
end

function n=nSelected(sel,nInput)
sel=char(string(sel));
if strcmp(sel,'1-'),n=nInput;return;end
match=regexp(sel,'^([0-9]+)-([0-9]+)$','tokens','once');
if ~isempty(match)
    a=str2double(match{1}); b=str2double(match{2});
    assert(a>=1 && b>=a && b<=nInput,'ASCT:M8:Selection', ...
        'Selected range outside the ROI model');
    n=b-a+1;return;
end
assert(~isempty(regexp(sel,'^[0-9]+(,[0-9]+)*$','once')), ...
    'ASCT:M8:Selection','Unsupported con.chanSel format: %s',sel);
indices=str2double(split(string(sel),','));
assert(~isempty(indices) && all(indices>=1) && all(indices<=nInput) && ...
    numel(unique(indices))==numel(indices), ...
    'ASCT:M8:Selection','Invalid ROI selection');
n=numel(indices);
end
