% load data file ('dataf') preprocessed with fieldtrip
% and show in eeglab viewer
%
% This function is provided as is. It only works for some specific type of
% data. This is a simple function to help the developer and by no mean
% an all purpose function.

function [EEG] = sc_ft2eeglab(dataft)

%[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

% if exist(dataf,'file')
%   load(dataf)
% end
% 
% load chanlocs.mat
% EEG.chanlocs = chanlocs;
for ch = 1 : length(dataft.label)
    EEG.chanlocs(ch).labels = char(dataft.label(ch));
    EEG.chanlocs(ch).X = []; EEG.chanlocs(ch).Y = []; EEG.chanlocs(ch).Z = [];
    EEG.chanlocs(ch).ref = [];
    EEG.chanlocs(ch).radius = []; EEG.chanlocs(ch).sph_theta = []; EEG.chanlocs(ch).sph_phi = []; EEG.chanlocs(ch).sph_radius = []; 
    EEG.chanlocs(ch).urchanel = [];
    EEG.chanlocs(ch).type = [];   %TODO - read from ft
end



EEG.setname    = dataft.cfg.dataset;
EEG.filename   = '';
EEG.filepath   = '';
EEG.subject    = '';
EEG.group      = '';
EEG.condition  = '';
EEG.session    = [];
EEG.comments   = 'preprocessed with fieldtrip';
EEG.nbchan     = size(dataft.trial{1},1);
EEG.trials     = size(dataft.trial,2);
EEG.pnts       = size(dataft.trial{1},2);
EEG.srate      = dataft.fsample;
EEG.xmin       = dataft.time{1}(1);
EEG.xmax       = dataft.time{1}(end);
EEG.times      = dataft.time{1};
EEG.ref        = []; %'common';
EEG.event      = [];
EEG.epoch      = [];
EEG.icaact     = [];
EEG.saved      = 'no';

if isfield(dataft, 'topo') 
    EEG.icawinv =  dataft.topo; % (EEG.icaweights*EEG.icasphere)
else
    EEG.icawinv    = []; 
end

if isfield(dataft, 'weights') 
    EEG.icaweights = dataft.weights;
else
    EEG.icaweights = [];

end

if isfield(dataft, 'sphere') 
    EEG.icasphere =  dataft.sphere;
else
    EEG.icasphere =  [];
end

if isfield(dataft, 'unmixing') 
    EEG.icaw =  dataft.unmixing;
else
    EEG.icaw =  [];
end

if isfield(dataft, 'elec') 
    for ch = 1: length(dataft.elec.chanpos  )
        EEG.chaninfo.icachansind(1,ch) = ch;
    end
end

%%% %DATA TRANSFORMATION %%%
if isfield(dataft, 'topo') & isfield(dataft, 'weights') & isfield(dataft, 'sphere') 
    
    for tr = 1:size(dataft.trial,2)
        EEG.data(:,:,tr) = dataft.topo * dataft.trial{1,tr}; %that makes sure that the data is stored in EEGlab format, namely, having original data before ICA decomposition. Therefore the inverse transformation is done on fieldtrip data
        EEG.icaact(:,:,tr) =  (EEG.icaweights*EEG.icasphere) * EEG.data(:,:,tr);
    end
    

else    
    %if there is no data from ICA, then normal trnasformation applies (namely, there is no need to go back with IC data to original data on electrodes).
    for tr=1:size(dataft.trial,2)
      EEG.data(:,:,tr) = single(dataft.trial{1,tr});
    end
    
end








 