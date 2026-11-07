%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% TRIG. DEF. AND SEGMENTATION %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function segments continous data into epoch.
% Triggers of interst should be specified in 'EX_SETUP.m' script in 'design' section.
% It supports both no-recodding and recodding of triggers.
% If recodding of triggers is needed 'sc_recodding_TEMPLATE.m' script should be edited
% and saved in experiment folder with an original name.
% It's name is passed along to this function as a 'recod_fun_to_call' parameter.
% for more info check 'sc_recodding_TEMPLATE.m'
% Parameters such as seg.prestim, seg.poststim and baseline should be specified in EX_SETUP, accordingly to experimental design.

clear data_all_segm

%% loading data (if rc.load_segm = 'L' in EX_SETUP %%%

if strcmp(rc.load_prep, 'L') || ~exist('data_all_prep')
    
    clear data_all_prep
    
    loadFolder = fullfile(analysisFolder, '/1_PREPROCESSED');
    if exist(loadFolder)
        infile_all = sc_reading(loadFolder, '*PREP.mat');
        infile = infile_all;
    else
        error( ["There are no infile files in the '/1_PREPROCESSED' folder." , newline, "Most likely preprocessed data haven't been saved"] );
    end
    
    % reading preprocessed data + possibly defining 'begId' and 'endId' variables
    
    if exist('begId') && exist('endId')
        infile = infile_all(begId : endId);
    end
    
    if ~exist('begId'); begId = 1; end
    
    parfor ds = 1 : length(infile)
        
        if isempty(infile{ds})
            error(['There is no data in infile(',num2str(ds),').' newline, 'It may happen that due to begId and length(infile) speficifaction this ds has not been preprocessed earlier'] );
        else
            disp([' [' num2str( round( 100 * (ds) / length(infile) ) ) '%] Loading PREPROCESSED DS', num2str(ds+begId-1), ' - ', infile{ds}] );   %mw
            tmpdata = load(infile{ds});
            data_all_prep(ds) = tmpdata.data_prep;
        end
    end
    clear tmpdata
    
end


%% SEGMENTATION %%%

infile_hdr = [];

for ds = 1 : length(infile)
    
    switch (rc.dataFormat)
        case 'bdf'
            infile_hdr{ds} = replace( infile{ds}, fullfile(rc.analysisName, '/1_PREPROCESSED'), '0_bdf');
            infile_hdr{ds} = replace( infile_hdr{ds}, '_PREP.mat', '.bdf');  %mmw
        case 'eeglab'
            infile_hdr{ds} = replace( infile{ds}, fullfile(rc.analysisName, '/1_PREPROCESSED'), '0_bdf');
            infile_hdr{ds} = replace( infile_hdr{ds}, '_PREP.mat', '.set');  %mmw    end
    end
    
    if isempty( data_all_prep(ds).hdr )
        error(['There is no data in data_all_prep(',num2str(ds),').'] );
    end
    
    disp( [ newline '[' num2str( round( 100 * ds / length(infile) ) ) '%] Ds: ', num2str(ds) ' is being segmented' ]);
    
    if ~isfield(seg, 'studyType')
        seg.studyType='ER';
    end
    
    % segmentation
    cfg=[];
    cfg.headerfile         = infile_hdr{ds};   % has to be specified too
    
    switch (rc.dataFormat)
        case 'bdf'
            cfg.trialdef.detectflank = 'up';
            cfg.trialdef.eventtype  = 'STATUS'; % '?' to look up full trigger list 'STATUS' for eeg and ' ' for meg
        case 'eeglab'
            cfg.headerformat = 'eeglab_set';
            cfg.trialdef.eventtype  = 'trigger'; 
% eventtype   = '';
    end
    
    cfg.trialdef.prestim    = seg.prestim;
    cfg.trialdef.poststim   = seg.poststim;
    
 if ds == 1 || ~isfield(data_all_prep, 'sampleinfo')
     data_all_prep(ds).sampleinfo = []; 
 end

if ~isfield(seg, 'recodeFn'); seg.recodeFn = ''; end

    
    % checking for recodding | in case recodding is needed, the parameter 'recod_fun_to_call' should be specified in EX_SETUP (in the directory where the data is stored)
    if ~isempty(seg.recodeFn)
        
        cfg_trigconfig = ft_definetrial(cfg);
        
        if isfield(seg, 'resampleTo')   %correct triggers to match new fs
            cfg_trigconfig_nfs = cfg_trigconfig; %nfs - new sampling rate
            downs = data_all_prep(ds).hdr.downs;
            interv = round((cfg_trigconfig.trl(1,2)-cfg_trigconfig.trl(1,1))/downs);
            
            cfg_trigconfig_nfs.trl(:,2) = round(cfg_trigconfig.trl(:,2)/downs);
            cfg_trigconfig_nfs.trl(:,1) = cfg_trigconfig_nfs.trl(:,2)-interv;
            cfg_trigconfig_nfs.trl(:,3) = round((cfg_trigconfig.trl(:,3))/downs);
            
            for m = 1:length(cfg_trigconfig_nfs.event)
                cfg_trigconfig_nfs.event(m).sample = round(cfg_trigconfig_nfs.event(m).sample/downs);
                if cfg_trigconfig_nfs.event(m).sample == 0; cfg_trigconfig_nfs.event(m).sample=1; end %avoid zero - samples start from 1
            end
            cfg_trigconfig = cfg_trigconfig_nfs;
        end
        
        [~, dsfile, ~] = fileparts( infile{ds} ); % extract file path, data set name, and extension
        dsname = dsfile(design.idPosStart : design.idPosEnd);
        % formula_to_call = strcat( seg.recodeFn , '(data_all_prep(ds) , ds, cfg_trigconfig, trig_list, cfg.trialdef.eventtype);' );
        formula_to_call = strcat( seg.recodeFn , '(cfg_trigconfig, seg, dsname);' );

        
        % [ data_all_prep(ds) , cfg_trigconfig ] = eval(formula_to_call);
        [ cfg_trigconfig ] = eval(formula_to_call);

        
    else
        cfg.trialdef.eventvalue = seg.trig_list;
        cfg_trigconfig = ft_definetrial(cfg);
        
        if isfield(seg, 'resampleTo')   %correct triggers to match new fs
            
            cfg_trigconfig_nfs = cfg_trigconfig; %nfs - new sampling rate
            downs = data_all_prep(ds).hdr.downs;
            interv = round((cfg_trigconfig.trl(1,2)-cfg_trigconfig.trl(1,1))/downs);
            
            cfg_trigconfig_nfs.trl(:,2) = round(cfg_trigconfig.trl(:,2)/downs);
            cfg_trigconfig_nfs.trl(:,1) = cfg_trigconfig_nfs.trl(:,2)-interv;
            cfg_trigconfig_nfs.trl(:,3) = round((cfg_trigconfig.trl(:,3))/downs);
            
            for m = 1:length(cfg_trigconfig_nfs.event)
                cfg_trigconfig_nfs.event(m).sample = round(cfg_trigconfig_nfs.event(m).sample/downs);
                if cfg_trigconfig_nfs.event(m).sample == 0; cfg_trigconfig_nfs.event(m).sample=1; end %avoid zero - samples start from 1
            end
            cfg_trigconfig = cfg_trigconfig_nfs;
        end
        
        tmpdata = ft_preprocessing(cfg_trigconfig, data_all_prep(ds) );
        if ~isfield(tmpdata, 'sampleinfo')
            tmpdata = sc_fixsampleinfo(tmpdata);
        end
        data_all_prep(ds) = tmpdata;
        
    end
    
    data_all_segm(ds) = ft_redefinetrial( cfg_trigconfig, data_all_prep(ds) );
    
    if strcmp(seg.studyType, 'RS')
        if isfield(seg, 'rsSegm')   % disable dummy RS segmentation if set to zero
            if strcmp(seg.studyType, 'RS')   %RESTING STATE DESIGN
                cfg = [];   % segmenting of RS data based on time
                cfg.length = seg.rsSegm;
                data_all_segm(ds) = ft_redefinetrial(cfg, data_all_segm(ds));
            end
        end
        
    end  
    
    %baseline correction
    cfg = [];
    cfg.demean = 'yes';
    if size(seg.baseline,2) == 1
        cfg.baselinewindow = [seg.baseline, 0];  % old style
    elseif size(seg.baseline,2) == 2
        cfg.baselinewindow = [seg.baseline(1) seg.baseline(2)];
    else
        error('baseline correction not defined properly')
    end
    data_all_segm(ds) = ft_preprocessing(cfg, data_all_segm(ds));
    
    % saving order of original trials (first colmun contains trigger values, second order of original trials)
    for tr = 1:length(data_all_segm(ds).trialinfo)
        data_all_segm(ds).trialinfo(tr, 2) = tr; %here it just gives information about order of the trial witin selected trials (it is not absolute order of trials)
    end
    
end


%% SAVE %%%


  
saveFolder = [ analysisFolder '/2_SEGMENTED'];

if ~exist(saveFolder)
    mkdir(saveFolder);
end

file_name = strcat( saveFolder , '/_SEGM_param.mat');
save(file_name, 'seg');

file_name = strcat( saveFolder , '/_SEGM_infile.mat');
save(file_name, 'infile');

for ds = 1 : length(infile)
    
    [~, dsfile, ~] = fileparts( infile{ds} ); % extract file path, data set name, and extension
    dsfile = replace(dsfile, '_PREP', '_SEGM');
    file_name = fullfile(saveFolder, strcat(dsfile,'.mat'));
    disp( [ '[' num2str(round( 100 * ds / length(infile) ) ) '%] Saving SEGM DS: ', num2str(ds), ' - ', dsfile] );
    
    data_segm = data_all_segm(ds);
    save(file_name, 'data_segm' );
    
end

clear data_segm


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  VISUALISATION OF SEGMENTED DATA   %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify which DS you want to display.
% Funtion defaultly displays:
% 10 epochs or 10 sek
% all channels present in given DS
% sets horizontaL scale to 70
% for more info type 'edit sc_plot' and analyse the script

%     for ds = begId : length(data_all_segm)
%         sc_plot(data_all_segm(ds), infile{ds}, '_SEGM', ds);
%     end
