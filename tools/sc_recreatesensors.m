% sript for sensor based connectivity
% it reconstructs sensor signals after both stages of AR (sensor AR + ICA AR)
% it should be run after ICA classification (step 6), then continue with
% CONN estimation (step 10)
% set con.sensorLevel = 1 in exsetup

% CAUTION! currently design.DC are not read.
% conditions are read from design.COND(1).name / design.COND(1).trigg
% only single trigger per condition is supported currently
rc.analysisFolder = fullfile(rc.expFolder, rc.analysisName);
currentFolder = fullfile(rc.analysisFolder, '6_ICA2');
% currentsaveFolder = fullfile(currentFolder, 'sensorspace');
% currentsaveFolder = fullfile(currentFolder, 'eeglab');
% if ~exist(currentsaveFolder); mkdir(currentsaveFolder); end

if exist(currentFolder) % reading 'infile' file
    infile_all = sc_reading(currentFolder, '*ica2.mat');  % screading : lsit of  files with specific extrnsions
    infile = infile_all;
else
    error( "There are no input files '/6_ICA2' folder. Most likely ica.decomposition data haven't been saved");
end


if exist('begId') && exist('endId')
    if ~(begId==0 && endId==0)
        infile = infile_all(begId : endId);
    end
end


clear data_all_arj data_all_ica1

if ~exist('begId'); begId=1; end

parfor  ds = 1 : length(infile)     % For every file in in infile
    [~, dsname, ~] = fileparts(infile(ds)); % File parts return path, name and extension, we want only name

    % load ica. decomp
    disp(strcat(' [', num2str( round(100*ds/length(infile) )), '%] Loading artifree ica. decomposed DS: ', dsname, ' - ', infile(ds)));
    file2load = infile{ds};
    tmpdata = load(file2load,'data_ica2');
    data_all_ica2(ds) = tmpdata.data_ica2;

    % load relevant ARJ files
    file2load = strrep(file2load, '6_ICA2', '5_ICA1_AR');
    file2load = strrep(file2load, '_ica2.mat', '_ICA1_arj.mat');
    disp(strcat(' [', num2str( round(100*ds/length(infile) )), '%] Loading artifree ARJ DS: ', dsname, ' - ', infile(ds)));
    tmpdata = load(file2load,'data_ica1');
    data_all_ica1ar(ds) = tmpdata.data_ica1;
end
clear tmpdata

% data_all_brain = data_all_ica1ar;

for ds = 1:length(data_all_ica2)

    dsname = data_all_ica1ar(ds).hdr.dsname;
    data_bic = data_all_ica1ar(ds);
    DATAica2 = data_all_ica2(ds);
    DATA_BESTIT = DATAica2.ICA.iter(DATAica2.ICA.best_iter.index);

    chan2ica_indexes = [find(strcmp(DATAica2.hdr.actualchantype, 'eeg'))' find(strcmp(DATAica2.hdr.actualchantype, 'mag'))' find(strcmp(DATAica2.hdr.actualchantype, 'meg'))' find(strcmp(DATAica2.hdr.actualchantype, 'meggrad'))'  find(strcmp(DATAica2.hdr.actualchantype, 'megmag'))' ];
    chan2ica_labels = DATAica2.label(chan2ica_indexes);
    % elec_indexes = ( setxor(1:length(data_all_ica2(ds).hdr.actualchantype), chan2ica_indexes) )';

    MIXM = DATA_BESTIT.mixing;   % removing non brain ICs from the mixing matrix

    numIC = size(MIXM,2);
    numICbrain = numel(DATA_BESTIT.brain_ic);
    numCH = size(MIXM,1);

    sensorsig_allIC = MIXM * DATA_BESTIT.IC_sig;  % SENS backprojection with all ICs

    for c = 1:size(MIXM,2)   % remove non-brain components by zeroing of mixing matrix
        if ~ismember(c, DATA_BESTIT.brain_ic)
            MIXM(:,c) = zeros(numCH,1);
        end
    end

    % sensorsig_brainIC = MIXM * rescaled_ICsig;
    sensorsig_brainIC   = MIXM * DATA_BESTIT.IC_sig;
    ssig = sensorsig_brainIC;


    triallen = size(DATAica2.trial{1},2);
    for cdt = 1:length(design.COND(1).name)
        currentmltoutFolder = fullfile(rc.analysisFolder, '8_CONN', con.conName, 'unc', strcat('DC', mat2str(cdt)) );
        if ~exist(currentmltoutFolder); mkdir(currentmltoutFolder); end
        currtrigtxt = char(design.COND(1).trig{cdt});
        currtrig = str2num(strrep(currtrigtxt, 'S ', ''));
        multin = []; sigconf = [];
        for trl = 1:length(DATAica2.trialinfo)
            if DATAica2.trialinfo(trl,1) == currtrig
                dchunk = ssig(:,(trl-1)*triallen+1:trl*triallen);
                multin = [multin dchunk];
            end
        end
        disp([' [', num2str( round(100*ds/length(infile) )), '%] Saving DS ', dsname]);
        save(fullfile(currentmltoutFolder, strcat(dsname, '_mltin.mat')), 'multin')
        sigconf.triallen = triallen;
        sigconf.nochan = size(multin,1);
        sigconf.fsample = DATAica2.fsample;
        save(fullfile(currentmltoutFolder, strcat(dsname, '_sigconf.mat')), 'sigconf')
    end

    % ica1arsig = data_bic.trial{1}(1:size(sensorsig_brainIC,1),:);    % SENS backprojection brain ICs only

    % ica2stat(ds).allIC = numIC;
    % ica2stat(ds).brainIC = numICbrain;
    % ica2stat(ds).var_BEF = var(ica1arsig')';
    % ica2stat(ds).var_allIC = var(sensorsig_allIC')';
    % ica2stat(ds).var_brainIC = var(sensorsig_brainIC')';
    %
    % ica2stat(ds).var_stat = [ica2stat(ds).var_BEF,  ica2stat(ds).var_allIC, ica2stat(ds).var_brainIC];
    % ica2stat(ds).var_ave = [mean(ica2stat(ds).var_BEF),  mean(ica2stat(ds).var_allIC), mean(ica2stat(ds).var_brainIC)];
    % ica2stat(ds).ratio_res = (1 - mean(ica2stat(ds).var_allIC) / mean(ica2stat(ds).var_BEF)) * 100;
    % ica2stat(ds).ratio_brain = (1 - mean(ica2stat(ds).var_brainIC) / mean(ica2stat(ds).var_BEF)) * 100;
    %
    % if length(sensorsig_brainIC) == length(data_all_ica1ar(ds).trial{1})
    %     data_bic.trial{1}(1:size(sensorsig_brainIC,1),:) = sensorsig_brainIC;
    % else
    %     disp(dsname);
    %     error('mismatch');
    % end

    % data_bic.cfg.dataname = dsname;
    % data_bic.cfg.dataset = dsname;

    %
    % file2load = infile{ds};
    % file2save = strrep(file2load, '6_ica.', '6_ica./sensorspace');
    % file2save = strrep(file2save, '_ica2.mat', '_bic.mat');
    % save(file2save, 'data_bic');
    %
    % file2saveEL = strrep(file2load, '6_ica.', '6_ica./eeglab');
    % file2saveEL = strrep(file2saveEL, '_ica2.mat', '_el.set');
    % EEG = sc_ft2eeglab(data_bic);
    % eeglabEX = pop_saveset( EEG, 'filename', file2saveEL);
    %
    %

end

% save(fullfile(currentFolder, 'ica.stat.mat'), "ica2stat");

% check var pre / post
