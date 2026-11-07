
% This function construct filedtrip-like data structure from ICA data and return segments of data to be rejected

% constructs data-like format which can be swallowed by ft_artifact function
clear data
data.fsample = header.smpfq;
data.trial = { ICA.best_iter.IC( ICA.iteration(ICA.best_iter.index).brain_ic , : ) }; % only brain components are taken into account when clasifying artifacts
data.time = {ica_par.time_ica}; 
seg.prestim = event(1).t_pre;
seg.poststim = event(1).t_post;

% preparing labels for each IC brain component
for i = 1 : size( data.trial{1,1} , 1)
    data.label(i,1) = { ['IC_brain', num2str(i)] };
end


% reading all events 
trials = [];

for i = 1 : length(event)
    
    for j = 1 : length(event(i).times)
        
        trials( (i-1)*length(event(i).times) + j, 1 ) = event(i).times(1,j) + seg.prestim / 1000 ;
        trials( (i-1)*length(event(i).times) + j, 2 ) = event(i).times(1,j) + seg.poststim / 1000;
        trials( (i-1)*length(event(i).times) + j, 3 ) = event(i).labels; %label - triggery 31,33,35 itd

    end
    
end

trials = sortrows(trials); % sorting events by time

%%%%%%%%%%%%%%%%%%%%%%
%%% Artf rejection %%%
%%%%%%%%%%%%%%%%%%%%%%

artifact = [];

cfg = [];
cfg.continuous = 'yes';
cfg.artfctdef.zvalue.channel = 'all';
cfg.artfctdef.zvalue.cutoff = ar.tr_z_value_th;
cfg.artfctdef.zvalue.trlpadding = 0;
cfg.artfctdef.zvalue.fltpadding = 0;
cfg.artfctdef.zvalue.artpadding = 0;
cfg.artfctdef.zvalue.interactive = 'no';
cfg.artfctdef.zvalue.rectify = 'yes';
[cfg, artifact_smp] = ft_artifact_zvalue(cfg, data);

artifact_smp = sortrows(artifact_smp); %sorting found artifacts

% converting sample info about artifacts into sec info about artifacts
artifact_sek = [];

for i = 1:size(artifact_smp,1)
    artifact_sek(i,:) = [ data.time{1,1}( 1,artifact_smp(i,1) ) data.time{1,1}( 1,artifact_smp(i,2) ) ]; %converts samples to seconds
end

%checking if given artifact range falls into any trial
i = 0;
t = 0;
artifact_all = []; %all artifacts
artifact_trial = []; %the only artifacts which fall into trials

for a = 1:size(artifact_sek,1)
    
    a_flag = 0; % zero denotes unassigned artefact
    for e = 1:size(trials,1) % checkin whether given artifact overlaps with any trial

        if ( artifact_sek(a,1) > trials(e,1) && artifact_sek(a,2) < trials(e,2) ) %is between trials
            
            a_flag = 1;
            i = i+1;
            t = t+1;
            artifact_all(i,:) = [ trials(e,1) trials(e,2) ];
            artifact_trial(t,:) = [ trials(e,1) trials(e,2) ];
                         
        elseif  ( artifact_sek(a,2) > trials(e,1) &&  artifact_sek(a,2) < trials(e,2) ) %overlaps with a trial, but starts before it
            
            a_flag = 1;
            i = i+1;
            t = t+1;
            artifact_all(i,:) = [ trials(a,1) trials(e,2) ];
            artifact_trial(t,:) = [ trials(a,1) trials(e,2) ];
        
        elseif  ( artifact_sek(a,1) > trials(e,1) &&  artifact_sek(a,1) < trials(e,2) ) %overlaps but end after
            
            a_flag = 1;
            i = i+1;
            t = t+1;
            artifact_all(i,:) = [ trials(a,1) trials(a,2) ];
            artifact_trial(t,:) = [ trials(a,1) trials(a,2) ];
        end
        
    end
    
    if a_flag == 0 % jeśli nie został przypisany do żadnego triala to zapisujemy ten artefakt w takim przedziale czasowym w jakim on został zaklasyfikowany, rozszerzając go o 0.1 sek
        
        i = i+1;
        
        if artifact_sek(a,2) - artifact_sek(a,1) < 0.1
            artifact_all(i,:) = [ (artifact_sek(a,1)+artifact_sek(a,2))/2 - 0.05 (artifact_sek(a,1)+artifact_sek(a,2))/2 + 0.05 ];
        else
            artifact_all(i,:) = artifact_sek(a,:); % przypisuje konkretny artefakt 'a' i numeruje traile w których artefakty się znajdują. Czasem jeden artefakt 'a' pasuje do kilku triali 'i'
        end
    end
          
end

artifact_trial = sortrows(artifact_trial);
artifact_trial = unique(artifact_trial, 'rows');

artifact_all = sortrows(artifact_all);
artifact_all = unique(artifact_all, 'rows');

save(path_file, 'artifact_all', 'artifact_trial', '-append'); %adds artifact_all and artifact_trail to the existing ICA structure file
% pass on artifact_all to the second ICA iteration


%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%


%loading data for training only
%     clear all
% 
%     addpath '/mnt/devv/SourceConn/Sara/ICA_MEG_od_Sary';
%     addpath '/mnt/devv/SourceConn/Sara/lc'; 
% 
%     analysisFolder = '/mnt/iSCSI1/Users/adaml/Devv/SourceConn/Exp/Sara';
%     cd(analysisFolder);
%     files = dir(analysisFolder); % reads all directories in the analysis folder
% 
%     ica_save_analysis_1 = '_ica1/'; % specifies where analysis of first ica run are saved
%     ica_save_meg_1 = '_meg_1.mat'; % specifies where results of first ica run are saved
%     
%     % !!!!! specify which ds you want to analyse
%     ds = 1;
%     nome_file = files(ds+2).name;
% 
%     path_raw = fullfile(analysisFolder , nome_file);
%     path_data = fullfile(analysisFolder , nome_file);
%     cd(path_raw);
%     
%     filename = fullfile(path_raw, strcat(nome_file, '.raw'));
%     header = lcreadheader(filename);
%     
%     fx = [nome_file ica_save_meg_1];
%     path_file = strcat(path_data,'/',fx);
%     load(path_file);
    
% here is body of the function