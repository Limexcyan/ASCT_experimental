function sc_plot( data_plot, varargin )


%uses eeg_plot_w newer EEGlab function

%UNTITLED Summary of this function goes here
% infile specifies filenem infile{subj})
% data specify data of interest data_all_segm(subj)
% name - must be string - array of char

if isfield(data_plot, 'hdr.dsname')
    data_plot.cfg.dataset = data_plot.hdr.dsname;  % custom name of the dataset - possibly NON-STANDARD
    data_plot.cfg.dataname = data_plot.hdr.dsname; % custom name of the dataset - possibly NON-STANDARD
else
    data_plot.cfg.dataset = '---';
    data_plot.cfg.dataname = '---';
end

if isfield(data_plot, 'grad')    
    yscale = 750;
    disp('assuming MEG signal...')
else
    yscale = 75;
    disp('assuming EEG signal...')
end

EEG = sc_ft2eeglab(data_plot); % must be called EEG
EEG = eeg_checkset( EEG );
eegrej = EEG.reject;
% 
if ~isempty(varargin)
    if length(varargin)==2 % chan range provided
        chfrom = varargin{1};
        chto = varargin{2};
        EEG = pop_select(EEG, 'channel', [chfrom:chto]);
        EEG.reject = eegrej;
    elseif length(varargin)==1
        if strcmp(varargin{1}, 'all')
        else  
        end
    else
        error('input argument for plotting not understood. provide either data only or channel two variables as range as additional parameter')
    end
end



if isfield(data_plot.hdr, 'dsname')
    titletext = data_plot.hdr.dsname;
    sc_pop_eegplot_w(EEG, 1, 1, 1, 0, yscale, 'title', titletext);   % yscale - 6th argument
else
    sc_pop_eegplot_w(EEG, 1, 1, 1, 0, yscale, 'title', '---');   % yscale - 6th argument
end