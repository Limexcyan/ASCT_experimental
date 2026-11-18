%%% ATLANTIS PROCESSING PIPELINE
% AUG2025 RESULTS with corrected lowfreq -> 3-12Hz, BRAIN TEMPLATES
% PREPRO: ana4
% final: ana6

clear all

 % begId = 1; %specify begining index %% 2, 11 - ceck - LC doesnt work
 % endId = 1; %specify end index


%% LOADING

% Specify main data folder where the files of interest are located
rc.expFolder = '/mnt/devv/Exp/LG/wprawki/dyslexia/';
rc.analysisName = 'ana1'; %specify name of your analysis
rc.dataFormat = 'eeglab';
% rc.iclocName = 'ana4';
% rc.ica2Name = 'ana4';
rc.dataRawFolder = '0_raw';
% rc.mriRawFolder = 'mristuff';
% rc.mriExt = 'nii';
% rc.mriCoordsys = 'ras';
% rc.headTemplate = 'headmodel_template_10yrs.mat';
% rc.sourceTemplate = 'sourcemodel_indiv_10yrs.mat';
% rc.rescaleUnits = 1e15;
rc.useParallel = 0;   % max number of parallel woorkers. use zero for disabling parallel processing0%% RUN CONTROL

% 0  - raw file read and preproc
% 1  - segmentation
% 2  - artifact rejection
% 3  - ICA1 decomposition
% 4  - ICA1 artifact rejection
% 5  - ICA2 decomposition
% 6  - IC classification
% 7  - realignment/headmodel/sourcemodel
% 8  - leadfield/localization
% 9  - reconstruct ROI signals
% 10 - connectivity estimation
% 11 - connectivity statistics

rc.load = 10;  % start from stage
rc.stop = 11;  % stop at stage  (-1 = run all)

%% PREPROCESSING

chan.meeg = [1:30 33:64];
chan.ref = [31 32];
chan.elec = []; %65 - VEOG1, HEOG2,
chan.eog = [];
chan.addMockEOG = [1, 2];  % this should be enabled AFTER proeprocessing (step 0)

filter.HPfreq = 2; %sets up high pass frequency
filter.HPtype = 'firws'; %sets up hp filter type
filter.HPord   = 1650; %sets up hp filter order (3.3*fs/trans_width) [2Hz trans 1.5-2.5]
filter.LPfreq = 48; %sets up lp frequency
filter.LPtype  = 'firws'; %sets up lp filter type
filter.LPord   = 550; %sets up lp filter order  [3Hz trans 46.5-49.5]
filter.resampleTo = 250;

%% SEGMENTATION

seg.studyType = 'ER'; % either 'ER' for event related; 'RS' for resting state
seg.prestim = 0; % +33 ms shift pre-stimulus period for epoching
seg.poststim = 1; % post-stimulus period for epoching
seg.baseline = 0; % 200 baselin correction (from base_line to zero)
seg.demean = 'Y'; % recommended for ica. ovverrides baseline correction
seg.eventType = 'Stimulus';
seg.recodeFn = ''; %'recode_rt_cond';


%% ARTIFACT REJECTION

% preliminary channel screening
    ar.chIQR = 20;    % chan iqr threshold for rejection
    ar.chRmLimit = 8; % sets max number of channels that can be removed from the DS. if exceeded, whole DS is removed
    ar.chWorstFraction = 0;  % use only a worst fraction of trials (0 to disable / use all)
    ar.chTrimMean = 0;
% trial variance
    ar.varIQR = 5;
% trial range
    ar.rangeThr = 400;
% muscle
    ar.muscHP = 35; % low freq window for muscle detection
    ar.muscLP = 50; % high freq window for muscle rejection
    ar.muscThr = 24; % 20 : muscle z-value (converted threshold)

ica.class.verbosity = 0;
ica.ICA1_nonlinearity = 'tanh';  %default tanh (faster for preliminary screening)
ica.ICA1_numIter = 2;
ica.ICA1_maxSteps = 120;
ica.ICA2_numIter = 20;
ica.ICA2_maxSteps = 200;
ica.ICA2_nonlinearity = 'pow3';
ica.ICA2_classModel = 'All_EEG.mat' %'classification_models_EEG_ER_elec.mat' %'classification_models_EEG_ER_mockEOG.mat';

%% ica.AR
ar.ica_topoZThr = 7; % sensor rejection that deviate significantly based on topography
ar.ica_ic2screen = 6;
ar.ica_movAver = 3; % moving aver of IC signal before ica ar in samples
ar.ica_singleicZthe = 20;  %trial rejection based on z-scores of individual IC
ar.ica_multiicZThr = 10;  %trial rejection based on z-scores of multiple IC simultaneously
ar.ica_multiicZCnt = 6;  %trial rejection based on z-scores of multiple IC simultaneously - no of IC that exceed ar.ica_multiicZThr

