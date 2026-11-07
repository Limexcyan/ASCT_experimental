function [data_segm, data_segm_eogcorr] = sc_segment(infile, data_prep, data_prep_eogcorr, rc, chan, filter, seg)

infile_trg = replace( infile, fullfile(rc.analysisName, '/1_PREPROCESSED'), rc.dataRawFolder);

switch (rc.dataFormat)
    case 'bdf'
        infile_trg = replace( infile_trg, '_PREP.mat', '.bdf');
    case 'eeglab'
        infile_trg = replace( infile_trg, '_PREP.mat', '.set');
    case 'ctf'
        infile_trg = replace( infile_trg, '_PREP.mat', '.ds');
    case 'itab'
        infile_trg = replace( infile_trg, '_PREP.mat', '.raw');
end

if isempty( data_prep.hdr )
    error(['There is no data in data_all_prep(',num2str(ds),').'] );
end

if isfield(data_prep.hdr, 'fid')
    fid = data_prep.hdr.fid;
end

if ~(    strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim')   )
    % FIXME all but RS sim triggereless format segmentation based on real triggers for most data formats
    cfg = [];
    cfg.trialdef.prestim    = seg.prestim;
    cfg.trialdef.poststim   = seg.poststim;
    cfg.trialdef.eventtype  = seg.event_type; % '?' to look up full trigger list
    cfg.continuous = 'no';

    switch (rc.dataFormat)
        case 'bdf'
            cfg.trialdef.detectflank = seg.detect_flank;
            cfg.headerfile         = infile_trg;   % has to be specified too
        case 'eeglab'
            cfg.headerformat = 'eeglab_set';
            cfg.headerfile         = infile_trg;   % has to be specified too
        case 'ctf'
            cfg.dataset = char(infile_trg);
        case 'itab'
            cfg.dataset = char(infile_trg);
    end


    if ~strcmp(rc.dataFormat, 'ctf')
        cfg.trialdef.eventvalue = seg.final_trig_list;  %ctf uses cfg.eventtyoe instead of cfg.eventvalue
    end
    try
        cfg_trigconfig = ft_definetrial(cfg);
    catch
        disp('NO TRIAL PROPERLY DEFINED. YOU MAY CHECK TRIGGER CODES FOUND BELOW.');
        % cfg=[];
        cfg.trialdef.eventtype  = '?' ;
        ft_definetrial(cfg);
        error('DEFINE TRIGGERS CORRECTLY BASED ON ABOVE EVENT LIST, PLS');
    end

    if isfield(filter, 'resampleTo')   %correct triggers to match new fs if resampled
        if filter.resampleTo
            cfg_trigconfig_nfs = cfg_trigconfig; %nfs - new sampling rate
            downs = data_prep.hdr.downs;
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
    end

    cfg_trigconfig_eogcorr = cfg_trigconfig;

    if ~isfield(data_prep, 'sampleinfo')
        data_prep.sampleinfo = [];
    end
    tmpoutput = ft_preprocessing(cfg_trigconfig, data_prep);
    if ~isfield(tmpoutput, 'sampleinfo')
        tmpoutput = sc_fixsampleinfo(tmpoutput);
    end
    data_prep = tmpoutput;

    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
        if ~isfield(data_prep_eogcorr, 'sampleinfo')
            data_prep_eogcorr.sampleinfo = [];
        end

        tmpoutput = ft_preprocessing(cfg_trigconfig, data_prep_eogcorr );
        if ~isfield(tmpoutput, 'sampleinfo')
            tmpoutput = sc_fixsampleinfo(tmpoutput);
        end
        data_prep_eogcorr = tmpoutput;
    end

    if strcmp( rc.dataFormat, 'ctf')
        matching_trial_ind = [];
        for inds = 1:length(cfg.trialdef.eventtype)
            matching_trial_ind = [matching_trial_ind find(strcmp({cfg_trigconfig.event.type},cfg.trialdef.eventtype{inds}))];
            % cfg_trigconfig.event contains all triggers
            % matching_trial_ind contains indexes for events for triggers of interest
        end
        matching_trial_ind = sort(matching_trial_ind);
        tmp_ev = cfg_trigconfig.event(matching_trial_ind);
        for inds = 1:length(tmp_ev)
            for evss = 1:length(cfg.trialdef.eventtype)
                if strcmp(cfg.trialdef.eventtype{evss}, tmp_ev(inds).type)
                    trial.trialinfo(inds,1) = seg.final_trig_list(evss);
                end

            end
            trial.trialinfo(inds,2) = inds;
        end
    end

    %% RECODE function
    if isfield(seg, 'recodeFn') && ~isempty(seg.recodeFn)
      [cfg_trigconfig] = feval(seg.recodeFn, cfg_trigconfig, infile);  % infile can be used for logging of trig recoding
    end

%%  final segmentation
    data_segm = ft_redefinetrial(cfg_trigconfig, data_prep );

    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
        data_segm_eogcorr = ft_redefinetrial(cfg_trigconfig, data_prep_eogcorr );
    end

else

    % add dummy trigger to trigerless datasets
    cfg = [];
    cfg.trl = [1, data_prep.sampleinfo(2), 0, 1];
    data_segm = ft_redefinetrial(cfg, data_prep );

end

if isfield(seg, 'rsSegm')   % disable dummy RS segmentation if set to zero
    if strcmp(seg.studyType, 'RS')   %RESTING STATE DESIGN
        cfg = [];   % segmenting of RS data based on time
        cfg.length = seg.rsSegm;
        data_segm = ft_redefinetrial(cfg, data_segm);

        if (~isempty(chan.eog) || ~isempty(chan.addMockEOG))
            % data_segm_eogcorr(ds) = ft_redefinetrial(cfg, data_segm_eogcorr(ds));
            data_segm_eogcorr = ft_redefinetrial(cfg, data_segm_eogcorr);
        end
    end
end

data_segm.hdr.dsname = data_prep.hdr.dsname;  % retain additional info in the header
if isfield(data_prep.hdr,'actualchantype'); data_segm.hdr.actualchantype = data_prep.hdr.actualchantype; end

if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
    data_segm_eogcorr.hdr.dsname = data_prep_eogcorr.hdr.dsname;
    if isfield(data_prep_eogcorr.hdr,'actualchantype'); data_segm_eogcorr.hdr.actualchantype = data_prep_eogcorr.hdr.actualchantype; end
end

%baseline correction
cfg = [];
cfg.seg.demean = 'yes';
if seg.demean == 0; cfg.baselinewindow = [seg.baseline, 0]; end
if seg.demean == 1; cfg.baselinewindow = 'all'; end
data_segm = ft_preprocessing( cfg, data_segm );
if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
    data_segm_eogcorr = ft_preprocessing( cfg, data_segm_eogcorr );
end

if isfield(data_segm, 'trialinfo')
    if strcmp(class(data_segm.trialinfo), 'table')   % FIX for trialinfo appearing as table at some point (changes in newer FT version?? or eeglab using either char or number codes for triggers)
        newtrialinfo = table2array(data_segm.trialinfo);
        new_data_segm = rmfield(data_segm, 'trialinfo');
        new_data_segm.trialinfo = newtrialinfo;
        data_segm = new_data_segm;
    end
end

if exist('fid', 'var'); data_segm.hdr.fid = fid; end

if ~exist('data_segm_eogcorr', 'var')
    data_segm_eogcorr = [];
else
    if exist('fid', 'var'); data_segm_eogcorr.hdr.fid = fid; end
end

if strcmp( rc.dataFormat, 'ctf')
    data_segm.trialinfo = trial.trialinfo;
end
