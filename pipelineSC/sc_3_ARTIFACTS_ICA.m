%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% ARTIFACT REJECTION %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function provides code for artifact rejection before ICA decomposition

% The first stage reject trials which are exceptionally bad.

% First stage either removes exceptionally bad channels or removes entire ds (if more than 8 channels are exceptionally bad)
% Parameters such as:
% ar.chRmLimit = 8; % sets number of channels that can be recovered by interpolation of neighbouring channels
% ar.ch_th = 700; % threshold above which channles must not exceed. If there is ar.chRmLimit or more channles exceeding this threshold entire DS is rejected (obsolete)
% th_rej = 500; % final threshold taken for reparation of chan. If any channel exceeds this value it will be recovred by interpolation
% should be specified

% Second stage take care about range artifacts within each trial.
% If more than limi_r channels exceeds threshold entire ds is removed
% th_r = 125; % range threshold specification
% limit_r = 4; % number of channels that still can exceed r_th and be repaired for this given trial. If there is more than r_limit channles exceeding r_th entire trial is rejected
% should be speficied

saveFolder = fullfile (rc.analysisFolder, '3_ARTIFREE');

if ~exist(saveFolder)
    mkdir(saveFolder);
end

clear data_all_arj REPORT.trials REPORT_2_channels REPORT_2_full_interp REPORT_3_muscle REPORT_4_range var_ch data_all_segm  data_all_segm_eogcorr data_all_arj data_all_arj_eogcorr

%%% loading data

loadFolder = fullfile(rc.analysisFolder, '2_SEGMENTED');

% reading 'infile' file
if exist(loadFolder)
    infile_all = sc_reading(loadFolder, '*SEGM.mat');
    infile = infile_all;
else
    error( ['There is no infile file in the /2_SEGMENTED folder.' , newline, 'Most likely segmented data havent been saved'] );
end

if exist('begId') && exist('endId')
    infile = infile_all(begId : endId);
end

if ~exist('begId'); begId=1; end

parfor  ds = 1 : length(infile)

    if isempty(infile{ds})
        error(['There is no data in infile(',num2str(ds),').' newline, 'It may happen that due to begId and length(infile) speficifaction this ds has not been segmented earlier'] );

    else
        disp(strcat(' [', num2str( round( 100 * ds / (length(infile)) ) ), '%] Loading DS', num2str(ds), ' - ', infile{ds}, ' file - segm data') );
        [~, dsname, ~] = fileparts(infile{ds});
        load_file = char(infile{ds});
        %             display(ds);
        data_segm_tmp = load( load_file, 'data_segm' );
        data_all_segm(ds) = data_segm_tmp.data_segm;
        load_file = replace(infile{ds}, '_SEGM.mat', '_SEGM_EOGcorr.mat');
        if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
            data_segm_eogcorr_tmp = load( load_file, 'data_segm_eogcorr' );
            data_all_segm_eogcorr(ds) = data_segm_eogcorr_tmp.data_segm_eogcorr;
        end
    end
end

clear data_segm_eogcorr_tmp data_segm_tmp
for  ds = 1 : length(infile)
    infile{ds} = replace(infile{ds}, '_SEGM.mat', '.mat');
end

if ~exist('begId'); begId=1; end

if strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim')
    for ds = 1 : length(data_all_segm)
        dsname = data_all_segm(ds).hdr.dsname;
        disp( 'Skipping artifact rejection stage for simulated data. Saving unchanged results...');
        file_name = fullfile(saveFolder, strcat(dsname, '_ARJ.mat'));
        data_artf = data_all_segm(ds);
        save(file_name, 'data_artf');
    end
    return;
end


%% CONSISTENCY CHECK %%%

if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
    if length(data_all_segm) ~= length(data_all_segm_eogcorr); error('CONSISTENCY CHECK FAILED: size of PREP data not equal to PREP_EOGcorr data. ABORTING.'); end
    for i = 1;length(data_all_segm)
        if ~strcmp(data_all_segm(i).hdr.dsname, data_all_segm_eogcorr(i).hdr.dsname); error('CONSISTENCY CHECK FAILED: ds names do not match between PREP and PREP_EOGcorr data. ABORTING.'); end
    end
