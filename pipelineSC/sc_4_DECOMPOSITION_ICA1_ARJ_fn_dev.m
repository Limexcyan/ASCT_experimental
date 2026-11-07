

function [data_ica1, sensors2rem,labelsforlog,reporttxtall]= sc_4_DECOMPOSITION_ICA1_ARJ_fn_dev(data_decomp1, data_arj, ds,infile, seg, ar, rc,q)
    reporttxtall = [];
    %%% Get Parameters 
    ICADATA = data_decomp1;   % Data (For trial reduction)
    folderICA1ar = fullfile (rc.analysisFolder, '5_ICA1_AR' );
    folderICA1  = fullfile (rc.analysisFolder, '4_ICA1' );

    dsname = ICADATA.dsname;
    currchantype = ICADATA.actualchantype;


    if ~isfield(ar, 'ica_ic2screen'); ar.ica_ic2screen = 0; end

    %%%%%% TRIALS BASED ON VARIANCE DEVIATION
    sc_ica1_trial_rejection;
    
    if ~isempty(artifact_trial) % if artifacts found
    
        for i = 1: size(artifact_trial,2)  %converts to original sample number
            artifact_smp_oryg(i,:) = data_arj.sampleinfo(artifact_trial(i),:);
        end
    
        cfg = [];
        cfg.artfctdef.reject = 'complete';
        cfg.artfctdef.zvalue.artifact = artifact_smp_oryg;
        cfg.artfctdef.type = 'zvalue';
        data_ica1 = ft_rejectartifact(cfg, data_arj);
    else
        data_ica1 = data_arj;
    end
    
    data_ica1.hdr.actualchantype = data_arj.hdr.actualchantype;
    
    % REMOVE SENSORS BASED ON TOPO DEVIATIONS
    
    sensors2ret=[];
    
    [n_IC , ~] = size(ICADATA.ICA.best_iter.IC_sig);
    IC_mix = ICADATA.ICA.iter(ICADATA.ICA.best_iter.index).mixing;
    
    
    if ar.ica_ic2screen >0      % how many ICs to screen
        if n_IC > ar.ica_ic2screen 
            noICscr = ar.ica_ic2screen ;
        else
            noICscr = n_IC;
        end
    else
        noICscr = n_IC;
    end
    
    chan2ica_indexes = [find(strcmp(data_ica1.hdr.actualchantype, 'eeg'))' find(strcmp(data_ica1.hdr.actualchantype, 'meg'))' find(strcmp(data_ica1.hdr.actualchantype, 'mag'))' find(strcmp(data_ica1.hdr.actualchantype, 'meggrad'))' find(strcmp(data_ica1.hdr.actualchantype, 'megmag'))'];
    chan2ica_labels = data_ica1.label(chan2ica_indexes);
    
    elec2retain_indexes = ( setxor(1:length(data_ica1.hdr.actualchantype), chan2ica_indexes) )';
    elec2retain_labels =  data_ica1.label(elec2retain_indexes);
    
    noMEEGch = numel(chan2ica_indexes);   %only on MEEG chans  for dev screening
    saveFolderds = fullfile(rc.analysisFolder, '4_ICA1', dsname);
    
    % Crate ch_trimmed and Out Folder for vis if it has not been done before
    outFolder = fullfile (folderICA1, dsname, 'IC_mixing_hist');
    if ~exist(outFolder); mkdir (outFolder); end
    
    if rc.eeg
        elecloc_ica = sc_trim_sens(data_ica1.label(chan2ica_indexes), data_ica1.hdr.elec);  %provides labels of chans that survived AR and were used for ICA
    else
        elecloc_ica = sc_trim_sens(data_ica1.label(chan2ica_indexes), data_ica1.hdr.grad);  %provides labels of chans that survived AR and were used for ICA
    end
    
    sc_locfile( elecloc_ica, saveFolderds)
    
    
    sens2rm = zeros(noMEEGch,1);
    for ic=1:noICscr
        rmindexes = find(abs(zscore(IC_mix(:,ic)))>ar.ica_topoZThr);   %find sensors deviating from others
        sens2rm(rmindexes)=1;
    end
    
    sensors2ret=find(sens2rm==0);
    sensors2rem=find(sens2rm==1);
    
    labelsforlog = ' (';
    for y = 1:length(sensors2rem)
        labelsforlog = [ labelsforlog, ' ', char(chan2ica_labels(sensors2rem(y))) ];
    end
    labelsforlog = [labelsforlog, ') '];
    
    cfg=[];
    cfg.channel=[chan2ica_labels(sensors2ret); elec2retain_labels];
    data_ica1 = ft_selectdata(cfg, data_ica1);
    data_ica1.hdr.dsname = dsname;
    data_ica1.hdr = rmfield(data_ica1.hdr, 'actualchantype');
    
    % recreate chantype field after sens removal
    data_ica1 = sc_fix_chantype(data_ica1);
    
    for i = sort(sensors2rem, 'descend')
        currchantype(i) = [];
    end
    data_ica1.hdr.actualchantype = currchantype;
    
    % 
    % disp(strcat( '[', num2str( round(ds/length(infile)*100)), '%] Saving post-ICA1 ARTIFREE data: ', dsname, ' (DS ', num2str(ds), ')'));
    % file_name = 
    % save(file_name, 'data_ica1' );
    payload.dsname = dsname;
    payload.type = "ICA1_ar";
    payload.saveFolder = folderICA1ar;
    payload.file_name = fullfile(folderICA1ar, [dsname '_ICA1_arj.mat']);
    payload.ds = ds;
    payload.data = data_ica1;
    payload.infileLen = length(infile);
    send(q,payload)
end