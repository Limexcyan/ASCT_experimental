%This script classifies data based on previously trained models
%
% ICA spatial plotting works by using showfield() function. In script there
% is another function that works similarily --> topoplot(). 

%% ----> Settings <----

%Loading colormap data
load('colors.mat');
predictions_all = [];
prob_values_all = [];
Y_all =[];
set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[40 120 3000 1800]);
% set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[80 120 1000 680]);   per schermi con risoluzione 1024x768

if ~isfield(ica, 'class') 
    ica.class.mode = 'class';
    Mode = 'class';
else
    if ~isfield(ica.class, 'mode')
        ica.class.mode = 'class';
        Mode = ica.class.mode; % Sets script to classification or labeling mode:

    else
        Mode = ica.class.mode; % Sets script to classification or labeling mode:
        % + 'label'  --> labeling mode
        % + 'class'  --> classificiation mode
        % + 'review' --> review mode
    end
end

if ~isfield(rc, "valid")
    Validation = 0;
else
    Validation = rc.valid;
end

if ~isfield(rc, 'Data_volume')
    Data_volume = 'all'; %Controlls whether one will analyse all data or only best iterations
else
    Data_volume = rc.Data_volume;
end
%+ 'best' --> processing only best iteration
%+ 'all'  --> procesing all iterations

Unsure_only = 0;        %analyse only labels that were left unsure DEPRECEATED
classification_threshold = 0.5;
classif_table_all = struct();

%% %----> load data  and prepare structures <----

currentFolder = fullfile(rc.analysisFolder, '6_ICA2');

if exist(currentFolder) % reading 'infile' file
    infile_all = sc_reading(currentFolder, '*ica2.mat');  % screading : lsit of  files with specific extrnsions
    infile = infile_all;
else
    error( "There are no input files '/6_ICA2' folder.Most likely ICA decomposition data haven't been saved");
end

if exist('begId') && exist('endId')
    infile = infile_all(begId : endId);
end
clear data_all_arj data_all_ica1 data_all_ica2

if ~exist('begId'); begId=1; end
clear channels code_dir Cx_image seg.demean detect_flank e event_type rc.expFolder i j k chan.layout_type limit_ch load_file m_art_padding m_flt_padding m_hp m_lp m_ord m_th m_trl_padding m_type artifactFolder rc.analysisName filter import_ref_chan infile_all plot_chan_var recodeFn rc.save_artf rc.save_ica1 th_ch topo_z_value_th trig_list useParallel bdfFolder  tr_z_value_th


%%% Parallel pool init:
if rc.useParallel
    if strcmp(Mode,'class') & (isfield(rc,'classExecEnv') && rc.classExecEnv == 'gpu')
        % For GPU a failsafe making Pool size depend on available resources
        nW = sc_classPoolSize(rc, infile);
    else
        nW = rc.useParallel;
    end
    pool = gcp('nocreate');

    % Force Process Parpool
    if isempty(pool) || pool.NumWorkers ~= nW
        delete(pool);
        parpool('Processes', nW);
    end
end


%%% Enable parallel processing and apply quic fixes to all workers
if ~isempty(gcp('nocreate'))
    pctRunOnAll rmpath('/opt/MATbox/emegs3.3/emegs2dLib')
    if (isfield(rc,'classExecEnv') && rc.classExecEnv == 'gpu') % for GPU adds CUDA compatibility 
        pctRunOnAll parallel.gpu.enableCUDAForwardCompatibility(true); 
    end
else
    rmpath('/opt/MATbox/emegs3.3/emegs2dLib')
    if (isfield(rc,'classExecEnv') && rc.classExecEnv == 'gpu') % for GPU adds CUDA compatibility 
        parallel.gpu.enableCUDAForwardCompatibility(true); 
    end
end


%%% Load Classification model
if isfield(ica, 'ICA2_classModel')
    modelFile = ica.ICA2_classModel;
    if ~endsWith(modelFile, '.mat'), modelFile = [modelFile '.mat']; end
else
    modelFile = 'All_EEG.mat';
    ica.ICA2_classModel = modelFile;     % DSC prints this name
    warning('Model for classification of components not specified. Using default model All_EEG.mat')
end
Mods = load(modelFile, 'convModel', 'featModel', 'normStruct', 'mWeights');


%% ICA Classification

ica2stat = { 'dsname' 'best_iter' 'IC_all' 'IC_brain' 'var orig' 'var ica' 'var brainIC' 'var resid' '%var_brainIC' '%var_ICAresid'};  % save log with number of components found at ica1
progressfile = fullfile (rc.analysisFolder, '6_ICA2', 'class_progress.txt');
  
