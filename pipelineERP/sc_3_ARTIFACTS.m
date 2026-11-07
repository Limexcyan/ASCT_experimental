%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ARTIFACT REJECTION %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function provides code for artifact rejection.

% The first stage rejects trials which are exceptionally bad.
% Parameters such as 'th_tr' and 'survive_factor_tr' should be specified.
% If numer of trials which are ment to be rejected exceeds 'survive_factor_tr' entire ds is removed from analysis.

% Second stage either interpolates exceptionally bad channels or removes entire ds (if more than 8 channels are exceptionally bad)
% Parameters such as:
% limit_ch = 8; % sets number of channels that can be recovered by interpolation of neighbouring channels
% limit_ch_2 = 4; % sets second channel limit (if number of chanelles to be recovered exceeds this limit, th_var will be calculated differently)
% th_ch = 700; % threshold above which channles must not exceed. If there is limit_ch or more channles exceeding this threshold entire DS is rejected
% th_rej = 500; % final threshold taken for reparation of channels. If any channel exceeds this value it will be recovred by interpolation
% should be specified

% Third stage rejects muscle artifacts
% parameters for MUSCLE and RANGE artifacts rejection:
% m_hp = 35; % lowpass filter specification for muscle rejection
% m_lp = 45; % highpass filter specification for muscle rejection
% m_ord = 8; % muscle filter order
% m_type = 'but';
% m_th = 20; % muscle z-value (converted threshold) for given lp and hp filter specification
% m_art_padding = 0.05;
% m_trl_padding = 0.05;
% m_flt_padding = 0.05;

% Fourth stage considers range artifacts within each trial.
% If less than 4 channels exceeds threshold it interpolates those channels. If more than four, it removes entire trials.
% Parameters such as:
% th_r = 100; % range threshold specification
% limit_r = 4; % number of channels that still can exceed r_th and be repaired for this given trial. If there is more than r_limit channles exceeding r_th entire trial is rejected
% should be speficied


clear data_all_interp data_all_arj REPORT_1_trials REPORT_2_channels REPORT_2_full_interp REPORT_3_muscle REPORT_4_range

