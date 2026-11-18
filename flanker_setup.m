% ATLANTIS SOURCE CONNECTIVITY TOOLBOX
% https://atlantis.psychologia.uj.edu.pl

% This is a sample ExSetup file used to setup and run the analysis.
% It can be easily customized to run own's analyses
% Modify variables only, preserve the remaining code

clearvars 

%% RUN CONTROL 

% keep begId and endId commented, unless you want to analyze only subset of datasets
begId = 4;  %specify the first dataset index to start the analysis from
endId = 4;  %specify the last dataset index to stop the analysis on

% analytic steps to run
rc.load = 2;  % start from stage
rc.stop = 11;  % stop at stage  

% 0  - raw file import and preprocessing
% 1  - segmentation
% 2  - artifact rejection
% 3  - ICA1 decomposition
% 4  - ICA1 artifact rejection
% 5  - ICA2 decomposition
% 6  - IC classification
% 7  - realignment
% 8  - source/head models and localization
% 9  - reconstruct ROI s1ignals
% 10 - connectivity estimation
% 11 - connectivity statistics and data export

rc.useParallel = 0;   % the number of parallel workers to launch. zero to disable parallel processing

%% FILE LOCATION

rc.expFolder = '/mnt/devv/Exp/LG/wprawki/flanker';       % main exp folder. everything will be saved within this direstory. all path settings are relative to this directory
rc.analysisName='ana1';                         % the name of the current analysis. everything will be saved with a folder with this name
rc.dataFormat = 'bdf';                          % raw data format: 'itab' 'ctf' (MEG) 'bdf' 'eeglab' (EEG) 'itab-sim' (simulations)
rc.dataRawFolder = '0_raw';                     % raw data folder
% rc.iclocName = '';
% rc.ica2Name = '';
rc.mriRawFolder = '';                      % location of T1 scans. leave empty if average brain template is to be used
rc.mriExt = '';                              % format of T1 scans
rc.mriCoordsys = '';                         % coordsys of MRI scans. typically 'ras'
%rc.elecRealPos = 'scanelec';                    % directory with individual position mat files. comment out to disable


%% PREPROCESSING   %%%

chan.meeg = [1:64];            % specify EEG/MEG channels 
chan.ref  = [71 72];           % EEG: ref channels to use during import / MEG: ref channels to perform CTF noise balancing
chan.eog =  [65 66 67 68];     % EOG channels for EEG
chan.elec = [65 66 67 68];  % additional electric channels (including EOG but excluding MEG/EEG sensors)

filter.HPfreq = 2;             % high pass frequency
filter.HPtype = 'firws';       % hp filter type
filter.HPord   = 846;         % hp filter order (3.3*fs/trans_width[Hz])    %% here we assume fs=512Hz and HP transition width of 1Hz (1.5-2.5 Hz)
filter.LPfreq = 48;            % lp frequency
filter.LPtype  = 'firws';      % lp filter type
filter.LPord   = 282;          % lp filter order                             %% here we assume fs=512Hz and LP transition width of 3Hz (46.5-49.5 Hz)
filter.plotResp   = 'no';      % specify where you want to see filer response ('yes') or 'no'


%% SEGMENTATION

seg.studyType = 'ER';      % either 'ER' for event related; 'RS' for resting state
seg.prestim = 0;           % pre-stimulus period for epoching [sec]
seg.poststim = 2;          % post-stimulus period for epoching [sec]
seg.baseline = 0;          % baseline correction (from base_line to zero) [sec]
% seg.recodeFn = 'Recoding_Flanker';  %provide trigger recoding function if necessary or comment out to ignore

%% STUDY DESIGN

% define Id, Group, Session by the position in the filename
design.idPosStart = 1;
design.idPosEnd = 2;
%design.grpPosStart = 4;
%design.grpPosEnd = 6;
design.sesPosStart = 8;
design.sesPosEnd = 8;  


% conditions / trigger codes
design.COND(1).name = {'FLANK-CONG', 'FLANK-INCO'};       % condition names
design.COND(1).trig = { {113}, {123} };   % triggers associated with conditions

 
%% ARTIFACT REJECTION 1

% bad channels detection
ar.chIQR     = 8; % iqr threshold for chan rejection. 
ar.chRmLimit = 8; % sets max number of channels that can be removed from the DS. if exceeded, a whole DS is removed   

% bad trials detection
ar.varIQR   = 8;   % trial variance
ar.rangeThr = 200; % trial range
ar.muscThr  = 20;  % muscle contamination z-threshold
ar.muscHP   = 20;
ar.muscLP   = 40;

%% INDEPENDENT COMPONENT ANALYSIS

