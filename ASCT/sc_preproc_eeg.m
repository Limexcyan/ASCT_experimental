function [] = sc_preproc_eeg (infile, chan, filter, rc)

[~, dsname, ~] = fileparts( infile ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type
disp( ['DS: ', dsname, ' is being preprocessed' ]); 

cfg = [];
cfg.reref       = 'no';
% cfg.datafile = infile; %needs to be provided too
cfg.dataset = infile;
data_eog = ft_preprocessing(cfg); %rereference to avg data is done after artifact rejection in sc_3_ARTIFACTS

for i = chan.meeg
    chantype{i} = 'eeg';
end
if isfield(chan, 'eog')
    for i = chan.eog
        chantype{i} = 'eog';
    end
end
if isfield(chan, 'ref')
    if ~isempty(chan.ref)
        for i = chan.ref
            chantype{i} = 'ref';
        end
    end
end
chantype = chantype';

%% ensuring proper electrodes locations 

if ~isfield(chan, 'sensMatFile') || isempty(chan.sensMatFile)
    % no elecmat specified, use standard adult MNI template
    warning('header locations disregarded, 10-20 MNI template used instead');
    tmpsens = load('elec_1005_mni.mat');
    mnisens = tmpsens.sens;
    data_eog.hdr.elec = sc_trim_sens(data_eog.label, mnisens);
elseif strcmp(chan.sensMatFile, 'use_header')
    % force to use header information
    warning("Electrode location forced to be read from the header. Ensure if they are expressed in MNI coordiantes!");
    if ~isfield(data_eog.hdr, 'elec')
        error('Header locations chosen, but no electrode info has been found there. Typically, standard 10-20 locations are fine, you just need to leave elec.sensMatFile empty.')
    end
elseif strcmp(chan.sensMatFile, 'use_custom')
    % force to use custom electrode information from the 3D modelling
    warning("Using custom individual electrode location forced to be read from the header. Ensure if they are expressed in MNI coordiantes!");
        error('fixme');
else
    % use provided template
    disp('Elecmat file for sensor locations is to be used. Ensure MNI coord system in that file!');
    tmpsens = load(chan.sensMatFile);
    mnisens = tmpsens.sens;
    data_eog.hdr.elec = sc_trim_sens(data_eog.label, mnisens);
end

if isfield(data_eog, 'elec'); data_eog = rmfield(data_eog, 'elec'); end   % removing as redundant

% adding proper chantype (some import toolboxes fail to provide proper types)
for e = 1:length(data_eog.hdr.elec.label)
    for s = 1:length(chantype)
        if strcmpi(data_eog.hdr.elec.label{e}, data_eog.label{s})
            data_eog.hdr.elec.chantype{e} = chantype{s};
            break;
        end
    end
end

for e = 1:length(data_eog.hdr.label)
    for s = 1:length(chantype)
        if strcmpi(data_eog.hdr.label{e}, data_eog.label{s})
            data_eog.hdr.chantype{e} = chantype{s};
            break;
        end
    end
end

% data_eeg.hdr.elec = sc_trim_sens(data_eeg.label, tmpsens.sens);

% adding proper elecloc
if isfield(data_eog.hdr, 'elec')
    for e = 1:length(data_eog.hdr.elec.label)
        for s = 1:length(mnisens.label)
            if strcmpi(data_eog.hdr.elec.label{e}, mnisens.label{s})
                data_eog.hdr.elec.elecpos(e,:) = mnisens.elecpos(s,:);
                data_eog.hdr.elec.chanpos(e,:) = mnisens.chanpos(s,:);
                break;
            end
        end
    end
end

data_eog = sc_fix_chantype(data_eog);

if isfield(chan, 'ref')  % re-reference if needed
    if ~isempty(chan.ref)
        cfg = [];
        cfg.reref       = 'yes';
        cfg.refchannel  = chan.ref;
        data_eog = ft_preprocessing(cfg, data_eog);
    end
end

% retaining relevant channels
cfg = [];
if isempty(chan.addMockEOG)
    cfg.channel     = data_eog.label([chan.meeg chan.elec]);
else
    cfg.channel     = data_eog.label([chan.meeg]);
end
data_eog = ft_preprocessing(cfg, data_eog);
data_eog = sc_fix_chantype(data_eog);


%%% filtering 
if filter.HPfreq > 0
cfg             = [];
cfg.hpfilter    = 'yes';     
cfg.hpfilttype  = filter.HPtype;
cfg.hpfreq      = filter.HPfreq;       
cfg.hpfiltord   = filter.HPord;
else
    cfg.hpfilter    = 'no';     
end

if filter.LPfreq > 0
cfg.lpfilter    = 'yes';     
cfg.lpfilttype  = filter.LPtype;
cfg.lpfreq      = filter.LPfreq;        
cfg.lpfiltord   = filter.LPord;
else
    cfg.lpfilter    = 'no';
end

if ~isfield(filter, 'plotResp') || isempty(filter.plotResp)
    cfg.plotfiltresp = 0;
else
    cfg.plotfiltresp = 1;
end


data_prep = ft_preprocessing(cfg, data_eog);
data_prep.hdr.dsname = dsname;   % add dsname
clear data_eog

if isfield(filter, 'resampleTo')
    if filter.resampleTo
    cfg=[];
    cfg.resamplefs = filter.resampleTo;
    cfg.detrend = 'no';
    cfg.demean = 'no';
    cfg.method = 'decimate';
    downs = data_prep.fsample/filter.resampleTo;
    data_prep = ft_resampledata(cfg,data_prep);
    data_prep.hdr.downs=downs;
    end
end

data_prep = orderfields(data_prep);

%% MOCK ELEC SIGNAL FOR FURTHER CLASSIFICATION


if ~isempty(chan.addMockEOG)
    data_prep = sc_mockeog(data_prep, chan);
end

%%%%%%%%% temporary EOG correction for estimating EOG-corrected chan variance

if ~isempty(chan.eog) || ~isempty(chan.addMockEOG)

    data_eog = data_prep;

    cfg=[]; cfg.channel = 'all';
    data_prep = ft_preprocessing(cfg, data_prep);  % to ensuure both data and data_eogcorr have the same structure (including sampleinfo)

    data_eog.cfg.dataname = dsname; 
    data_eog.cfg.dataset = dsname; 

    EEG = sc_ft2eeglab(data_eog); % !!! must be called EEG - eeglab formalism    % conversion to eeglab in order to use AAR toolbox
    EEG = pop_crls_regression2( EEG, find(strcmp(data_eog.hdr.actualchantype, 'eog')), 3, 0.9999, 0.01); 

    data_eog.trial = eeglab2fieldtrip(EEG, 'raw', 'none').trial;     % conv data back to FT format - signal only

    cfg = [];
    cfg.channel = find(strcmp(data_eog.hdr.actualchantype, 'eeg'));
    data_prep_eogcorr = ft_preprocessing(cfg, data_eog);  % remove EOG channels
    data_prep_eogcorr = sc_fix_chantype(data_prep_eogcorr);
    data_prep_eogcorr = orderfields(data_prep_eogcorr);
    clear data_eog

    if ~isempty(chan.addMockEOG)
    cprintf('*red','\nWarning: temporary EoG correction performed using reconstructed ocular signal\n');
    end
else

   data_prep_eogcorr  = data_prep;
end

%%%%%%%% end of temporary EOG corr

saveFolder = fullfile(rc.analysisFolder, '1_PREPROCESSED');
if ~exist(saveFolder)
    mkdir(saveFolder);
    if isunix
        system(['chmod g+s ' saveFolder]);  % for Unix sets guid bit for seamless multiuser analyses
    end
end


% %% MOCK ELEC SIGNAL FOR FURTHER CLASSIFICATION
% 
% 
% if ~isempty(chan.addMockEOG)
%     data_prep = sc_mockeog(data_prep, chan);
% end

%% save individual PREPROC file
  
disp( ['Saving DS: ', dsname, ' - PREPROCESSED'] );   %mmw

file_name = fullfile(saveFolder, strcat(dsname, '_PREP.mat'));


if rc.saveCompress
    save(file_name, 'data_prep', '-v7.3');
else
    save(file_name, 'data_prep', '-nocompression', '-v7.3');
end

file_name = fullfile(saveFolder, strcat(dsname, '_PREP_EOGcorr.mat'));
data_prep = data_prep_eogcorr;

if ~isempty(chan.eog) || ~isempty(chan.addMockEOG)
    if rc.saveCompress
        save(file_name, 'data_prep', '-v7.3');
    else
        save(file_name, 'data_prep', '-nocompression', '-v7.3');
    end
end

% saving sensors - same for all ds
sens = data_prep.hdr.elec;
save(fullfile(saveFolder, 'sensors.mat'), 'sens')

end