nDS        = length(infile);
tables_all = cell(nDS,1); stats_all  = cell(nDS,1);     
failed = false(nDS,1);
if (isfield(rc,'timing') && rc.timing); tRunStart = now;  end  % used to ignore timing files from older runs


%%% Perform Classification/ Labeling/ Reviewing
if strcmp(Mode,'class') % Parfor for DS only on Classification
    q = parallel.pool.DataQueue;
    afterEach(q, @(m) sc_handleMsg(progressfile, m));

    parfor ds = 1:nDS
        [~, dsn] = fileparts(infile{ds});
        %try % Failsafe if failure, so  one ICA will not crash the whole processing
            [tables_all{ds}, stats_all{ds}] = sc_5_ds_classify(infile, ds, rc, chan, ica, seg, ...
                currentFolder, progressfile, Data_volume, Mode, Mods);
            send(q, struct('ok', true,  'dsname', dsn, 'ds', ds, 'msg', ''));
        % catch ME % Logging ICA Class Failed
        %     failed(ds) = true;
        %     where = '';
        %     if ~isempty(ME.stack), where = sprintf(' [%s, line %d]', ME.stack(1).name, ME.stack(1).line); end
        %     send(q, struct('ok', false, 'dsname', dsn, 'ds', ds, 'msg', [ME.message where]));
        % end
    end
else
    for ds = 1:nDS
        [tables_all{ds}, stats_all{ds}] = sc_5_ds_classify(infile, ds, rc, chan, ica, seg, ...
            currentFolder, progressfile, Data_volume, Mode, Mods);
        [~, dsn] = fileparts(infile{ds});
        sc_logProgress(progressfile, dsn, ds);
    end
end


%%% Save Queue Data 
for ds = 1:nDS
    if isempty(stats_all{ds}), continue; end    % skipped / failed DS
    [~, dsname, ~] = fileparts(infile{ds});

    for l = 1:4; ica2stat{ds+1,l} = stats_all{ds}{l}; end

    classif_table = tables_all{ds};
    for iter = 1:length(classif_table)
        classif_table_all.("ds_"+strrep(dsname,'-','_')).(char(sprintf("Iter_%s",strrep(string(iter),'-','_')))) = classif_table{iter};
        Y_all           = [Y_all;           classif_table{iter}.Y];
        predictions_all = [predictions_all; classif_table{iter}.Proposed_Classification];
        prob_values_all = [prob_values_all; classif_table{iter}.prob_values];
    end
end

if ~isempty(gcp('nocreate'))
    pctRunOnAll addpath('/opt/MATbox/emegs3.3/emegs2dLib')
else
    addpath('/opt/MATbox/emegs3.3/emegs2dLib')
end

%% save 
save(fullfile(currentFolder,"classif_table.mat"),'classif_table_all','-v7.3');  % '-v6' v6 added for speedup
save(fullfile(currentFolder,"ica2stat.mat"),'ica2stat','-v7.3');  % '-v6' v6 added for speedup


fid = fopen(progressfile, 'a+');
fprintf(fid, '\n');
fprintf(fid, 'all requested ds classified');
fclose(fid);



%% Last tests

%%% Global Validation
if Validation == true && ~strcmp(Mode,'label')
    sc_validationPlot_test(predictions_all,Y_all,prob_values_all,currentFolder,"","All")
end


%%% Global Timing
if (isfield(rc,'timing') && rc.timing)
    if isfield(rc,'test') && rc.test
        tFolder = fullfile(rc.analysisFolder, '6_ICA2_classified');
    else
        tFolder = fullfile(rc.analysisFolder, '6_ICA2');
    end
    tf = dir(fullfile(tFolder, '*', 'class_timing.csv'));
    tf = tf([tf.datenum] >= tRunStart);                      % only this run

    rows = cell(numel(tf),1);
    for k = 1:numel(tf)
        f    = fullfile(tf(k).folder, tf(k).name);
        opts = setvartype(detectImportOptions(f), 'dsname', 'string');
        rows{k} = readtable(f, opts);
    end
    timingAll = vertcat(rows{:});
    if isempty(timingAll)
        warning('No timing files found for this run.');
    else

        writetable(timingAll, fullfile(tFolder, 'class_timing.csv'));   % the single combined file
    
        disp('==================== TIMING PER DS [s] ====================')
        disp(timingAll)
        disp('==================== TOTAL [s] ====================')
        disp(varfun(@sum,  timingAll, 'InputVariables', @isnumeric))
        disp('==================== MEAN PER DS [s] ====================')
        disp(varfun(@mean, timingAll, 'InputVariables', @isnumeric))
    end
end