ica.ICA1_numIter  = 2;          % number of ICA1 iterations (runs)
ica.ICA1_maxSteps = 100;        % max steps to seek for the next IC (modulates deflation level); see the manual
ica.ICA1_nonlinearity = 'pow3'; % 'pow3' (faster) | 'tanh' (may be slightly more accurate)

ica.ICA2_numIter  = 25;         % number of ICA2 iterations (runs)
ica.ICA2_maxSteps = 200;        % max steps to seek for the next IC (modulates deflation level); see the manual
ica.ICA2_nonlinearity = 'tanh';


%%% ICA Classification code
ica.ICA2_classModel = 'All_EEG.mat'; % Classification model used
ica.class.verbosity = 0;
%% IC ARTIFACT REJECTION (AR2)

% bad channels ic-based removal
ar.ica_topoZThr     = 7;    % rejction of sensors that deviate significantly / topography based
% bad trials ic-based removal
ar.ica_ic2screen    = 6;    % how many IC to screen for artifacts. 
ar.ica_singleicZthe = 20;   % trial rejection based on z-scores of individual IC
ar.ica_multiicZThr  = 7;    % trial rejection based on z-scores of multiple IC simultaneously 
ar.ica_multiicZCnt  = 5;    % trial rejection based on z-scores of multiple IC simultaneously - no of IC that exceed ar.ica_multiicZThr

%%  LOCALIZATION   
loc.norm = 'cov';       % 'lambda' | 'cov' (default). 'cov' is recommended BUT with proper noiseLev estimation. see manual.
% loc.lambda    = 0.1;  % valid if loc.norm = 'lambda'
loc.noiseLev    = 2;    % valid if loc.norm = 'cov'. provide pre-determined system noise level here
loc.depthWeight = 0.5;  % depth weightning parameter (default 0.5)

loc.ROI(1).name = 'dACC';   %see one notes for justifications
loc.ROI(1).pos = [7 18 33];  

loc.ROI(2).name = 'raIns';   
loc.ROI(2).pos = [37 16 -2];  

loc.ROI(3).name = 'rDL';  
loc.ROI(3).pos = [58 18 44];

loc.ROI(4).name = 'rPPC';  
loc.ROI(4).pos = [48 -52 50]; 

loc.ROI(5).name = 'rVL';  
loc.ROI(5).pos = [42 25 14];  

 
%% CONNECTIVITY  

con.conName = 'FPN_300_600';    % subirectory to save the current connectivity analysis 
con.decimate = 2;       % divide factor to decrease sampling rate before conn calculations. 
con.mvarOrd = 7;        % MVAR model order
con.chanSel = '1-';     % ROIs to include: '1-' fo all; ex: '1,2,4,5' for selection
con.useRange = 1;       % cut range from predefined epochs (for ER study); 0 to analyze whole epochs
con.timeRangeStart = 0.3; % range start [sec] if useRange = 1
con.timeRangeEnd = 0.6; % range end [sec] if useRange = 1
con.varNorm = 1

%% DATA EXPORT and STATS
% DC stands for DATA CONFIGURATION. used to build elements of statistical comparisons

DC=1; % incongruent flanker in all sessions 
design.DC(DC).name = 'inco_all'; 
design.DC(DC).COND = {'FLANK-INCO'};
% design.DC(DC).SES = {'1','2','3','4'};  

DC=2; % congruent flanker in all session
design.DC(DC).name = 'cong_all';
design.DC(DC).COND = {'FLANK-CONG'};  
% design.DC(DC).SES = {'1','2','3','4'};  


% STAT COMPARISONS and EXPORT 
con.contrast2test = {[1,2]};              % DCs to be contrasted (here two contarsts will be checked DC1 vs DC2)  ***
con.freqRange = {[3,8], [8 12], [13 30], [3 30]};         % freq ranges [Hz]
con.subTitle = {'theta', 'alpha', 'beta', 'wide-freq'};  % names for ranges defined above   ***
con.pThresh = {0.2, 0.001};                            % p threshold for visualization   ***
con.oneTailed = 1;                               % one- ore two-taoiled test 
con.testType = 'within';                         % contrast type: 'within' | 'between'
con.iqr = {999};                                   % remove extremes before stats ***
% *** marks settings that can have multiple values; STAT will be then iterated consecutively to include all settings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic
%addpath('/opt/MATbox/fieldtrip');
addpath('/mnt/devv/Exp/LG/wprawki/flanker/fix', '-begin');
rehash;
which sc_3_ARTIFACTS_ICA -all
%ft_defaults;
sc_initAnalysis
toc
