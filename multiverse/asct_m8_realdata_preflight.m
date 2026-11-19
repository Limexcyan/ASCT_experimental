function report = asct_m8_realdata_preflight(setup,sourceAnalysis,requiredROIs)
%ASCT_M8_REALDATA_PREFLIGHT Read-only inspection of EVERY saved STEP9 ROI.
% Run only after STEP9 finished. Validates actual saved signal row counts,
% trial length and selected ROI count; it does not certify source quality.
assert(isstruct(setup) && isfield(setup,'rc') && isfield(setup.rc,'expFolder') && ...
    isfield(setup,'con') && isfield(setup,'design') && isfield(setup.design,'DC'), ...
    'ASCT:M8:Setup','Expected ExSetup rc, con and design');
assert(ischar(sourceAnalysis) || (isstring(sourceAnalysis) && isscalar(sourceAnalysis)), ...
    'ASCT:M8:Source','Source analysis must be a name');
assert(isscalar(requiredROIs) && requiredROIs>=1 && ...
    requiredROIs==fix(requiredROIs),'ASCT:M8:ROI','Invalid required ROIs');
assert(~isempty(regexp(char(sourceAnalysis),'^[A-Za-z0-9_.-]+$','once')), ...
    'ASCT:M8:Source','Source analysis must be a directory name');
base=fullfile(char(setup.rc.expFolder),char(sourceAnalysis),'7_SOURCEACT');
assert(isfolder(base),'ASCT:M8:MissingInputs','No ROI inputs at %s',base);
mods={};
if ~isfield(setup.con,'lc') || logical(setup.con.lc),mods{end+1}='lc';end %#ok<AGROW>
if isfield(setup.con,'unc') && logical(setup.con.unc),mods{end+1}='unc';end %#ok<AGROW>
assert(~isempty(mods),'ASCT:M8:Modality','No selected signal modality');
beg=0;last=0;
if isfield(setup,'begId'),beg=setup.begId;end
if isfield(setup,'endId'),last=setup.endId;end
assert((beg==0 && last==0) || (beg>=1 && last>=beg && ...
    beg==fix(beg) && last==fix(last)), ...
    'ASCT:M8:Range','Invalid begId/endId');
rows={};k=0;
for dc=1:numel(setup.design.DC)
    for m=1:numel(mods)
        modality=mods{m};
        folder=fullfile(base,sprintf('DC%d',dc),modality);
        files=dir(fullfile(folder,['*_sigroi_' modality '.mat']));
        assert(~isempty(files),'ASCT:M8:MissingInputs','No ROI signals in %s',folder);
        [~,idx]=sort({files.name});files=files(idx);
        if beg>0
            assert(numel(files)>=last,'ASCT:M8:MissingInputs', ...
                'Only %d input files; endId=%d',numel(files),last);
            files=files(beg:last);
        end
        for j=1:numel(files)
            f=fullfile(files(j).folder,files(j).name);
            s=load(f,'data_sigroi');
            assert(isfield(s,'data_sigroi') && isstruct(s.data_sigroi), ...
                'ASCT:M8:InvalidROIFile','Missing data_sigroi: %s',f);
            content=s.data_sigroi;
            if isfield(content,'signal')
                conditions={content};
            else
                names=fieldnames(content);
                assert(~isempty(names),'ASCT:M8:InvalidROIFile','No conditions: %s',f);
                conditions=cell(1,numel(names));
                for z=1:numel(names), conditions{z}=content.(names{z});end
            end
            for z=1:numel(conditions)
                c=conditions{z};
                assert(isstruct(c) && isfield(c,'signal') && ...
                    isfield(c,'trialen') && isnumeric(c.signal) && ...
                    ndims(c.signal)==2 && size(c.signal,1)>=requiredROIs, ...
                    'ASCT:M8:InsufficientROIs', ...
                    'Need %d ROI signals in %s (condition %d)',requiredROIs,f,z);
                assert(isscalar(c.trialen) && c.trialen>=2 && ...
                    c.trialen==fix(c.trialen) && ...
                    size(c.signal,2)>=2*c.trialen && ...
                    mod(size(c.signal,2),c.trialen)==0 && ...
                    all(isfinite(c.signal(:))), ...
                    'ASCT:M8:TrialShape','Invalid trial length in %s',f);
                k=k+1;
                rows{k,1}=table(dc,{modality},{files(j).name},z, ...
                    size(c.signal,1),c.trialen, ...
                    size(c.signal,2)/c.trialen, ...
                    'VariableNames',{'DC','modality','file','conditionIndex', ...
                    'nROIs','trialLength','nTrials'});
            end
        end
    end
end
report=vertcat(rows{:});
end