%%% Failed ICA report:
if any(failed)
    fprintf(2, '\n%d DS FAILED: %s  (details in class_failed.txt)\n', sum(failed), mat2str(find(failed)'));
end


%% Functions

function sc_logProgress(progressfile, dsname, ds)
    % Same format as the original block in sc_5_ds_classify
    fid = fopen(progressfile, 'w');
    fprintf(fid, 'recently completed ds: ');
    fprintf(fid, '%s', dsname);
    fprintf(fid, '\n');
    fprintf(fid, mat2str(ds));
    fclose(fid);
    disp(['Completed DS ' num2str(ds) ': ' dsname]);
end


function sc_handleMsg(progressfile, m)
    % handles Messages  especially failed ones for progress and all:
    if m.ok
        sc_logProgress(progressfile, m.dsname, m.ds);        % same file/format as before
    else
        failfile = strrep(progressfile, 'class_progress.txt', 'class_failed.txt');
        fid = fopen(failfile, 'a');
        fprintf(fid, '%s  DS %d  %s  FAILED: %s\n', datestr(now), m.ds, m.dsname, m.msg);
        fclose(fid);
        fprintf(2, 'DS %d (%s) FAILED: %s\n', m.ds, m.dsname, m.msg);
    end
end


function nW = sc_classPoolSize(rc, infile)
    % Number of workers for DS-level parfor, limited by RAM, GPU memory and cores.
    %   rc.ramPerDS_GB     - peak RAM of ONE DS   (measure once, see Step 4)
    %   rc.gpuPerWorker_GB - GPU memory per worker (measure once, see Step 4)
    %   rc.classExecEnv    - 'gpu' (default) or 'cpu' (then GPU is not a limit)

    % --- RAM ---
    if isfield(rc,'ramPerDS_GB')
        ramPerDS = rc.ramPerDS_GB;
    else                                        % rough guess: 3x largest file + 1 GB
        b = zeros(numel(infile),1);
        for k = 1:numel(infile), d = dir(infile{k}); b(k) = d.bytes; end
        ramPerDS = 3*max(b)/1e9 + 1;
    end
    freeRAM = sc_freeRAM_GB();
    nRAM     = floor(0.8*freeRAM / ramPerDS);   % keep 20% headroom

    % --- GPU ---
    nGPU = inf;
    useGPU = ~isfield(rc,'classExecEnv') || strcmp(rc.classExecEnv,'gpu');
    if useGPU && canUseGPU()
        if isfield(rc,'gpuPerWorker_GB'), gpuPerW = rc.gpuPerWorker_GB; else, gpuPerW = 1.5; end
        g       = gpuDevice;
        freeGPU = g.AvailableMemory/1e9;
        nGPU    = floor(0.8*freeGPU / gpuPerW);
    end

    % --- cores + user limit ---
    nCPU = feature('numcores');
    nW   = max(1, min([nRAM, nGPU, nCPU, rc.useParallel]));

    fprintf('Class pool: %d workers  (RAM allows %d, GPU allows %g, cores %d, requested %d)\n', ...
            nW, nRAM, nGPU, nCPU, rc.useParallel);
end

function gb = sc_freeRAM_GB()
    % Available physical RAM in GB, cross-platform
    if ispc
        [~, sys] = memory;
        gb = sys.PhysicalMemory.Available/1e9;
    elseif isunix && ~ismac                               % Linux
        txt = fileread('/proc/meminfo');
        tok = regexp(txt, 'MemAvailable:\s*(\d+)', 'tokens', 'once');
        kb  = str2double(tok{1});
        gb  = kb/1e6;
    else                                                  % macOS fallback
        [~, out] = system('sysctl -n hw.memsize');
        gb = 0.5 * str2double(out)/1e9;                   % assume half is free
    end
end

% %%Functions for Own_CLassifier
% function [X,Corr] = preprocessMiniBatch(XCell,XCorr)
% 
% X = cat(4,XCell{:});
% Corr = cat(1,XCorr{:})';
% % Y = cat(2,YCell{:});
% % Y = onehotencode(Y,1,'ClassNames',[1 0]);
% end

% function [classesPredictions,raw_pred] = ownPredictions(dlnet,mbq,classes)
%     %%% Old Function that fetches the data in Batches - for making
%     %%% predicitons based on Joint Model (Depreceated)
%     classesPredictions = [];
%     raw_pred = [];
% 
%     while hasdata(mbq)
%         [dlX1,dlX2] = next(mbq);
% 
%         % Make predictions using the model function.
%         dlYPred = predict(dlnet,dlX1,dlX2);
%         raw_pred = [ raw_pred dlYPred(1,:)];
%         % Determine predicted classes.
%         YPredBatch = onehotdecode(dlYPred,classes,1);
%         classesPredictions = [classesPredictions YPredBatch];
% 
%     end
% 
% end
