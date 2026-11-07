dsName = '/mnt/devv/SourceConn/Exp/MarkusData/FearGenSpider/C01/A0700_FearGenSpider_20170410_01.ds';

% determine dataset header information
hdr  = ft_read_header(dsName);

% channel selection based on sensor types
megInd = find(strcmp(hdr.chantype, 'meggrad')); meglabel = hdr.label(megInd);
eegInd = find(strcmp(hdr.chantype, 'eeg')); eeglabel = hdr.label(eegInd);
refInd = find(strncmp(hdr.chantype, 'ref', 3)); reflabel = hdr.label(refInd);
fprintf(1, '\nfound %d MEG, %d EEG and %d reference channels in dataset %s\n', ...
        length(meglabel), length(eeglabel), length(reflabel), dsName);

% import data    
cfg = [];
cfg.dataset = dsName;
cfg.continuous  = 'yes';

% only MEG    
cfg.channel = meglabel;
rawDataMEG = ft_preprocessing(cfg);

% only EEG    
cfg.channel = eeglabel;
rawDataEEG = ft_preprocessing(cfg);

% only References
cfg.channel = reflabel;
rawDataRef = ft_preprocessing(cfg);

% MEG plus Reference
cfg.channel = [meglabel; reflabel];
rawDataMEGREF        = ft_preprocessing(cfg);



%%%%% ITAB ver

dsname = '/mnt/devv/SourceConn/Exp/MarkusData/FearGenSpider/0_data/C01/A0700_FearGenSpider_20170410_01.ds';

hdr = ft_read_header(dsname);


%to generate topoplot
cfg=[];
% cfg.grad = 'CTF275.lay';
layout=ft_prepare_layout(cfg, data);

  figure
  ft_plot_layout(layout);


cfg = [];
cfg.dataset = dsname;
% cfg.trialdef.eventtype      = 'trigger';
% cfg.trialdef.eventvalue     = {31,33,35, 41, 43, 45}; %3 sek 
%cfg.trialdef.eventvalue     = {11,13,15, 21, 23, 25}

% cfg.trialdef.prestim        = 0.3;
% cfg.trialdef.poststim       = 3;
% cfg = ft_definetrial(cfg);     

% cfg = ft_rejectartifact(cfg);

% bad_channel = find([hdr.orig.ch.flag]==1);
% good_channel = setdiff(find([hdr.orig.ch.type]==2),bad_channel);
% cfg.channel = [hdr.label(good_channel)];
data = ft_preprocessing(cfg);


