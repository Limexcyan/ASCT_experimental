% function for calculating ICA2 statistics, including percent of variance bef and after ica and classification

function [ica2stat] = sc_icavarstat(dsname, ica2file, data_ica2)


    fileb4ica = strrep(ica2file, '6_ICA2', '5_ICA1_AR');
    fileb4ica = strrep(fileb4ica, '_ica2.mat', '_ICA1_arj.mat');
    tmpdata = load(fileb4ica,'data_ica1');
    DATAB4ICA = tmpdata.data_ica1;
    DATABEST = data_ica2.ICA.iter(data_ica2.ICA.best_iter.index);

    chan2ica_indexes = [find(strcmp(data_ica2.hdr.actualchantype, 'eeg'))' find(strcmp(data_ica2.hdr.actualchantype, 'mag'))' find(strcmp(data_ica2.hdr.actualchantype, 'meg'))' find(strcmp(data_ica2.hdr.actualchantype, 'meggrad'))'  find(strcmp(data_ica2.hdr.actualchantype, 'megmag'))'];
    % chan2ica_labels = data_ica2.label(chan2ica_indexes);

    MIXM = DATABEST.mixing;  % mixing matrix 

    numIC = size(MIXM,2);
    numICbrain = numel(DATABEST.brain_ic);
    numCH = size(MIXM,1);
    
    
    sensorsig_allIC = MIXM * DATABEST.IC_sig;  % SENS backprojection with all ICs

    MIXMbr = MIXM;
    for c = 1:size(MIXMbr,2)   % remove non-brain components by zeroing of mixing matrix 
        if ~ismember(c, DATABEST.brain_ic)
            MIXMbr(:,c) = zeros(numCH,1);
        end
    end

    sensorsig_brainIC = MIXMbr * DATABEST.IC_sig;
    ica1arsig = zeros(numCH, size(DATAB4ICA.trial{1},2), length(DATAB4ICA.trial));
    for i = 1: length(DATAB4ICA.trial)
        ica1arsig(1:numCH, 1:size(DATAB4ICA.trial{1},2), i) = DATAB4ICA.trial{i}(chan2ica_indexes,:);
    end
    ica1arsig = reshape(ica1arsig,numCH, size(DATAB4ICA.trial{1},2)*length(DATAB4ICA.trial));

    ica2stat.allIC = numIC;
    ica2stat.brainIC = numICbrain;
    ica2stat.var_BEF = var(ica1arsig')';
    ica2stat.var_allIC = var(sensorsig_allIC')';
    ica2stat.var_brainIC = var(sensorsig_brainIC')';

    ica2stat.var_stat = [ica2stat.var_BEF,  ica2stat.var_allIC, ica2stat.var_brainIC];
    ica2stat.var_ave = [mean(ica2stat.var_BEF),  mean(ica2stat.var_allIC), mean(ica2stat.var_brainIC)];
    mean_res = mean(ica2stat.var_BEF) - mean(ica2stat.var_allIC);
    ica2stat.ratio_resid = mean_res / mean(ica2stat.var_BEF) * 100;
    ica2stat.ratio_brain = (mean(ica2stat.var_brainIC) / mean(ica2stat.var_BEF)) * 100;
    ica2stat.ratio_nonbrain = (mean(ica2stat.var_BEF) - mean(ica2stat.var_brainIC) - mean_res)/ mean(ica2stat.var_BEF) * 100;



end
