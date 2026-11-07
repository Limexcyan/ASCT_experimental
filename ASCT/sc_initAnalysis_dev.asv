% main script for executing SC pipeline functions

warning off
rc.asctdir = fileparts(mfilename('fullpath'));

tic

if ~isfield(rc,'scan')
    rc.scan = 0;
end

if rc.scan  
    if ~isfield(con, 'conName')
        con.conName = scansim.conName;
        if scansim.iter > 1
            rc.load = 10;
        end
    end
end

rc.analysisFolder = fullfile(rc.expFolder, rc.analysisName);
rc.rawFolder = fullfile( rc.expFolder, rc.dataRawFolder); 

if strcmp(rc.dataFormat, 'itab-sim')
    rc.sim = 1;
% else
%     rc.sim = 0;
end


if ~isfield(rc, 'mriRawFolder')
    rc.mriRawFolder = '';
end

if isempty (rc.mriRawFolder)
    rc.indivHSmodels = 0;
else
    rc.indivHSmodels = 1;
end

switch rc.dataFormat
    case 'bdf'
        seg.detect_flank = 'up';
        seg.event_type = 'STATUS'; % 'STATUS' for biosemi, 'TRIGGER' for meg-Chieti
        rc.eeg = 1; rc.meg = 0;
    case 'itab'
        seg.detect_flank = 'up';
        seg.event_type = 'trigger';
        rc.eeg = 0; rc.meg = 1;
    case 'ctf'
        seg.event_type = {};
        event_ctftrig = {};
        for i = 1:length(design.COND(1).name)
            seg.event_type = [seg.event_type design.COND(1).type{i}];
            event_ctftrig = [event_ctftrig design.COND(1).name{i}];
        end
        rc.eeg = 0; rc.meg = 1;
        if ~isfield(chan, 'ori'); chan.ori = '+X'; end
    case 'eeglab'
        if ~isfield(seg,'eventType')
            seg.event_type = 'trigger';
        else
            seg.event_type = seg.eventType;
        end
            rc.eeg = 1; rc.meg = 0;
        
    case {'itab-sim', 'syn-sim'}
        if ~isfield(loc, 'ROI')
            % tmploc = load( fullfile( rc.expFolder, 'SCANS', rc.analysisName, '0_SIMSTUFF', 'loc_roi.mat') );
            tmploc = load( fullfile( rc.expFolder, '0_SIMSTUFF', 'loc_roi.mat') );
            loc.ROI = tmploc.loc.ROI;
             seg.event_type = 'trigger';
        end
        rc.eeg = 0; rc.meg = 1;
end

% manage parpool

if license('checkout','Distrib_Computing_Toolbox')
    poolobj = gcp('nocreate');
else
    poolobj = [];
    disp('Parallel Computing Toolbox unavailable. Running in sequence mode');
end