end

%% SAMPLEINFO RECREATE if missing

if ~isfield(data_all_segm(1), 'sampleinfo')
    data_all_segm2 = data_all_segm;
    for ds = 1 : length(data_all_segm)
        tmpout = sc_fixsampleinfo(data_all_segm2(ds));
        data_all_segm(ds).sampleinfo = [];
        data_all_segm(ds) = tmpout;
    end
    clear tmpout data_all_segm2;
end

%% VARIANCE OF [EOG-corrected TRIALS and CHANNELS %%%%%%%
%this block of code removes channels clasified as 'bad'.

disp ('Calculating variance of channels and trials for:');

for ds = 1 : length(data_all_segm)

    disp (['DS: ', num2str(ds), '/' num2str(length(data_all_segm))]);

    %%%%%%%% VARIANCE OF uncorrected TRIALS and CHANNELS %%%%%%%
    if rc.eeg
        meegchan_unc = [find(strcmp(data_all_segm(ds).hdr.actualchantype, 'eeg'))' find(strcmp(data_all_segm(ds).hdr.actualchantype, 'meg'))' find(strcmp(data_all_segm(ds).hdr.actualchantype, 'mag'))' find(strcmp(data_all_segm(ds).hdr.actualchantype, 'meggrad' ))' find(strcmp(data_all_segm(ds).hdr.actualchantype, 'megmag' ))'];
    else
        if length(data_all_segm(ds).label) == length(data_all_segm(ds).hdr.label)
        meegchan_unc = [find(strcmp(data_all_segm(ds).hdr.chantype, 'eeg'))' find(strcmp(data_all_segm(ds).hdr.chantype, 'meg'))' find(strcmp(data_all_segm(ds).hdr.chantype, 'mag'))' find(strcmp(data_all_segm(ds).hdr.chantype, 'meggrad'))' find(strcmp(data_all_segm(ds).hdr.chantype, 'megmag'))'];
        else
            error('inconsistent channel labels. this should not happen for MEG data. as it happened, check the code and fix')
        end
    end
    meegchan_unc_labels = data_all_segm(ds).label(meegchan_unc);

    var_uncorr_chantrial_ds = zeros( numel(meegchan_unc), length( data_all_segm(ds).trial ) );  % first index refers to channels, second to trails (and after averaging to DS).
    % end
    for tr = 1 : length( data_all_segm(ds).trial )
        dat = data_all_segm(ds).trial{tr}(meegchan_unc , : );
        var_uncorr_chantrial_ds(:,tr) = std(dat, [], 2, 'omitnan').^2;
    end

    if ar.chWorstFraction  % use only a worst (hihest variance) half of trials to estimate chan value. good for datasets with parial electrode failures (like sleep)
        var_uncorr_chantrial_ds_sorted = zeros( numel(meegchan_unc), tr);  % first index refers to channels, second to trails (and after averaging to DS).
        for cha = 1:size(var_uncorr_chantrial_ds,1)
            var_uncorr_chantrial_ds_sorted(cha,:) = sort(var_uncorr_chantrial_ds(cha,:));
        end
        var_uncorr_chantrial_ds = var_uncorr_chantrial_ds_sorted(:,1:ceil(tr/ar.chWorstFraction));
    end

    if ar.chTrimMean
        var_uncorr_ch{ds} = trimmean( var_uncorr_chantrial_ds, (100-ar.chTrimMean), 2); % averaging for columns -> channels x nr_triggers  
    else
        var_uncorr_ch{ds} = mean( var_uncorr_chantrial_ds, 2); 
    end

    var_uncorr_ch_sorted{ds} = sort( var_uncorr_ch{ds}, 'descend' );

    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg

        meegchan_eogcorr = find(strcmp(data_all_segm_eogcorr(ds).hdr.actualchantype, 'eeg'))';   % EOG correction relevant for EEG only
        meegchan_eogcorr_labels = data_all_segm_eogcorr(ds).label(meegchan_eogcorr);

        var_eogcor_chantrial_ds = zeros( numel(meegchan_eogcorr) , length( data_all_segm_eogcorr(ds).trial ) ); % first index refers to channels, second to trials (and after averaging to DS).
        for tr = 1 : length( data_all_segm_eogcorr(ds).trial )
            % calculating variance for each channel for each subject
            dat = data_all_segm_eogcorr(ds).trial{tr};
            var_eogcor_chantrial_ds(: , tr) = std(dat, [], 2, 'omitnan').^2;
        end

        if ar.chWorstFraction  % use only a worst (hihest variance) half of trials to estimate chan value. good for datasets with parial electrode failures (like sleep)
            var_eogcor_chantrial_ds_sorted = zeros( numel(meegchan_unc), tr);  % first index refers to channels, second to trails (and after averaging to DS).
            for cha = 1:size(var_eogcor_chantrial_ds,1)
                var_eogcor_chantrial_ds_sorted(cha,:) = sort(var_eoguncor_chantrial_ds(cha,:));
            end
            var_eogor_chantrial_ds = var_eogor_chantrial_ds_sorted(:,1:ceil(tr/chWorstFraction));
        end
              
        if ar.chTrimMean
            var_eogcor_ch{ds} = trimmean( var_eogcor_chantrial_ds, (100-ar.chTrimMean), 2); % trimmean 
        else
            var_eogcor_ch{ds} = mean( var_eogcor_chantrial_ds, 2); % averaging for columns == channels x nr_triggers 
        end

        var_eogcor_ch_sorted{ds} = sort( var_eogcor_ch{ds},'descend' );
    else
        var_eogcor_chantrial_ds = var_uncorr_chantrial_ds;
        var_eogcor_ch = var_uncorr_ch;
        var_eogcor_ch_sorted = var_uncorr_ch_sorted;
    end

    var_uncor_chantrial{ds} = var_uncorr_chantrial_ds;
    var_eogcor_chantrial{ds} = var_eogcor_chantrial_ds;

end

if(~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg  % if no eog corr available, use uncorrected variances
   meegchan_labels = meegchan_eogcorr_labels;
else
   meegchan_labels = meegchan_unc_labels;
end

clear var_uncorr_chantrial_ds var_eogcor_chantrial_ds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

REPORT_ch = ' '; %here entire report about Ist stage of artifact rejection will be saved. It specifies intepolated channels for each DS as well as removed DS.

ds_rej = []; %vector with subject to be rejected
thres_ch_var = {}; %contains info about current threshold of variance for chann rej
ch_rej = {}; %contains info which channels has been rejected for a given ds


%% REMOVE BAD CHANNELS (OR THE WHOLE DS if to many bad channels)

for ds = 1 : length(data_all_segm)

    dsname = data_all_segm(ds).hdr.dsname;
    disp( [' [' num2str(round(ds/(length(infile)) *100)) '%] DS: ', num2str(ds), ' - ', dsname, ' Artifact rejection - CHANNELS' ]);

    [iqr_ch_var(ds), q1_ch_var(ds), q3_ch_var(ds)] = sc_iqr(var_eogcor_ch{ds}); %calculates iqr of channels for given DS based on corrected (if available) vaules

    %saving values of thresholds
    thres_ch_var(ds).val_hi = q3_ch_var(ds) + ar.chIQR*iqr_ch_var(ds);    
    thres_ch_var(ds).iqr = ar.chIQR;
   
    bad_channels = find( var_eogcor_ch{ds} > thres_ch_var(ds).val_hi );  %hi activity

    bad_chan_labels = ' ';
    bad_chan_dv = [];

    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
      current_data_segm = data_all_segm_eogcorr(ds);
    else
      current_data_segm = data_all_segm(ds);
    end

    for i = 1 : length(bad_channels)
        if i < length(bad_channels)
            bad_chan_labels = strcat(bad_chan_labels, meegchan_labels{bad_channels(i)}, ', ');
        else
            bad_chan_labels = strcat(bad_chan_labels, meegchan_labels{bad_channels(i)});
        end
        bad_chan_dv(i) = (var_eogcor_ch{ds}(bad_channels(i)) - q3_ch_var(ds) ) / iqr_ch_var(ds);
    end

    clear current_data_segm

    bad_chan_labels = ['DS: ', num2str(ds), '-', dsname, ' outlier chs: ', bad_chan_labels ];   % bad_channel trasponse - very important ;)
    REPORT_ch = [REPORT_ch, newline, bad_chan_labels, ' (igr dev: ',  num2str(bad_chan_dv, '%.1f '), ')'];

    %channels rejection
    if length(bad_channels) > ar.chRmLimit
        ds_rej = [ds_rej ds]; % whole DS to be rejected.
        ch_rej(ds).list = []; % creates structure with bad_channels
        ch_rej(ds).iqrdev = []; %creates structure with bad_channels
        ds2remove(ds)=1;
        data_all_arj(ds).hdr.dsname = dsname;

    else
        cfg = [];
        ds2remove(ds) = 0;       
        ch2retain = data_all_segm(ds).label; %first selects all channels and then remove channels which are meant to be rejected || calling of select data chooses only those channels which has been selected as good
        ch2remove = {meegchan_labels{bad_channels}}';
        for ch = length(ch2retain):-1:1
            for chr = 1:length(ch2remove)
                if strcmpi(ch2retain(ch), ch2remove(chr))
                    ch2retain(ch) = [];
                    break;
                end
            end
        end
        cfg.channel = ch2retain;
        ch_rej(ds).list = ch2remove; %creates structure with bad_channels
        ch_rej(ds).iqrdev = bad_chan_dv'; %creates structure with bad_channels

        data_all_arj(ds) = ft_selectdata(cfg, data_all_segm(ds) );
        if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
            data_all_arj_eogcorr(ds) = ft_selectdata(cfg, data_all_segm_eogcorr(ds) );    % actual removal of bad channels (eog-corr data)
        end

    end

    bad_channels_nr{ds}=bad_channels;
end

if ~exist('data_all_arj')
error('All processed datasets rejected. Check AR settings')
end


% channel var plots
disp ('saving chan variance plots...')
parfor ds = 1 : length(data_all_arj)  %mw parfor
        
    figure('visible','off', 'NumberTitle', 'on');
    if ds2remove(ds)==0
        ttl = (['chan var sorted - DS: ' , data_all_arj(ds).hdr.dsname ]);
    else
        ttl = (['chan var sorted - DS: ' , data_all_arj(ds).hdr.dsname, ' - REMOVED' ]);
    end
    ttl = strrep(ttl, '_', '\_');
    title(ttl);
    hold on;
    set(gca,'FontSize',14)
    plot(var_uncorr_ch_sorted{ds});
    lege = ['iqr = ' num2str(thres_ch_var(ds).iqr, '%.1f')];
    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
        plot(var_eogcor_ch_sorted{ds});
        yline(thres_ch_var(ds).val_hi,'--g');
        legend('original', 'EOG-corrected', lege);
    else
        yline(thres_ch_var(ds).val_hi,'--g');
        legend('original', lege);
    end

    if ~exist (fullfile(saveFolder, 'chanvar'), 'dir')
        mkdir (fullfile(saveFolder, 'chanvar'))
    end

    print( fullfile(saveFolder, 'chanvar', strcat( data_all_arj(ds).hdr.dsname, '_chvar.jpg')),'-djpeg','-r100');
    close;

end


% REMOVE DS CATEGORIZED AS BAD  (too many bad channels) %

ds_rej = sort(ds_rej , 'descend');  %sorting subjects in decreasing direction in order to avoid index mismatching while removing them

disp (REPORT_ch);

REPORT.report = REPORT_ch;
REPORT.varnc_ch = var_uncorr_ch;
REPORT.varnc_ch_sorted = var_uncorr_ch_sorted;
if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
    REPORT.varcr_ch = var_eogcor_ch;
    REPORT.varcr_ch_sorted =  var_eogcor_ch_sorted;
end


writematrix(REPORT_ch, fullfile(saveFolder, '_REPORT_ch.txt'));


%% TRIAL REJECTION

% TRIAL VARIANCE

for ds = 1 : length(data_all_arj)

    if ~ismember(ds, ds_rej)   % skip if ds is to be rejected
        disp( [' [' num2str(round(ds/(length(infile)) *100)) '%] DS: ', num2str(ds), ' - ', dsname, ' Artifact rejection II - TRIAL Variance' ]);

        urtrial{ds} = 1:length(data_all_arj(ds).trial);

        var_uncorr_chantrial_ds = var_uncor_chantrial{ds};
        var_eogcor_chantrial_ds = var_eogcor_chantrial{ds};

        bad_channels =  sort(bad_channels_nr{ds}, 'descend');

        for i = 1:length(bad_channels)
            var_uncorr_chantrial_ds(bad_channels(i),:) =  [];
            var_eogcor_chantrial_ds(bad_channels(i),:) =  [];
        end


        varcr_chan_ds = mean(var_eogcor_chantrial_ds,1);  %average by chans
        [iqr_trial, q3_trial] = sc_iqr(varcr_chan_ds);
        varcr_trial_iqrth = q3_trial + ar.varIQR * iqr_trial;

        cfg = [];
        cfg.trials = find(varcr_chan_ds<=varcr_trial_iqrth);
        removedtr = find(varcr_chan_ds>varcr_trial_iqrth);

        data_all_arj(ds) = ft_selectdata(cfg, data_all_arj(ds) );

        if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
            data_all_arj_eogcorr(ds) = ft_selectdata(cfg, data_all_arj_eogcorr(ds) );
        end

        removedtriqrdv = [];
        for i = 1: length(removedtr)
            removedtriqrdv(i) = (varcr_chan_ds(removedtr(i)) - q3_trial )/ iqr_trial;
        end
        trial_rej(ds).varlist = find(varcr_chan_ds>varcr_trial_iqrth);
        trial_rej(ds).variqrdev = removedtriqrdv;


        for i = sort(removedtr, 'descend')
            urtrial{ds}(i)=[];
        end

        %saving reports
        REPORT.trial(ds).ntr_pre = size(varcr_chan_ds,2);
        REPORT.trial(ds).ntr_post = 0;
        REPORT.trial(ds).ntr_rmv = 0;
        REPORT.trial(ds).rmv_percent = 0;
        REPORT.trial(ds).ntr_var = numel(removedtr);
        REPORT.trial(ds).rmv_tr_var = removedtr;
        REPORT.trial(ds).ntr_ren = 0;
        REPORT.trial(ds).rmv_tr_ren = [];
        REPORT.trial(ds).ntr_msc = 0;
        REPORT.trial(ds).rmv_tr_msc = [];
        clear varnc_chan_ds var_eogcor_chantrial_ds varcr_chan_ds

    end
end



% recreate chantype field
data_all_arj = sc_fix_chantype(data_all_arj);


%% RANGE ARTIFACTS

if ar.rangeThr  % do only if range set as > 0

    for ds = 1 : length(data_all_arj)
        if ~ismember(ds, ds_rej)   % skip if ds is to be rejected ot range threshold set to zero

            dsname = data_all_arj(ds).hdr.dsname;  % retain additional fields

            disp( [' [' num2str(round(ds/(length(infile)) *100)) '%] DS: ', num2str(ds), ' - ', dsname, ' Artifact rejection III - TRIAL Range' ]);

            % RANGE

            cfg = [];
            cfg.continuous = 'no'; % allows for trial-like data scanning
            cfg.artfctdef.threshold.range     = ar.rangeThr; %reads range threshold - suggested 75, 100 or 125
            cfg.artfctdef.threshold.bpfilter = 'no';

            cfg.artfctdef.threshold.channel   =  find( strcmp(data_all_arj(ds).hdr.actualchantype,'eeg') | strcmp(data_all_arj(ds).hdr.actualchantype,'meg') | strcmp(data_all_arj(ds).hdr.actualchantype,'mag') | strcmp(data_all_arj(ds).hdr.actualchantype,'meggrad') | strcmp(data_all_arj(ds).hdr.actualchantype,'megmag')); %reads labels of channels
            if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
                [cfg_range, artifact_range] = ft_artifact_threshold(cfg, data_all_arj_eogcorr(ds));
            else
                [cfg_range, artifact_range] = ft_artifact_threshold(cfg, data_all_arj(ds));
            end

            removed_tr{ds} =[];
            removed_utr{ds} =[];
            artifactsr = unique(artifact_range(:,1:2),'rows');
            for trtr = 1:size(cfg_range.artfctdef.threshold.trl,1)
                for arar = 1:size(artifact_range,1)
                    trrange = cfg_range.artfctdef.threshold.trl(trtr,1):cfg_range.artfctdef.threshold.trl(trtr,2);
                    arrange = artifact_range(arar,1):artifact_range(arar,2);
                    if ismember(trrange, arrange)
                        removed_utr{ds} = [removed_utr{ds} , urtrial{ds}(trtr)];
                        removed_tr{ds} = [removed_tr{ds} , trtr];
                    end
                end
            end
            removed_utr{ds} = unique(removed_utr{ds});
            removed_tr{ds} = unique(removed_tr{ds});

            for i = sort(removed_tr{ds},'descend')
                urtrial{ds}(i) = [];
            end

            data_all_arj(ds) = ft_rejectartifact(cfg_range, data_all_arj(ds)); %needs to be called in order to reject artifact from actual data.

            data_all_arj(ds).hdr.dsname = dsname;  % restore additional fields
            % data_all_arj(ds).hdr.actualchantype = actualchantype;
            % data_all_arj(ds).hdr.urchantype = urchantype;
            % data_all_arj(ds).hdr.urchanlabel = urchanlabel;

            REPORT.trial(ds).ntr_ran = numel(removed_utr{ds});
            REPORT.trial(ds).rmv_tr_ran =removed_utr{ds};

            if isempty(removed_tr{ds})
                REPORT.trial(ds).ntr_ran = 0;
                REPORT.trial(ds).rmv_tr_ran =[];
            end

        end
    end

end


% recreate chantype field
data_all_arj = sc_fix_chantype(data_all_arj);


%% MUSCLE ARTIFACTS

for ds = 1 : length(data_all_arj)
    if ~ismember(ds, ds_rej)   % skip if ds is to be rejected

        dsname = data_all_arj(ds).hdr.dsname;
        disp( [' [' num2str(round(ds/(length(infile)) *100)) '%] DS: ', num2str(ds), ' - ', dsname, ' Artifact rejection IV - TRIAL Muscle contamination' ]);

        dsname = data_all_arj(ds).hdr.dsname;  % retain additional fields
        actualchantype = data_all_arj(ds).hdr.actualchantype;

        % MUSCLE

        chan2artf = [find(strcmp(data_all_arj(ds).hdr.actualchantype, 'eeg'))' find(strcmp(data_all_arj(ds).hdr.actualchantype, 'meg'))' find(strcmp(data_all_arj(ds).hdr.actualchantype, 'mag'))' find(strcmp(data_all_arj(ds).hdr.actualchantype, 'meggrad'))' find(strcmp(data_all_arj(ds).hdr.actualchantype, 'megmag'))'];

        removed_tr{ds} = [];

        cfg=[];
        cfg.artfctdef.muscle.bpfilter    = 'yes';
        cfg.artfctdef.muscle.bpfreq      = [ar.muscHP ar.muscLP];
        cfg.artfctdef.muscle.bpfilttype  = 'but';
        cfg.artfctdef.muscle.hilbert     = 'yes';
        cfg.artfctdef.muscle.boxcar      = 0.5;
        cfg.artfctdef.muscle.channel     = data_all_arj(ds).label(chan2artf); %Nx1 cell-array with selection of channels, see FT_CHANNELSELECTION for details
        cfg.artfctdef.muscle.cutoff      = ar.muscThr; %z-value at which to threshold (default = 4)
        ar_musc_art_padding = 0.1;   % [s]
        ar.musc_trl_padding = 0.1;   % [s]
        ar.musc_flt_padding = 0.1;   % [s]
        cfg.continuous = 'no';
        cfg.artfctdef.muscle.interactive = 'no'; %specify 'yes' in case you want this part of artifact rejection be active
        [cfg, artifact_muscle] = ft_artifact_muscle(cfg, data_all_arj(ds)); % this function saves to 'cfg.artfctdef.muscle.artifact' an array with artifact. It is also saved in 'artifact_muscle'.

        %Getting Good trials
        for i = 1:size(cfg.artfctdef.muscle.trl,1)
            data_point_vec = find(cfg.artfctdef.muscle.trl(i,1) <= (artifact_muscle(:,1)) & cfg.artfctdef.muscle.trl(i,2) >= (artifact_muscle(:,2)));
            if ~isempty(data_point_vec)
                for data_p = data_point_vec'
                    artifact_muscle(data_p,:) = [0,0];
                end
                removed_tr{ds} = [removed_tr{ds} i ];
            end
            if isempty(artifact_muscle)
                break;
            end
        end
        artifact_muscle(artifact_muscle(:,1)==0,:) = [];
        for i = 1:(size(cfg.artfctdef.muscle.trl,1)-1)
            data_point_vec = find(cfg.artfctdef.muscle.trl(i,1) <= (artifact_muscle(:,1)) & cfg.artfctdef.muscle.trl(i+1,2) >= (artifact_muscle(:,2)));
            if ~isempty(data_point_vec)
                artifact_muscle(data_point_vec,:) = [];

                removed_tr{ds} = [removed_tr{ds} i i+1];
            end
            if isempty(artifact_muscle)
                break;
            end
        end
        removed_tr{ds} = unique(sort(removed_tr{ds}));

        data_all_arj(ds) = ft_rejectartifact(cfg, data_all_arj(ds)); %needs to be called in order to reject artifact from actual data. Knows artifacts from cfg saved while calling ft_artifact_muscle

        removed_utr{ds} = [];
        for i = 1:numel(removed_tr{ds})
            removed_utr{ds} = [removed_utr{ds} urtrial{ds}(removed_tr{ds}(i))];
        end

        for i = sort(removed_tr{ds},'descend')
            urtrial{ds}(i) = [];
        end

        % saving reports
        REPORT.trial(ds).ntr_msc = numel(removed_utr{ds});
        REPORT.trial(ds).rmv_tr_msc = removed_utr{ds};

        % Re-referencing is done in two steps. To be sure there is no lose of SNR.
        % This kind of rereferencig is applied in ICA pipline (for ERP analysis there is a need to specify reference method)

        if rc.eeg
            disp('Re-referencing to AVG signal');
            cfg = [];
            cfg.reref = 'yes';
            cfg.refchannel = (find (strcmp(data_all_arj(ds).hdr.chantype, 'eeg')))';   % we rereference only to eeg channels, electric channels VEOG1, HEOG2 and EXG5 (heart) are not taken into account
            cfg.refmethod  = 'avg';
            data_all_arj(ds) = ft_preprocessing(cfg, data_all_arj(ds));
        end

        REPORT.trial(ds).ntr_post = length(data_all_arj(ds).trial);
        REPORT.trial(ds).ntr_rmv = REPORT.trial(ds).ntr_pre - REPORT.trial(ds).ntr_post;
        REPORT.trial(ds).rmv_per = round( REPORT.trial(ds).ntr_rmv / REPORT.trial(ds).ntr_pre*100);

        data_all_arj(ds).hdr.dsname = dsname;  % restore additional fields
        % data_all_arj(ds).hdr.actualchantype = actualchantype;
        % data_all_arj(ds).hdr.urchantype = urchantype;
        % data_all_arj(ds).hdr.urchanlabel = urchanlabel;

    end

    data_all_arj(ds).hdr.dsname = dsname;  % retain additional fields
    data_all_arj(ds).hdr.actualchantype = actualchantype;  

end


% recreate chantype field
% data_all_arj = sc_fix_chantype(data_all_arj);



%% SAVE %%%

fid = fopen(fullfile(saveFolder, '_AR_Trial_Report.txt'),'w+');

for  ds = 1 : length(data_all_arj)
        dsname = data_all_arj(ds).hdr.dsname;

        fprintf(fid,'\n----------------------------------------------------------\n');
        % fprintf(fid,'%s \nDS: %d',dsname,ds);
        fprintf(fid,'DS: %d\n%s',ds,dsname);
        fprintf(fid,'\n');
        if ds2remove(ds)
            fprintf(fid,'\nDataset REMOVED due to bad channels\n\n');
        else
            fprintf(fid,'\nREMOVED CHANNEL(S) (iqr = %.1f)', ar.chIQR);
            % rem_chan = ch_rej(ds).list;
            iqrdev_chan = ch_rej(ds).iqrdev;
            if ~isempty(ch_rej(ds).list)
                for inds = 1:length(ch_rej(ds).list)
                    fprintf(fid,'\n');
                    % fprintf(fid,'%3d: %s (%.1f)',rem_chan(inds),ch_rej(ds).list(inds),iqrdev_chan(inds));
                    fprintf(fid,'%s (%.1f)',char(ch_rej(ds).list(inds)),iqrdev_chan(inds));
                end
            else
                fprintf(fid,'\n    None');
            end
            fprintf(fid,'\n\n');

            fprintf(fid,'REMOVED TRIALS (%d/%d; %.1f%%)', REPORT.trial(ds).ntr_rmv, REPORT.trial(ds).ntr_pre, REPORT.trial(ds).rmv_per);
            fprintf(fid,'\n');
            fprintf(fid,'  %d trial(s) removed due to VARIANCE (iqr=%d)', numel(REPORT.trial(ds).rmv_tr_var), ar.varIQR);
            fprintf(fid,'\n');
            i=1;
            for inds = REPORT.trial(ds).rmv_tr_var
                fprintf(fid,'    %d (%.1f)',inds, trial_rej(ds).variqrdev(i));
                fprintf(fid,'\n');
                i=1+1;
            end


            if ~isfield(REPORT.trial(ds), 'rmv_tr_ran')
                REPORT.trial(ds).rmv_tr_ran = [];  % if RANGE skipped
            end

            fprintf(fid,'  %d trial(s) removed due to RANGE (thr=%d)', numel(REPORT.trial(ds).rmv_tr_ran) ,ar.rangeThr);
            fprintf(fid,'\n');
            for inds = REPORT.trial(ds).rmv_tr_ran
                fprintf(fid,'    %d',inds);
                fprintf(fid,'\n');
            end

            fprintf(fid,'  %d trial(s) removed due to MUSCLE (zthr=%d,freq=(%d,%d))', numel(REPORT.trial(ds).rmv_tr_msc), ar.muscThr,ar.muscHP,ar.muscLP);
            fprintf(fid,'\n');

            for inds =  REPORT.trial(ds).rmv_tr_msc
                fprintf(fid,'    %d',inds);
                fprintf(fid,'\n');

            end

        end
end
fclose(fid);

clear data_all_segm data_all_segm_eogcorr data_segm

file_name = strcat( saveFolder, '/_ARTF_param.mat');
save(file_name, 'ar');

file_name = strcat( saveFolder, '/_ARTF_infile.mat');
save(file_name, 'infile');


for ds = 1 : length(data_all_arj)
    if ~ismember(ds, ds_rej)
        dsname = data_all_arj(ds).hdr.dsname;
        disp( [ '[' num2str(round( 100 * ds/( length( data_all_arj )) ) ) '%] Saving DS: ', num2str(ds), ' - ', dsname, ' ARTIF free data'] );
        file_name = fullfile(saveFolder, strcat(dsname, '_ARJ.mat'));
        data_artf = orderfields(data_all_arj(ds));
        if rc.saveCompress
            save(file_name, 'data_artf');
        else
            save(file_name, 'data_artf', '-nocompression', '-v7.3');
        end
    end
end