%% loading data (if specified in load_read = 'L' %%%


if strcmp(rc.load_segm, 'L') || ~exist('data_all_segm')

    if ~exist('data_all_segm'); disp('No data in memory, loding from datafiles'); end

    clear data_all_segm
    loadFolder = [analysisFolder '/2_SEGMENTED' ];

    % reading 'infile' file
    if exist(loadFolder)
        infile_all = sc_reading(loadFolder, '*SEGM.mat');
        infile = infile_all;
    else
        error( ['There is no infile file in the /2_SEGM folder.' , newline, 'Most likely segmented data havent been saved'] );
    end

    if exist('begId') && exist('endId')
        infile = infile_all(begId : endId);   %mmw
    end

    parfor ds = 1 : length(infile)

        if isempty(infile{ds})
            error(['There is no data in infile(',num2str(ds),').' newline, 'It may happen that due to begId and length(infile) speficifaction this ds has not been segmented earlier'] );
        else
            disp([' [' num2str( round( 100 * ds / length(infile) ) ) '%] Loading SEGM DS', num2str(ds), ' - ', infile{ds}] );  %mmw

            [~, dsname, infileext] = fileparts(infile{ds});
            load_file = [loadFolder '/' dsname infileext];   %TODO  infileext remove
            tmpdata = load( load_file, 'data_segm' );
            data_all_segm(ds) = tmpdata.data_segm;
        end
    end
end

clear infileext  tmpdata
%in this script saveFolfer must be specified at the begining due to REPORT files which are saveed after each stage of artifact rejection.

saveFolder = fullfile(analysisFolder, '3_ARTIFREE');
if ~exist(saveFolder); mkdir(saveFolder); end

if ~exist('begId'); begId=1; end


%%  TEMPORARY SCZEPAN I OSCYLACJE TRIGGERÓW !!!!!!

% for ds = 1 : length(data_all_segm)
%
%     DATA = data_all_segm(ds);
%     minoffset = floor(256*0.7);
%     ovl = zeros(length(DATA.trial),1);
%
%     for t = 1:length(DATA.trial)-1
%
%         if DATA.sampleinfo(t+1) - DATA.sampleinfo(t) < minoffset
%             ovl(t+1)=1;
%         end
%   end
%
%     if any(ovl)>0
%         ttk = [];
%
%         for t = 1:length(ovl)
%             if ovl(t) == 0; ttk =  [ttk t]; end
%         end
%
%         if ovl(length(ovl)) == 0; ttk =  [ttk length(ovl)]; end
%
%         cfg = [];
%         cfg.trials = ttk;
%         data_all_segm(ds) = ft_preprocessing(cfg, DATA);
%
%         warning ('TRIALS OVERLAPPED !!!!!');
%         warning ('TRIALS OVERLAPPED !!!!!');
%         warning ('TRIALS OVERLAPPED !!!!!');
%         warning ('TRIALS OVERLAPPED !!!!!');
%         warning ('TRIALS OVERLAPPED !!!!!');
%
%     end
% end



%% VARIANCE OF TRIALS   %%%%%%%%%%

%this block of code calculates variation for each trial and each channel. Subsequnetly variation for given DS can be calculated.


% for ds = 1 : length(data_all_segm)   %TEMP for SZCZEPAN
%
%     DATA = data_all_segm(ds);
%     minoffset = floor(256*0.7);
%     ovl = zeros(length(DATA.trial),1);
%
%     for t = 1:length(DATA.trial)-1
%         if DATA.sampleinfo(t+1) - DATA.sampleinfo(t) < minoffset
%             ovl(t+1)=1;
%         end
%     end
%
%     ttk = [];
%
%     for t = 1:length(ovl)
%         if ovl(t) == 0
%             ttk =  [ttk t];
%         end
%     end
%
%     if ovl(length(ovl)) == 0
%         ttk =  [ttk length(ovl)];
%     end
%
%
% cfg = [];
% cfg.trials = ttk;
% DATA_TRIM = ft_preprocessing(cfg, DATA);
%
% data_all_segm(ds) = DATA_TRIM;
%
% disp('repairing DS.....');
%
% end


for ds = 1 : length(data_all_segm)
    if isempty( data_all_segm(ds).hdr )
        error(['There is no data in data_all_segm(',num2str(ds),').'] );
    else
        var_level = []; % first index refers to channels, second to trials (and after averaging to DS).
        for tr = 1 : length( data_all_segm(ds).trial )
            % calculating variance for each channel for each trial
            dat = data_all_segm(ds).trial{tr};
            var_level(: , tr) = nanstd(dat, [], 2).^2; %first index refers to channels, second to trials. this line calculates variation of each channel for a given trial
        end
        noeegchan = sort(find(~strcmp(data_all_segm(ds).hdr.chantype, 'eeg')), 'descend');
        for c = noeegchan; var_level(c,:) = []; end  % removing no eeg chans

        var_tr{ds} = trimmean( var_level , 10, 1); % var_tr contains a row of var for each trial (each trial has been averaged over all channels). 10% of extreme channels are rejected by applying treammean - it reffers to 8 worst and 8 best channels. we agreed that 8 worst channels can be interpolated, thus triming is applied
        disp( ['For DS: ' num2str(ds) ' no of trials with var. over ' num2str(th_tr) '(th_var) = ' num2str( length( find( var_tr{ds} > th_tr) ) ) ] );
    end
end


%% REJECTION OF TRIALS (or DS) based on trial variance %%%%

% this block of code removes trials with variance exceeding th_tr or removes an entire DS

ds_rej = []; %contains list of ds to be rejected
REPORT_1_trials = ' '; %contains report for rough trials rejection

% rejection of trials

for ds = 1 : length(data_all_segm)  %mmw

    [~, dsname, ~] = fileparts(infile{ds});
    disp( [' [' num2str(round( ds/length(infile) *100)) '%] DS: ', num2str(ds), ' - ', dsname, ' Artf rejection, part I (bad trials)' ]);    %mmw

    if length( find( var_tr{ds} > th_tr) ) > survive_factor_tr * length( data_all_segm(ds).trial ) %checks number of trials for which variation (avergaed over channels) exceed th_tr. If this number exceeds survive_factor_tr then entire DS is removed
        ds_rej = [ds_rej ds]; %saves DS to be rejected when too many bad trials.
        curr_bad_tr = ['WARNING: DS: ', num2str(ds), '-', dsname, ' has at least ', num2str( survive_factor_tr * length( data_all_segm(ds).trial ) ), ' trials with var over: ', num2str(th_tr),'. It will be rejected from further analysis'];
        REPORT_1_trials = [REPORT_1_trials, newline, curr_bad_tr]; %saves info about given DS to the report
        warning(curr_bad_tr);
    else
        tr_to_rej = find( var_tr{ds} > th_tr ); %finds trials which var (averaged over channels) exceed th_tr and mark them as artifacts

        if length( find( var_tr{ds} > th_tr) ) == 0
            curr_bad_trial = ['DS: ', num2str(ds+begId-1), ' - ', dsname, ' - trials removed: ', num2str( length( find( var_tr{ds} > th_tr) ) ), ' (', num2str( round( 100* length( find( var_tr{ds} > th_tr) )/ length( data_all_segm(ds).trial ) ) ), '%);'];   % bad_channel trasponse - very important ;)
        else
            curr_bad_trial = ['DS: ', num2str(ds+begId-1), ' - ', dsname, ' - trials removed: ', num2str( length( find( var_tr{ds} > th_tr) ) ), ' (', num2str( round( 100* length( find( var_tr{ds} > th_tr) )/ length( data_all_segm(ds).trial ) ) ), '%); deleted: ', num2str(tr_to_rej)  ];
        end
        REPORT_1_trials = [REPORT_1_trials, newline, curr_bad_trial];

        artifact_trials = [];

        for tr = 1: length(tr_to_rej)
            artifact_trials(tr , :) = data_all_segm(ds).sampleinfo( tr_to_rej(tr) , :); %crating artifacts matrix (same as for threshold artifacts)
        end

        cfg = [];
        cfg.artfctdef.threshold.artifact   = artifact_trials;
        data_all_interp(ds) = ft_rejectartifact( cfg, data_all_segm(ds) ); %rejecting artifacts (if no artifacts found just saving data_all_segm to data_all_interp)
    end