% % if rc.load ~= 6   % problem with topopolot if run in parpool with workers running, so parpool is disabled (bit it still runs in parallel
%     if rc.useParallel>0
%         if isempty(poolobj)  % If no pool, do not create a new one.
%             parpool('Threads', rc.useParallel);         
% 
%         else
%             if poolobj.NumWorkers ~= rc.useParallel
%                 delete(poolobj);
%                 parpool('Threads', rc.useParallel);
%             end
%         end
%     end
% % end

%% SETTING DEFAULTS

if ~isfield(rc, 'saveCompress'); rc.saveCompress = 1; end
if ~isfield(rc, 'mriRawFolder'); rc.mriRawFolder = ''; end
if ~isfield(rc, 'mriExt'); rc.mriExt = ''; end
if ~isfield(rc, 'mriCoordsys'); rc.mriCoordsys = ''; end
if ~isfield(rc, 'elecRealPos'); rc.elecRealPos = ''; end
if ~isfield(rc, 'resetGPU;'); rc.resetGPU = 0; end
if ~isfield(rc, 'headTemplate'); rc.headTemplate = ''; end

if ~isfield(filter, 'resampleTo'); filter.resampleTo=0; end
if ~isfield(filter, 'LPfreq'); filter.LPfreq=0; end
if ~isfield(filter, 'HPfreq'); filter.HPfreq=0; end
if ~isfield(filter, 'plotResp'); filter.plotResp=0; end

if ~isfield(chan, 'ref'); chan.ref = []; end
if ~isfield(chan, 'ori'); chan.ori = '+Y'; end
if ~isfield(chan, 'addMockEOG'); chan.addMockEOG = []; end  % workaround for datasets withoud EOG electrodes. for better classification performance, mock EOG is added based on frontal leads
% if ~isempty(chan.addMockEOG); chan.elec = [1111]; chan.eog = [1111]; end

if ~isfield(seg,'origTrig'); seg.origTrig = []; end
if ~isfield(seg,'demean'); seg.demean=1; end

if ~isfield(design,'concatSes'); design.concatSes = 0; end

if ~isfield(ar, 'chWorstFraction'); ar.chWorstFraction = 0; end
if ~isfield(ar, 'chTrimMean'); ar.chTrimMean = 0; end
if ~isfield(ar, 'muscHP'); ar.muscHP = 35; end
if ~isfield(ar, 'muscLP'); ar.muscLP = 60; end
if ~isfield(ar, 'ica_movAver'); ar.ica_movAver = 0; end


if ~isfield(ica, 'ICA_method'); ica.ICA_method = 'fastica'; end
if ~isfield(ica, 'approach'); ica.approach = 'defl'; end
if ~isfield(ica, 'ICA_epsilon'); ica.ICA_epsilon = 0.000001; end
if ~isfield(ica, 'ica1_ic_to_screen'); ica.ica1_ic_to_screen = 25; end

if ~exist('loc'); loc=[]; end
if ~isfield(loc, 'method'); loc.method = 'mne'; end
if ~isfield(loc, 'recon'); loc.recon = 'pca'; end
if ~isfield(loc, 'depthWeight'); loc.deep_weight = 0; end
if ~isfield(loc, 'force_lf'); loc.force_lf = 1; end
if ~isfield(loc, 'depthWeight'); loc.depthWeight = 0.5; end
if ~isfield(loc, 'reslice'); loc.reslice = 0; end

if ~isfield(con, 'sensorLevel'); con.sensorLevel = 0; end    % source connectivity by default
if ~isfield(con, 'method'); con.method = 'dtf'; end
if ~isfield(con, 'isParametric'); con.isParametric = 0; end
if ~isfield(con, 'oneTailed'); con.oneTailed = 1; end
if ~isfield(con, 'lc'); con.lc = 1; end
if ~isfield(con, 'unc'); con.unc = 0; end
if ~isfield(con, 'varNorm'); con.varNorm = 0; end       % var divide
if ~isfield(con, 'winshf'); con.winshf = 0; end
if ~isfield(con, 'winnum'); con.winnum = 1; end
if ~isfield(con, 'winlen'); con.winlen = []; end
if ~isfield(con, 'useRange'); con.userange = 0; end

if con.sensorLevel; con.lc = 0; con.unc = 1; end % lc not relevant for source conn

if ~isfield(rc, 'sim'); rc.sim =[]; end
if ~isfield(rc, 'simStats'); rc.simStats = 0; end

% if isfield(simul, 'plev'); %FIXME
%     simul.siglev = 1;
% else
%     if ~isfield(simul, 'siglevel'); simul.siglevel = 1; end
% end  %if plev is determined, only the first siglevel is used

% if strcmp(rc.mriCoordsys, 'ras'); rc.mriCoordsys = 'itab'; end % for compatibility
% if strcmp(rc.mriCoordsys, 'als'); rc.mriCoordsys = 'ctf'; end 
rc.mriCoordsys = 'undetermined';

% check if current analysis folder uses previous stages from another folder
rc.usePrevFolder = 0; % if stays zero, all steps use the one pointetd by rc.analysisName
if isfield(rc, 'ica2Name');  rc.usePrevFolder = 5; rc.prevFolder = fullfile(rc.expFolder, rc.ica2Name);  end
if isfield(rc, 'iclocName'); rc.usePrevFolder = 8; rc.prevFolder = fullfile(rc.expFolder, rc.iclocName); end


fprintf('\n\n');
cprintf('*blue',   '         ◜◝\n');
cprintf('*blue', '\\       /  \\   ◜◝   A ⎯⎯⮞ S ⎯⎯⮞ C ⎯⎯⎯⮞ T ⮜⎯⎯\n');
cprintf('*blue',   ' \\     /    \\ /  \\ / ');       
    cprintf('*red',   'Atlantis Source Connectivity Toolbox\n');
cprintf('*blue',   '  \\   /      ¯    ¯      \n');       
cprintf('*blue',   '    ⎺ \n\n\n');


%% START OF FUNCTIONS CALL 

% 0  - raw file read and preproc
% 1  - segmentation
% 2  - artifact rejection
% 3  - ICA1 decomposition
% 4  - ICA1 artifact rejection
% 5  - ICA2 decomposition
% 6  - IC classification
% 7  - realignment
% 8  - source/head models and localization
% 9  - reconstruct ROI signals
% 10 - connectivity estimation
% 11 - connectivity statistics

if rc.load > 11 || rc.stop > 11 || rc.load < 0 || rc.stop < 0; error('FUNCTION CALL FOR NONEXISTING STAGES. check rc.load / rc.stop paraams'); end

if rc.load == 0;    sc_1_PREPROC_ICA;                                   end
if rc.stop == 0;    disp("PREPROC stage completed SUCESSFULLY"); sc_finish_effort; return; end

if rc.load <= 1;    sc_2_SEGM_ICA;                                      end
if rc.stop == 1;    disp('SEGM stage completed SUCESSFULLY.'); sc_finish_effort; return; end

if design.concatSes > 1   % if concat ses is enabled, ses filaname indexes are used only during preproc / segmentation
    if strcmp(rc.dataFormat, 'ctf')
        design = rmfield(design, "sesPosStart");
        design = rmfield(design, "sesPosEnd");
    else
        error ('Sessions merge is now only supported for CTF file format, sorry...');
    end
end

if rc.load <= 2;    sc_3_ARTIFACTS_ICA;                                 end
if rc.stop == 2;    disp('ARTIFACT REJ stage completed SUCESSFULLY.'); sc_finish_effort; return; end

if rc.load <= 5;  
   sc_4_DECOMPOSITION_ICA_dev;  
   % sc_4_2_VIZUALISATION_ICA; % 
    if rc.stop >= 5;    
        sc_4_2_VIZUALISATION_ICA;                       end; 
end
if rc.stop ==3 || rc.stop == 4 || rc.stop == 5;    disp('Requested ICA stages completed SUCESSFULLY.'); sc_finish_effort; return; end

if rc.load <= 6  
    % poolobj = gcp('nocreate'); if ~isempty(poolobj);  delete(poolobj); end   % see above; problem with parfor topoplot and running workers
    sc_5_CLASSIFICATION_ICA;    
end
if rc.stop == 6;    disp('CLASSIFICATION stage completed SUCESSFULLY.'); sc_finish_effort; return; end

if rc.useParallel>0  %recreate parppol after step 6
    poolobj = gcp('nocreate');
    if isempty(poolobj); parpool(rc.useParallel); end
end

if rc.load <= 8;    sc_6_SOURCE_LOC_ICA;                             end
if rc.stop == 7     disp("REALIGNMENT completed SUCESSFULLY."); sc_finish_effort; return; end
if rc.stop == 8;    disp("REALIGNMENT and SOURCE LOC completed SUCESSFULLY."); sc_finish_effort; return; end

if ~exist('begId'); begId = 0; end
if ~exist('endId'); endId = 0; end

if rc.load <= 9;    sc_7_SIG_RECON(rc, design, loc, con, begId, endId);    end
if rc.stop == 9;    disp('SIGNAL RECONSTRUCTION completed SUCESSFULLY.'); sc_finish_effort; return; end

if rc.load <= 10
    if strcmp(con.method, 'mfg')
        sc_8_CONN_MFG(rc, seg, design, loc, con);
        error('STOP - NO ERROR');
    end

    if ~isempty(rc.sim) && con.sensorLevel ~= 0
        % sensor-level connectivity path
        warning('running SENSOR LEVEL CONNECTIVITY')
        sc_recreatesensors
        sc_8_CONN_sensors(rc, seg, design, loc, con);
    else
        % regular source connectivity (default)
        sc_8_CONN(rc, seg, design, loc, con);
    end

    if rc.sim  %additional functions for simulation purposes
        if ~isfield(rc, 'simStatsFn')
            sc_simsummary(rc, seg, design, loc, con, simul, [], begId, endId);
        else
            disp('Using custom stat function');
            feval(rc.simStatsFn);
        end
    end
end

if rc.stop == 10;   disp("CONNECTIVITY ESTIMATION completed SUCESSFULLY."); sc_finish_effort; return; end

if rc.load <= 11;   sc_9_CONN_STAT_WRAPPER;  sc_finish_effort; return; end



function [] = sc_finish_effort()

elapsed = toc;
if elapsed <50
    elapsedtxt = ['', mat2str(round(elapsed)), ' sec'];
else
    elapsedtxt = ['', mat2str(round(elapsed/60)), ' min'];
end

fprintf('\n\n');
cprintf('*blue', '         ⌒\n');
cprintf('*blue', '\\       / \\   ⌒   A ⎯⎯⮞ S ⎯⎯⮞ C ⎯⎯⎯⮞ T ⮜⎯⎯\n');
cprintf('*blue', ' \\     /   \\ / \\ / ');
    cprintf('magenta', 'OUR EFFORTS, WHICH LASTED ');
    cprintf('*blue', elapsedtxt);
    cprintf('magenta', ', WERE SUCCESSFUL\n');
cprintf('*blue', '  \\   /     ¯   ¯      \n');
cprintf('*blue', '    ⎺ \n\n');


end
