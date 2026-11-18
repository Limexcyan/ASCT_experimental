function output = asct_multiverse_execute(p,~,~)
% Execute REAL ASCT scripts with a fresh, isolated parameter workspace.
% Requires MATLAB, FieldTrip, MMULTAR and the usual data/ExSetup dependencies.
root=fileparts(fileparts(mfilename('fullpath')));
addpath(root,fullfile(root,'pipelineSC'),fullfile(root,'MNE_functions'), ...
    fullfile(root,'tools'),fullfile(root,'external','mmultar'), ...
    fullfile(root,'MNE_functions','templates'),fullfile(root,'multiverse'));
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
