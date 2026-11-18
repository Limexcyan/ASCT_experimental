function output = asct_multiverse_execute(p,~,~)
% Execute REAL ASCT scripts with a fresh, isolated parameter workspace.
% Requires MATLAB, FieldTrip, MMULTAR and the usual data/ExSetup dependencies.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'pipelineSC'),fullfile(root,'MNE_functions'), ...
    fullfile(root,'tools'),fullfile(root,'external','mmultar'), ...
    fullfile(root,'MNE_functions','templates'),fullfile(root,'multiverse'));
if p.rc.load==11
    % STEP11 plots source networks; FieldTrip must be initialized even when
    % the original singleverse setup omitted ft_defaults.
    if isfield(p,'fieldtripPath')
        ftroot=char(p.fieldtripPath);
    elseif isfolder('/opt/MATbox/fieldtrip')
        ftroot='/opt/MATbox/fieldtrip';
    else
        ftroot='';
    end
    if ~isempty(ftroot)
        assert(isfolder(ftroot),'ASCT:RealMultiverse:MissingFieldTrip', ...
            'FieldTrip folder not found: %s',ftroot);
        addpath(ftroot);
        ft_defaults;
    end
    assert(exist('ft_read_headshape','file')==2, ...
        'ASCT:RealMultiverse:MissingFieldTrip', ...
        'STEP11 requires FieldTrip. Set multiverse.fieldtripPath in EX_SETUP.');
end
rc=p.rc; chan=p.chan; filter=p.filter; seg=p.seg; ar=p.ar;
ica=p.ica; loc=p.loc; con=p.con; design=p.design;
if isfield(p,'simul'), simul=p.simul; end
if isfield(p,'begId'), begId=p.begId; end
if isfield(p,'endId'), endId=p.endId; end
sc_initAnalysis;
output=struct('analysisFolder',rc.analysisFolder);
if isfield(p,'truthConnectivity')
    output.performance=asct_multiverse_evaluate_output(rc.analysisFolder,con.conName,p.truthConnectivity);
end
end
