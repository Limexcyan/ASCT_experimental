function [data_prep] = sc_preproc_meg_itab (infile, chan, filter, rc)

%% Functiom for reading and preprocessing MEG data in ITAB file format

[~, dsname, ~] = fileparts( infile ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type

%% import

cfg = [];
cfg.continuous         = 'yes';
cfg.channel = 'all';
cfg.dataset = infile;
% hdr = ft_read_header(infile);

if strcmp(rc.dataFormat, 'itab-sim') | strcmp(rc.dataFormat, 'syn-sim')
    cprintf('magenta', '\nWARNING WARNING WARNING; running simulation in a DEV mode. parameters set for a specific SIM file\n\n');
    infile2 = infile;
    infile = '/mnt/devv/Exp/SIM/ITAB-sim/0_raw/mrtlne88_0101.raw';
end


data_meg = ft_preprocessing(cfg);
hdr = ft_read_header(infile);

for ch = chan.elec
    if ismember(ch, chan.eog)
        if ~strcmpi(data_meg.hdr.chantype(ch), 'eog')
            cprintf ('red', ['\n\nchannel ', num2str(ch) , ' is not specified as EOG in the header. fixing this...\n\n']);
            data_meg.hdr.chantype(ch) = {'eog'};
        end
    else
        if ~strcmpi(data_meg.hdr.chantype(ch), 'elec') || ~strcmpi(data_meg.hdr.chantype(ch), 'ecg')
            cprintf ('red', ['\n\nchannel ', num2str(ch) , ' is not specified as an electric channel in the header. fixing this...\n\n']);
            data_meg.hdr.chantype(ch) = {'elec'};
        end
    end
end


% retain selected channels and remove these marked as faulty

cfg = [];
bad_channel = find([hdr.orig.ch.flag]==1);
good_channel = setdiff(find([hdr.orig.ch.type]==2),bad_channel);
chan2retain = intersect(good_channel, chan.meeg);
chan2retain = [chan2retain chan.elec];
cfg.channel = [hdr.label(chan2retain) ];
data_meg = ft_preprocessing(cfg, data_meg);

data_meg = sc_fix_chantype(data_meg);


if (~isfield(chan, 'sensMatFile') || isempty(chan.sensMatFile)) || strcmp(chan.sensMatFile, 'use_header')
    % no sens file, use header instead
    cprintf('magenta', '\n\nElectrode location forced to be read from the header. Ensure if they are expressed in MNI coordiantes!\n\n');
    if ~isfield(data_meg.hdr, 'grad')
        error('No electrode info in the heeader. Check your data, please.')
    end    
else
    % use provided template
    cprintf('magenta', '\nElecmat file for sensor locations is to be used. Ensure MNI coord system in that file!\n\n');
    tmpsens = load(chan.sensMatFile);
    mnisens = tmpsens.sens;
    data_meg.hdr.elec = sc_trim_sens(data_meg.label, mnisens);
end


%%% MD (!!)
switch rc.dataFormat
    case {'itab-sim', 'syn-sim'}
        warning('W');
        simminfile = infile2;
        % simminfile = fullfile(rc.analysisFolder, '0_SIMSTUFF','mrtlne88_0101_sim.mat');
        tmpdata = load(simminfile);
        data_sim = tmpdata.sim;
        clear tmpdata
        
        % if data_meg.fsample == 1025
        %     data_meg.fsample = 1024;
        %     data_meg.hdr.Fs = 1024;
        % end

        %%%%%%% Warning! Data Sim is non existent where only ITAB format (not
        %%% itab-sim) is considered --> Dragged into switch By MD
        if length(data_meg.trial{1})>length(data_sim)
            cprintf('magenta', '\nWARNING: sim signal too short. cutting accordingly\n\n');    
            cfg = [];
            cfg.continuous         = 'yes';
            cfg.latency = [0 (length(data_sim)/data_meg.fsample)-0.289]; %fixed cut
            data_meg = ft_selectdata(cfg, data_meg);
        end

        data_meg.trial{1} = data_sim(:,1:size(data_meg.trial{1},2));  % replacing with simulated data
        %%%%%%
end
%%% filtering (applied to all structures the same maner
cfg             = [];
cfg.continuous = 'yes';

if filter.HPfreq
    cfg.hpfilter    = 'yes';     % enables high-pass filtering
    cfg.hpfilttype  = filter.HPtype;
    cfg.hpfreq      = filter.HPfreq;       % sets up the frequency for high-pass filter
    cfg.hpfiltord   = filter.HPord;
end

if filter.LPfreq
    cfg.lpfilter    = 'yes';     % enables low-pass filtering
    cfg.lpfilttype  = filter.LPtype;
    cfg.lpfreq      = filter.LPfreq;        % sets up the frequency for low-pass filter
    cfg.lpfiltord   = filter.LPord;
end

cfg.plotfiltresp = filter.plotResp;
if  filter.LPfreq || filter.HPfreq
    data_prep = ft_preprocessing(cfg, data_meg);
else
    data_prep = data_meg; % no filtering applied
end

data_prep.hdr.dsname = dsname;   % add dsname

%%% resampling

if isfield(filter, 'resampleTo')
    cprintf('magenta', '\nWARNING: resamling enabled. antialiasing LP set to 50Hz\n\n');
    if data_prep.fsample == 1025
        data_prep.fsample = 1024;   
            cprintf('red', '\nWARNING: sample rate changed 1025->1024 to allow for requested downsampling. This will introduce a tiny inaccuracy in frequency estimation that can be neglected.\n\n');
    end
    cfg=[];
    cfg.resamplefs = filter.resampleTo;
    cfg.detrend = 'no';
    cfg.demean = 'no';
    cfg.lpfilter = 'yes';
    cfg.method = 'downsample';
    cfg.lpfreq = '50';
    downs = data_prep.fsample/filter.resampleTo;
    data_prep = ft_resampledata(cfg,data_prep);
    data_prep.hdr.downs=downs;
      
    %fix to dropping sampleinfo during downsampling
    data_prep.sampleinfo(1) = 1;                          
    data_prep.sampleinfo(2) = size(data_prep.trial{1},2); 
    
end

saveFolder = fullfile(rc.analysisFolder, '1_PREPROCESSED');
if ~exist(saveFolder)
    mkdir(saveFolder);
end


% adding fiducials for further realignment
data_prep.hdr.fid.NAS = hdr.orig.marker(:,1);
data_prep.hdr.fid.RPA = hdr.orig.marker(:,3);
data_prep.hdr.fid.LPA = hdr.orig.marker(:,5);


%     disp( [ '[' num2str(round( 100*(ds)/length(infile))) '%] Saving DS: ', num2str(ds), ' - ', dsname, ' PREP'] );   %mmw
disp( ['Saving DS: ', dsname, ' - PREPROCESSED'] );   %mmw

file_name = strcat(saveFolder, '/', dsname, '_PREP.mat');
sc_parsave_prep(file_name, data_prep );



% saving sensors - same for all ds
sens = data_prep.hdr.grad;
save(fullfile(saveFolder, 'sensors.mat'), 'sens')

end