%    [~, dsname, ~] = fileparts( infile{ds} ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type
%         disp( ['[' num2str(round( 100*(ds)/length(infile))) '%] DS: ', num2str(ds), ' - ' , dsname, ' is being preprocessed' ]);  %mmw
        
        %%% rereferencing
        cfg = [];
        %         cfg.datafile = dsname %infile{ds}; %need to be provided too
        cfg.dataset = dsname; %infile{ds};
        cfg.continuous         = 'yes';
        %cfg.chantype = 'eeg';
%         cfg.reref       = 'yes';
%         cfg.refchannel  = import_ref_chan;
        
        data_meg = ft_preprocessing(cfg); %rereference to avg data is done after artifact rejection in sc_3_ARTIFACTS
        
        % removing ref channels
%         cfg = [];
%         cfg.channel     = channels;
%         data_eeg = ft_preprocessing(cfg, data_eeg);
        
        %%% filtering (applied to all structures the same maner
        cfg             = [];
        cfg.hpfilter    = 'yes';     % enables high-pass filtering
        cfg.hpfilttype  = filter.HPtype;
        cfg.HPfreq      = filter.HPfreq;       % sets up the frequency for high-pass filter
        try %mmw
            cfg.hpfiltord   = filter.HPord;
        catch
        end
        
        cfg.lpfilter    = 'yes';     % enables low-pass filtering
        cfg.lpfilttype  = filter.LPtype;
        cfg.LPfreq      = filter.LPfreq;        % sets up the frequency for low-pass filter
        try %mmw
            cfg.lpfiltord   = filter.LPord;
        catch
        end
        
        cfg.plotfiltresp = filter.plotResp;   
        data_all_prep(ds) = ft_preprocessing(cfg, data_meg);
        data_all_prep(ds).hdr.dsname = dsname;   % add dsname
        
        %%% temporary EOG correction for estimating EOG-corrected chan variance
%         data_meg = data_all_prep(ds);
%               
%         cfg = [];
%         cfg.channel     = sort([eeg_channels channels.eog]);
%         data_eeg = ft_preprocessing(cfg, data_eeg);
%                 
%         data_eeg.cfg.dataname = dsname; % custom name of the dataset
%         data_eeg.cfg.dataset = dsname; % custom name of the dataset
%         
%         EEG = sc_ft2eeglab(data_eeg); % !!! must be called EEG - eeglab formalism    % conversion to eeglab in order to use AAR toolbox
%         EEG = pop_crls_regression2( EEG, channels.eog , 3, 0.9999, 0.01 ); %eog channels must be specfied in EX_SETUP in order to run crls regression
%         
%         data_eeg.trial = eeglab2fieldtrip(EEG, 'raw', 'none').trial;     % conv data back to ft - only the data matrix
%         
%         % remove EOG channels
%         cfg = [];
%         cfg.channel = [eeg_channels];
%         data_all_prep_eogcorr(ds) = ft_preprocessing(cfg, data_eeg);

        %%% end of temporary EOG corr
        
        
        
        data_prep=data
        
%   infile_bdf{ds} = replace( infile{ds}, fullfile(rc.analysisName, '/1_PREPROCESSED'), '0_bdf');
%     infile_bdf{ds} = replace( infile_bdf{ds}, '_PREP.mat', '.bdf');  %mmw
%     
%     if isempty( data_all_prep(ds).hdr )
%         error(['There is no data in data_all_prep(',num2str(ds),').'] );
%     end
    
%     disp( [ '[' num2str( round( 100 * ds / length(infile) ) ) '%] Ds: ', num2str(ds) ' is being segmented' ]);
    event_type = 'frontpanel trigger'; 
    detect_flank = 'up';
    % segmentation
    cfg=[];
    cfg.datafile           = dsname %infile_bdf{ds};   % the original bdf file (with data+header) needs to be provided; ft_definetrial(cfg, data_eeg) would not work as data_eeg contains only EEG channels from which trigger info was dropped
    cfg.headerfile         = dsname %infile_bdf{ds};   % has to be specified too
    cfg.trialdef.eventtype  = event_type; % '?' to look up full trigger list
% cfg.trialdef.eventtype  = '?'
    cfg.trialdef.detectflank = detect_flank;
    cfg.trialdef.prestim    = 0.1 %seg.prestim;
    cfg.trialdef.poststim   = 1 %seg.poststim;
     cfg.trialfun   = 'ft_trialfun_general';
    
    % checking for recodding | in case recodding is needed, the parameter 'recod_fun_to_call' should be specified in EX_SETUP (in the directory where the data is stored)
%     if exist('recodeFn')
%         
%         cfg_trigconfig = ft_definetrial(cfg);
%         cfg_trigconfig_eogcorr = cfg_trigconfig;
%         formula_to_call = strcat( recodeFn , '(data_all_prep(ds) , ds, cfg_trigconfig, trig_list);'); %building recodding function
%         formula_to_call_eogcorr = strcat( recodeFn , '(data_all_prep_eogcorr(ds) , ds, cfg_trigconfig_eogcorr, trig_list);'); %building recodding function
%         [ data_all_prep(ds) , cfg_trigconfig ] = eval(formula_to_call); %calling recodding function with all its parameters
%         [ data_all_prep_eogcorr(ds) , cfg_trigconfig_eogcorr ] = eval(formula_to_call_eogcorr); %calling recodding function with all its parameters
%         
%     else
        
        cfg.trialdef.eventvalue = [1   2  11  12  13  14  15  16  17  31  99] %trig_list;
        cfg_trigconfig = ft_definetrial(cfg);
        
data_prep_segm = ft_preprocessing(cfg_trigconfig, data_prep ) %data_all_prep(ds) );
        %         data_all_prep(ds) = ft_preprocessing(cfg_trigconfig, data_prep ) %data_all_prep(ds) );
%         data_all_prep_eogcorr(ds) = ft_preprocessing(cfg_trigconfig, data_all_prep_eogcorr(ds) );
%         
%     end
    
data_prep_segm2 = ft_redefinetrial(cfg_trigconfig, data_prep_segm );
    

    data_all_segm(ds) = ft_redefinetrial(cfg_trigconfig, data_all_prep(ds) );
    data_all_segm_eogcorr(ds) = ft_redefinetrial(cfg_trigconfig_eogcorr, data_all_prep_eogcorr(ds) );
    
    if strcmp(seg.studyType, 'RS')   %EVENT RELATED STUDY DESIGN
        cfg = [];   % segmenting of RS data based on time
        cfg.length = rsSegment;
        data_all_segm(ds) = ft_redefinetrial(cfg, data_all_segm(ds));
        data_all_segm_eogcorr(ds) = ft_redefinetrial(cfg, data_all_segm_eogcorr(ds));
    end
    
    data_all_segm(ds).hdr.dsname = data_all_prep(ds).hdr.dsname;
    data_all_segm_eogcorr(ds).hdr.dsname = data_all_prep_eogcorr(ds).hdr.dsname;
   
        
