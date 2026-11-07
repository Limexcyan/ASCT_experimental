function [data_prep] = sc_preproc_meg_ctf(infile, chan, filter, rc)

% currently adjusted to CTF scanner at IBB

[~, dsname, ~] = fileparts( infile ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type
dsname = char(dsname);

data_meg = sc_readctf(infile, chan);
% 
% for i = chan.meeg
%     chantype{i} = 'meg';
% end
% for i = chan.eog
%     chantype{i} = 'eog';
% end
% if isfield(chan, 'ref')
%     if ~isempty(chan.ref)
%         for i = chan.ref
%             chantype{i} = 'ref';
%         end
%     end
% end
% chantype = chantype';

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

if isfield(data_meg, 'elec'); data_meg = rmfield(data_meg, 'elec'); end   % removing as redundant
if isfield(data_meg, 'grad'); data_meg = rmfield(data_meg, 'grad'); end   % removing as redundant

for c = chan.elec; data_meg.hdr.chantype{c} = 'elec'; end
for c = chan.eog; data_meg.hdr.chantype{c} = 'eog'; end
data_meg = sc_fix_chantype(data_meg);

% retaining relevant channels

cfg = [];
cfg.channel     = data_meg.label([chan.meeg chan.elec]);
data_meg = ft_preprocessing(cfg, data_meg);
data_meg = sc_fix_chantype(data_meg);

%%% filtering (applied to all structures the same maner
cfg             = [];
if filter.HPfreq > 0
cfg.hpfilter    = 'yes';     % enables high-pass filtering
cfg.hpfilttype  = filter.HPtype;
cfg.hpfreq      = filter.HPfreq;       % sets up the frequency for high-pass filter
cfg.hpfiltord   = filter.HPord;
else
    cfg.hpfilter    = 'no';     
end

if filter.LPfreq > 0
cfg.lpfilter    = 'yes';     % enables low-pass filtering
cfg.lpfilttype  = filter.LPtype;
cfg.lpfreq      = filter.LPfreq;        % sets up the frequency for low-pass filter
cfg.lpfiltord   = filter.LPord;
else
    cfg.lpfilter    = 'no';
end


cfg.plotfiltresp = filter.plotResp;
data_prep = ft_preprocessing(cfg, data_meg);

cfg = [];

data_prep.hdr.dsname = dsname;   % add dsname

%%% rescaling

if isfield(rc, 'rescaleUnits')
data_prep.trial{1}=data_prep.trial{1}*rc.rescaleUnits;
end

%%% downsampling

if isfield(filter, 'resampleTo')
    if filter.resampleTo
    cfg=[];
    cfg.resamplefs = filter.resampleTo;
    cfg.detrend = 'no';
    cfg.demean = 'no';
    cfg.lpfilter = 'yes';
    cfg.method = 'downsample';
    cfg.lpfreq = '100';
    downs = data_prep.fsample/filter.resampleTo;
    data_prep = ft_resampledata(cfg,data_prep);
    data_prep.hdr.downs=downs;
    end
end

% 
% %fix wrong chantype for elec channels during import
% chanelec_label = data_prep.hdr.label(chan.elec);
% for i = 1:length(chanelec_label)
%     nrelec = find (strcmp(data_prep.label,chanelec_label{i}));
% end
% nrelec = nrelec-length(chan.meeg);
% for i = 1:length(nrelec)
%     data_prep.elec.chantype(i)= {'elec'};
% end
% for i = chan.elec
%     data_prep.hdr.chantype(i) = {'elec'};
% end
% for i = chan.eog
%     data_prep.hdr.chantype(i) = {'eog'};
% end

% remove redundant fields

try
data_meg = rmfield(data_meg, 'grad');
catch
end
try
data_meg = rmfield(data_meg, 'elec');
catch
end

% save individual PREPROC file

saveFolder = fullfile(rc.expFolder, rc.analysisName, '/1_PREPROCESSED');
if ~exist(saveFolder)
    mkdir(saveFolder);
end

disp( join(string(['Saving DS: ', dsname, ' - PREPROCESSED'])) );   %mmw

file_name = char(fullfile(saveFolder, strcat(dsname, '_PREP.mat')));

if rc.saveCompress
    save(file_name, 'data_prep', '-v7.3');
else
    save(file_name, 'data_prep', '-nocompression', '-v7.3');
end

% file_name = fullfile(saveFolder, strcat(dsname, '_grad_ctf.mat'));
% grad_ctf = data_meg.grad;
% save(file_name, 'grad_ctf');
    
% saving sensors - same for all ds
sens = data_prep.hdr.grad;
save(fullfile(saveFolder, 'sensors.mat'), 'sens')

end


    function [data_meg] = sc_readctf(infile, chan)

        cfg = [];
        cfg.dataset = infile;
        cfg.continuous  = 'yes';
        data_meg = ft_preprocessing(cfg);

        % if strcmp(rc.dataFormat, 'ctf')  % define noise balancing (synthetic gradiometer order)
        if ~isempty (chan.ref)  % perform noise balancing if chan.ref provided
            cfg = [];
            cfg.gradient = 'G3BR';
            data_meg = ft_denoise_synthetic(cfg, data_meg);
        end

    end