end

% rejection of DS where too many bad trials were detected
ds_rej = sort(ds_rej , 'descend');  %sorting datasets in decreasing direction in order to avoid index mismatching while removing them

for ds = ds_rej
    if ds == length(data_all_segm)
        %removes information only from infile, since data_all_interp(ds_rej) hasn't been even created (it is last index)
        disp ( ['DS', num2str(ds), ' has been rejected from data']) ;
        infile{ds} = [];
        infile(ds) = [];

    else
        disp ( ['DS', num2str(ds), ' has been rejected from data']) ;
        data_all_interp(ds) = [];
        infile{ds} = [];
        infile(ds) = [];
    end
end

disp(REPORT_1_trials);

file_name = fullfile( saveFolder, '_REPORT_1_trials.mat');
save(file_name , 'REPORT_1_trials');


%% VARIANCE OF CHANNELS %%%%%%%%%%

% this block of code interpolates channels clasified as 'bad'. Interpolation is applied to all trials.
% (later block of code, dealing with RANGE, interpolates channels in individual trials)

clear var_ch var_level_sorted var_ch_sorted

if ~exist('data_all_interp')
    error('NO SINGLE DS SURVIVED AR. TERMINATING...')
end

for ds = 1 : length(data_all_interp)
    var_level = []; % first index refers to channels, second to trails (and after averaging to DS).
    cfg = [];
    for tr = 1 : length( data_all_interp(ds).trial )
        cfg.trl(1,1) = 1; cfg.trl(1,2) = length( data_all_interp(ds).trial{tr} );   %len of the whole data
        cfg.trl(1,3) = 0; cfg.trl(1,4) = 1;   % a trick to produce trl definition, instead of using ft_definetrials as we had no clear idea how to ask it for using the whole data (for bad chan rejection)
        % calculating variation for each channel for each dataset
        dat = data_all_interp(ds).trial{tr};
        var_level(: , tr) = nanstd(dat, [], 2).^2;
    end

    for c = noeegchan; var_level(c,:) = []; end  % removing no eeg chans

    var_level_sorted = sort(var_level, 2, 'descend');
    var_ch(: , ds) = trimmean( var_level_sorted( : , 1:fix(size( var_level_sorted, 2 ) /2 )) , 0, 2); % averaging for columns -> var_var_ch = 68x90 == channels x nr_triggers  |sort in decreasing direction, take half worst | trimmean rejecting 10%     %CHECK why take half worst?
end

var_ch_sorted = sort( var_ch, 1 ,'descend' );


%% INTERPOLATION %%% - IDENTYFYING BAD CHANNELS AND INTERPOLATING THEM

REPORT_2_channels = ' '; %here entire report about Ist stage of artifact rejection will be saved. It specifies intepolated channels for each DS as well as removed DS.

ds_rej = []; %vector with datasets to be rejected
th_var = {};
REPORT_ch = [];

