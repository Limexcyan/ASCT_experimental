function sc_plotb( data_plot )


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

EEG = sc_ft2eeglab(data_plot); % must be called EEG
EEG = eeg_checkset( EEG );
EEG = pop_select( EEG, 'nochannel',{'125'});
EEG = pop_select( EEG, 'nochannel',{'ECG'});

if isfield(data_plot, 'hdr.dsname')
    sc_pop_eegplot_w(EEG, 1, 1, 1, 0, 777, 'title', data_plot.hdr.dsname);   % yscale - 6th argument
else
       sc_pop_eegplot_w(EEG, 1, 1, 1, 0, 777, 'title', '---');   % yscale - 6th argument

end