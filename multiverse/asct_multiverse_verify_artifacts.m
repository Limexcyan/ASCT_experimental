function report = asct_multiverse_verify_artifacts(p)
%ASCT_MULTIVERSE_VERIFY_ARTIFACTS Fail closed after a real STEP8-10 run.
% Validates file presence and expected counts, not scientific correctness.
assert(isstruct(p) && isfield(p,'rc') && isfield(p,'con'), ...
    'ASCT:M2:MissingSetup','Expected prepared setup');
folder=fullfile(char(p.rc.expFolder),char(p.rc.analysisName));
nExpected=1;
if isfield(p,'begId') && isfield(p,'endId') && ...
        isscalar(p.begId) && isscalar(p.endId) && ...
        p.begId>=1 && p.endId>=p.begId
    nExpected=p.endId-p.begId+1;
end
report=struct('analysisName',p.rc.analysisName, ...
    'expectedParticipants',nExpected,'iclocFiles',0,'roiFiles',0,'connFiles',0);
if p.rc.load<=8
    files=dir(fullfile(folder,'7_SOURCEACT','icloc','*_icloc.mat'));
    ensureFiles(files,nExpected,'ICLOC',folder);
    report.iclocFiles=numel(files);
end
if p.rc.load<=9
    mods=modalities(p.con);
    nDC=designCount(p);
    for dc=1:nDC
        for k=1:numel(mods)
            pat=fullfile(folder,'7_SOURCEACT',sprintf('DC%d',dc),mods{k}, ...
                ['*_sigroi_' mods{k} '.mat']);
            files=dir(pat);
            ensureFiles(files,nExpected,'ROI',pat);
            report.roiFiles=report.roiFiles+numel(files);
        end
    end
end
mods=modalities(p.con);
assert(isfield(p.con,'conName') && ~isempty(p.con.conName), ...
    'ASCT:M2:MissingConnectivity','con.conName is required for artifact checks');
for dc=1:designCount(p)
    for k=1:numel(mods)
        pat=fullfile(folder,'8_CONN',char(p.con.conName),mods{k}, ...
            sprintf('DC%d',dc),'*_mltout.mat');
        files=dir(pat);
        ensureFiles(files,nExpected,'connectivity',pat);
        report.connFiles=report.connFiles+numel(files);
    end
end
end

function ensureFiles(files,number,kind,pattern)
assert(numel(files)>=number && (isempty(files) || all([files.bytes]>0)), ...
    'ASCT:M2:MissingArtifact', ...
    'Missing/empty %s files: expected >=%d at %s, found %d', ...
    kind,number,pattern,numel(files));
end

function n=designCount(p)
n=1;
if isfield(p,'design') && isfield(p.design,'DC') && ~isempty(p.design.DC)
    n=numel(p.design.DC);
end
end

function mods=modalities(con)
mods={};
if ~isfield(con,'lc') || logical(con.lc), mods{end+1}='lc'; end %#ok<AGROW>
if isfield(con,'unc') && logical(con.unc), mods{end+1}='unc'; end %#ok<AGROW>
assert(~isempty(mods),'ASCT:M2:NoSignal','Enable con.lc and/or con.unc');
end