for ds = 1 : length(data_all_interp)  %mmw

    [~, dsname, ~] = fileparts(infile{ds});
    disp( [' [' num2str( round((ds-begId)/(length(data_all_interp) - begId) * 100)) '%] DS: ', num2str(ds), ' - ', dsname, ' Artf rejection, part I (Interpolation)' ]);

    [igr_ch_var(ds), ~, q3_ch_var(ds)] = sc_iqr(var_ch(:,ds)); %calculates iqr of channels for given DS

    %saving values of thresholds
    th_ch_var(ds).val = q3_ch_var(ds) + th_chIQR*igr_ch_var(ds);
    th_ch_var(ds).iqr = th_chIQR;

    bad_channels = find( var_ch(:,ds) > th_ch_var(ds).val );
    curr_bad_ch = ' ';
    curr_bad_ch_dev = [];

    for i = 1 : length(bad_channels)
        if i < length(bad_channels)
            curr_bad_ch = strcat(curr_bad_ch, data_all_interp(ds).label{bad_channels(i)}, ', ');
        else
            curr_bad_ch = strcat(curr_bad_ch, data_all_interp(ds).label{bad_channels(i)});
        end
        curr_bad_ch_dev(i) = (var_ch(bad_channels(i),ds) - q3_ch_var(ds) )/ igr_ch_var(ds);
    end

    curr_bad_ch = ['DS: ', num2str(ds), '-', dsname, ' outlier chs: ', curr_bad_ch ];   % bad_channel trasponse - very important ;)
    REPORT_ch = [REPORT_ch, newline, curr_bad_ch, ' (igr dev: ',  num2str(curr_bad_ch_dev, '%.1f '), ')'];

    curr_bad_ch = ' ';

    for i = 1 : length(bad_channels)
        curr_bad_ch = strcat(curr_bad_ch, data_all_interp(ds).label{bad_channels(i)}, ', ');
    end

    %%% INTERPOLATION

    %DEFNING NEIGHBOURS
    cfg = [];
    cfg.method = 'triangulation';
    neighbours = ft_prepare_neighbours(cfg, data_all_interp(ds) ) ;

    %REPARING CHANNELS
    cfg =[];
    cfg.neighbours = neighbours; % - DEFINED ABOVE
    data_all_interp(ds)  = ft_preprocessing(cfg, data_all_interp(ds) );
    cfg.method = 'average'; %'weighted', 'average', 'spline', 'slap' or 'nan' (default = 'weighted')  %mmw
    cfg.badchannel = data_all_interp(ds).label(bad_channels);
    if ~isempty(cfg.badchannel)
        data_all_interp(ds) = ft_channelrepair(cfg, data_all_interp(ds) );
    end

    badchannelsds{ds} = bad_channels;
end

for ds = 1 : length(data_all_interp)  %mmw
    if length(badchannelsds{ds}) >= limit_ch
        ds_rej = [ds_rej, ds]; %save indexes of subjects to be removed
    end
end

writematrix(REPORT_ch, fullfile(saveFolder, '_REPORT_ch.txt'));

% REMOVING SUBJECTS when too many bad channels detected

ds_rej = sort(ds_rej , 'descend');  %sorting subjects in decreasing direction in order to avoid index mismatching while removing them


for ds = ds_rej
    disp ( ['ds ', num2str(ds), ' has been REJECTED from the datasets']) ;
    data_all_interp(ds) = []; %additionally removes
    infile{ds} = [];
    infile(ds) = [];
end

disp (REPORT_2_channels);

REPORT_2_full_interp.report = REPORT_2_channels;
REPORT_2_full_interp.var_ch = var_ch;
REPORT_2_full_interp.var_ch_sorted = var_ch_sorted;
REPORT_2_full_interp.th_var = th_var;

file_name = fullfile(saveFolder , '_REPORT_2_full_interp.mat');
save(file_name , 'REPORT_2_full_interp');
file_name = fullfile(saveFolder , '_INTERP_infile.mat');
save(file_name, 'infile');

ds_rej = [];    %mmw

saveFolder = [ analysisFolder '/3_ARTIFREE'];

%% RE-REFERENCING %%%%%%%%%