%DESIGN % here specify your experminet design
design.COND(1).name = {'mul', 'vis', 'aud'};
%design.COND(1).name = {'1', '2', '3'}
design.COND(1).trig = { {6}, {7}, {8}};
%design.COND(1).trig = { {'S  6'}, {'S  7'}, {'S  8'}};

% Here indexes of characters of the file name (used for coding indiv id, sesions and groups) should be specified.

design.idPosStart = 6;
design.idPosEnd = 8;
design.grpPosStart = 3;   % 0 CTR; 1 DYS
design.grpPosEnd = 4;     % 1 FEM; 2 MALE

%%  LOCALIZATION

loc.headmodelMethod = 'simbio';
loc.norm = 'cov'; % lambda | cov
loc.noiseLev = 2;  %
loc.method = 'mne';   %
loc.recon = 'pca';
loc.depthWeight = 0.5;

% Atlas Juelich
% Lewy V1 = -9.18mm, -85.86mm, 2.41mm
% Prawy V1 = 14.09mm, -82.13mm, 2.62mm
% Lewa A1 (TE 1.1) = -38.69mm, -28.58mm, 11.71mm
% Prawa A1 (TE1.1) = 40.50mm, -24.80mm, 11.43mm
%
% Metaanaliza Gao et al. 2023
% Lewa STC (conjunction & interaction) -56 -42 8
% Prawa STC (conjunction & interaction) 60 -30 10
% Lewa PFC (A-V) -42 14 26
% Prawa PFC (A-V simple) 48 10 20

loc.ROI(1).name = 'LV1';
loc.ROI(1).pos = [-9 -86 2];

loc.ROI(2).name = 'RV1';
loc.ROI(2).pos = [14 -82 3];

loc.ROI(3).name = 'LA1';
loc.ROI(3).pos = [-39 -29 12];

loc.ROI(4).name = 'RA1';
loc.ROI(4).pos = [40 -25 11];

loc.ROI(5).name = 'LSTC';
loc.ROI(5).pos = [-56 -42 8];

loc.ROI(6).name = 'RSTC';
loc.ROI(6).pos = [66 -30 10];

loc.ROI(7).name = 'LPFC';
loc.ROI(7).pos = [-42 14 26];

loc.ROI(8).name = 'RPFC'; %
loc.ROI(8).pos = [48 10 20];


%% DESIGN

DC=1;
design.DC(DC).name = 'mul-all';
design.DC(DC).COND = {'mul'};
design.DC(DC).GRP = {};
DC=2;
design.DC(DC).name = 'vis-all';
design.DC(DC).COND = {'vis'};
design.DC(DC).GRP = {};
DC=3;
design.DC(DC).name = 'aud-all';
design.DC(DC).COND = {'aud'};
design.DC(DC).GRP = {};


%% CONNECTIVITY


% SIGRECON
con.decimate = 2;  %decrease sampling freq before conn calculations 

% MVAR [10]

% con.conName = 'p7-snr2-varnorm-w25-125-rev'; % CONN subirectory
% con.mvarOrd = 7;        % model order
% con.chanSel = '1-'; 
% con.useRange = 1;  % cut range from trials 
% con.timeRangeStart = 0.025; 
% con.timeRangeEnd = 0.125; 
% con.varNorm = 1;

con.conName = 'p7-snr2-varnorm-w100-200-rev'; % CONN subirectory
con.mvarOrd = 7;        % model order
con.chanSel = '1-';
con.useRange = 1;  % cut range from trials
con.timeRangeStart = 0.1;
con.timeRangeEnd = 0.2;
con.varNorm = 1;


% STATS [11]
con.freqRange = {[3 12], [8 12], [15 30]};
con.subTitle = {'lowfq', 'alpha', 'beta'};


con.testType = 'within'; %must be within or between
% con.contrast2test = {  [1,2], [1,3], [2,3], [4,5], [4,6], [5,6], [7,8], [7,9], [8,9]};  %with
con.contrast2test = {  [1,2], [1,3], [2,3]};  %with


% con.contrast2test = {   [4 7], [5 8], [6 9],  [10 16], [11 17], [12 18], [13 19], [14 20], [15 21], [16 19], [17 20], [18 21], [10 13], [11 14], [12 15]};  %betw
% con.testType = 'between'; %must be within or between


con.pThresh = {0.001};
con.oneTailed = true;  % divides p-values from 2-tailed test by 2
con.iqr = {3}; %remove extremes before stat


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic

addpath('/opt/MATbox/fieldtrip');
ft_defaults;

sc_initAnalysis
toc
