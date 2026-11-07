

[tmpinpathname, dsname, tmpinfileext] = fileparts(infile{ds});
data_all_artf(ds).cfg.dataset = dsname;  % custom name of the dataset - possibly NON-STANDARD
data_all_artf(ds).cfg.dataname = dsname; 
EEG = sc_ft2eeglab(data_all_artf(ds));

EEGbak = EEG;
% CURRENTSET = EEG;
% ALLEEG = EEG;
% 
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'overwrite','on','gui','off'); %overwrite the current EEG
eeglab redraw




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% IC
[tmpinpathname, dsname, tmpinfileext] = fileparts(infile{ds});
data_all_IC(ds).cfg.dataset = dsname;  % custom name of the dataset - possibly NON-STANDARD
data_all_IC(ds).cfg.dataname = dsname; 
EEG = sc_ft2eeglab(data_all_IC(ds));

EEGbak = EEG;
% CURRENTSET = EEG;
% ALLEEG = EEG;
% 
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'overwrite','on','gui','off'); %overwrite the current EEG
eeglab redraw