if strcmp(chan.ref_method, 'AVG')

    disp('Re-referencing to AVG...');

    for ds = 1 : length(data_all_interp)  %mmw

        [~, dsname, ~] = fileparts( infile{ds} ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type
        disp( ['[' num2str(round( 100*(ds-begId+1)/(length(infile)-begId+1))) '%] DS: ', num2str(ds), ' - ' , dsname, ' is being re-referenced' ]);

        %optional rereferencing (if specified in EX_SETUP)
        if strcmp(chan.ref_method , 'AVG') || strcmp(chan.ref_method , 'avg')
            eegchan = find(strcmp(data_all_interp(ds).hdr.chantype, 'eeg'));
            noeegchan = find(~strcmp(data_all_interp(ds).hdr.chantype, 'eeg'));
            disp('rereferncing to AVG...');
            cfg = [];
            cfg.reref  = 'yes';
            % cfg.channel = eegchan;
            cfg.refmethod = 'avg';
            cfg.refchannel = eegchan;
            dataoryg = data_all_interp(ds).trial;
            data_all_interp(ds) = ft_preprocessing(cfg,data_all_interp(ds));
            for c = noeegchan  % retaining original non eeg sig before reference
                for t = 1:length(dataoryg)
                    data_all_interp(ds).trial{t}(c,:) = dataoryg{t}(c,:);
                end
            end
        end
    end
end


%% MUSCLE %%%%%%%%%%%%%%%%%

for ds = 1 : length(data_all_interp) %mmw  parpool (8) seems to be safe

    [~, dsname, ~] = fileparts( infile{ds} ); % extract file path, data set name, and extension
    disp( [ '[' num2str( round( 100 * ( ds-begId+1 ) / ( length(data_all_interp) - begId + 1) ) ) '%] DS: ', num2str(ds), ' - ', dsname 'Artifact rejection - II - Muscle' ] );    %mmw

    eegchan = find(strcmp(data_all_interp(ds).hdr.chantype, 'eeg'));

    if ~exist('m_ord'); m_ord=8; end % defaults
    if ~exist('m_type'); m_type = 'but'; end % defaults
    
    cfg=[];
    cfg.artfctdef.muscle.bpfilter    = 'yes';
    cfg.artfctdef.muscle.bpfreq      = [m_hp m_lp];
    cfg.artfctdef.muscle.bpfiltord   = m_ord;
    cfg.artfctdef.muscle.bpfilttype  = m_type;
    cfg.artfctdef.muscle.hilbert     = 'yes';
    cfg.artfctdef.muscle.boxcar      = 0.5;
    cfg.artfctdef.muscle.channel     = eegchan; %data_all_interp(ds).hdr.label; %Nx1 cell-array with selection of channels, see FT_CHANNELSELECTION for details
    cfg.artfctdef.muscle.cutoff      = m_th; %z-value at which to threshold
    cfg.artfctdef.muscle.artpadding  = 0.1; %m_art_padding; % extension of time-range around data which is extending filter value
    cfg.artfctdef.muscle.trlpadding  = 0.1; %m_trl_padding; % extension of trial
    cfg.artfctdef.muscle.fltpadding  = 0.1; %m_flt_padding;
    cfg.artfctdef.muscle.interactive = 'no'; %specify 'yes' in case you want this part of artifact rejection to be interactive

    [cfg, artifact_muscle] = ft_artifact_muscle(cfg, data_all_interp(ds)); % this function saves to 'cfg.artfctdef.muscle.artifact' an array with artifact. It is also saved in 'artifact_muscle'.
    data_all_arj(ds) = ft_rejectartifact(cfg, data_all_interp(ds)); %needs to be called in order to reject artifact from actual data. Knows artifacts from cfg saved while calling ft_artifact_muscle

    % saving reports
    REPORT_3_muscle(ds).ntr = length( data_all_interp(ds).trial ) - length( data_all_arj(ds).trial );
    REPORT_3_muscle(ds).per = 100 * ( length(data_all_interp(ds).trial) - length(data_all_arj(ds).trial) ) / length(data_all_interp(ds).trial);

end

file_name = [saveFolder, '/_REPORT_3_muscle.mat'];
save(file_name , 'REPORT_3_muscle');

%% RANGE %%%%%%%%%%%%%%%%%

ds_rej_par=[]; %mmw
ds_rej_par=zeros(1,length(data_all_arj)); %mmw

parfor ds = 1 : length(data_all_arj)  %mmw PARFOR

    data_arj_curr=data_all_arj(ds);
    eegchan = find(strcmp(data_all_arj(ds).hdr.chantype, 'eeg'));

    [~, dsname, ~] = fileparts( infile{ds} ); % extract file path, data set name, and extension
    disp( [ '[' num2str( round( 100 * ( ds-begId+1 ) / ( length(data_all_arj) - begId + 1) ) ) '%] DS: ', num2str(ds), ' - ', dsname ': ARTifact REJection - II - Range' ] );

    cfg = [];
    cfg.continuous = 'no'; % allows for trial-like data scanning
    cfg.artfctdef.threshold.range     = th_r; %reads range threshold - suggested 75, 100 or 125
    cfg.artfctdef.threshold.channel   = eegchan; %data_arj_curr.hdr.label; %reads labels of channels
    cfg.artfctdef.threshold.bpfilter = 'no';

    %calculate artifact (trials that should be completely rejected) as well as tr_to_repair which are trials for which interpolation method is applied
    [cfg, artifact_range, tr_to_repair] = sc_ft_artifact_threshold(cfg, data_arj_curr, limit_r);

    ntr_before = length( data_arj_curr.trial ); %remembers number of trials before rejection
    nch = 0; %sets number of repaired channles to zero for each loop iteration

    %goes through all instances of tr_to_repair and repairs given trials

    for tr = 1 : length(tr_to_repair)
        if ~isempty( tr_to_repair{tr} )
            nch = nch + length( tr_to_repair{tr} );
            disp( [ newline, 'For DS: ' , num2str(ds) , ' trial: ' , num2str(tr), ' repair: ', num2str( reshape( tr_to_repair{tr}', 1, [])) ] )
            cfg = [];
            cfg.method = 'triangulation';
            % cfg.method = 'template';
            % cfg.template = '_biosemi64_neighb.mat';  % cfg.elec          = structure with electrode positions or filename, see FT_READ_SENS or    cfg.layout        = filename of the layout, see FT_PREPARE_LAYOUT to be put in the future
            neighbours = ft_prepare_neighbours(cfg, data_arj_curr ) ;
            %REPARING CHANNELS
            cfg =[];
            cfg.neighbours = neighbours; % - DEFINED ABOVE
            data_arj_curr  = ft_preprocessing(cfg, data_arj_curr);
            cfg.method = 'average';
            % cfg.method = 'weighted'; %'weighted', 'average', 'spline', 'slap' or 'nan' (default = 'weighted')  %mmw -> weighted
            cfg.badchannel = data_arj_curr.label( tr_to_repair{tr}' );
            cfg.trials = tr;
            data_arj_curr.trial{tr} = ft_channelrepair(cfg, data_arj_curr ).trial{1}; % should be 1 at the end since we repair it here trial by trial (there is only one trial in output of ft_channelrepair
        end
    end

    %needs to be called in order to really remove data from our dataset
    cfg = [];
    cfg.artfctdef.threshold.artifact   = artifact_range;
    cfg.artfctdef.threshold.interactive='yes';
    try %mmw try/catch
        data_arj_curr = ft_rejectartifact(cfg, data_arj_curr );
    catch
        %ds_rej(length(ds_rej)+1) = ds;
        ds_rej_par(ds) = 1;
    end

    %saving reports
    REPORT_4_range(ds).ntr = ntr_before - length(data_arj_curr.trial);
    REPORT_4_range(ds).pro = 100 * ( ntr_before - length(data_arj_curr.trial) ) / ntr_before ;

    REPORT_4_range(ds).nch = nch;
    REPORT_4_range(ds).nch_pro = 100 * nch / (length(data_arj_curr.trial).*length(data_all_interp(ds).label)) ;

    REPORT_4_range(ds).ntrialsremaining = size(data_arj_curr.trialinfo,1);

    dsname = strrep(dsname, '_SEGM', '');
    dsname = strrep(dsname, '_PREP', '');
    dsname = strcat(dsname, '_ARJ');
    disp( [ '[' num2str(round( 100* (ds)/(length(data_all_arj)) ) ) '%] Saving ARTIFACT FREE: ', num2str(ds), ' - ', dsname] );

    file_name = strcat(saveFolder, '/', dsname);
    data_artf = data_arj_curr;
    data_artf.hdr.dsname = dsname;
    sc_parsave_arj(file_name, data_artf);

end

clear data_arj_curr

range_file = [saveFolder '/_REPORT_4_range.mat'];
save(range_file , 'REPORT_4_range');

%% SAVE %%%


file_name = fullfile(saveFolder, '_ARTF_param.mat');
save(file_name, 'limit_ch', 'm_lp', 'm_hp', 'm_th', 'limit_r');

file_name = fullfile(saveFolder, '_ARTF_infile.mat');
save(file_name, 'infile');
