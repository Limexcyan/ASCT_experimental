%%%%%%%%% PREPROCESSING %%%%%%%%%%

% Consists of:
% REREFERENCING
% REJECTION OF REF. CHANNELS
% FILTERING OF HIGH AND LOW FREQUENCES
% SAVING CONTINOUS (PREPROCESSED) DATA - to be specified in saveFolder


%% READING FILE LIST %%%%%%%%

clear infile

switch rc.dataFormat
    case 'bdf'
        infile_all = sc_reading(rc.rawFolder, '*.bdf');
    case 'ctf'
       infile_all = sc_reading(rc.rawFolder, 'ds', 'dir')';
    case 'eeglab'
        infile_all = sc_reading(rc.rawFolder, '*.set');
    case 'itab'
        infile_all = sc_reading(rc.rawFolder, '*.raw');
    case {'itab-sim', 'syn-sim'}
        infile_all = sc_reading(rc.rawFolder, '*sim.mat');
end

if exist('begId') && exist('endId')
    infile = infile_all(begId : endId);
else
    infile = infile_all;
end

%% PREPROCESSING %%%%%%%%

saveFolder = fullfile (rc.analysisFolder, '1_PREPROCESSED');

if exist('data_all_prep'); clear data_all_prep; end
if rc.useParallel > 0
    parfor ds = 1: length(infile)
        [~, dsname, ~] = fileparts( infile{ds} ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type
        switch rc.dataFormat
            case {'bdf', 'eeglab'}
                sc_preproc_eeg(infile{ds}, chan, filter, rc);
            case 'ctf'
                [data_all_prep(ds)] = sc_preproc_meg_ctf(infile(ds), chan, filter, rc);
            case {'itab-sim', 'syn-sim', 'itab'}
                [data_all_prep(ds)] = sc_preproc_meg_itab(infile{ds}, chan, filter, rc);
        end
    end
else
    for ds = 1: length(infile)
        [~, dsname, ~] = fileparts( infile{ds} ); %extracting name of the current subject file - needs to be provided before converting to eeglab data type
        switch rc.dataFormat
            case {'bdf', 'eeglab'}
                sc_preproc_eeg(infile{ds}, chan, filter, rc);
            case 'ctf'
                [data_all_prep(ds)] = sc_preproc_meg_ctf(infile(ds), chan, filter, rc);
            case {'itab-sim', 'syn-sim', 'itab'}
                [data_all_prep(ds)] = sc_preproc_meg_itab(infile{ds}, chan, filter, rc);
        end
    end
end


file_name = fullfile ( saveFolder , '_PREP_param.mat');

disp('all PREP files saved');

