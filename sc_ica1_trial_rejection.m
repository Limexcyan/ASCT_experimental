
% This function construct filedtrip-like data structure from ICA data and return segments of data to be rejected
% constructs data-like format which can be swallowed by ft_artifact function

clear data
data.fsample = ICADATA.fsample;

if ar.ica_ic2screen > 0
    if size(ICADATA.ICA.best_iter.IC_sig,1) > ar.ica_ic2screen  % up to 10 first ICs are taken into account when clasifying artifacts
        data.trial = { ICADATA.ICA.best_iter.IC_sig( 1:ar.ica_ic2screen, : ) };
    else
        data.trial = { ICADATA.ICA.best_iter.IC_sig( : , : ) };
    end
else
    data.trial = { ICADATA.ICA.best_iter.IC_sig( : , : ) };
end

data.time = {ICADATA.ica_par.time_ica};
% data.sampleinfo{1} = {1 length(data.trial{1})};


% labels for each IC
for i = 1 : size( data.trial{1,1} , 1)
    data.label(i,1) = { ['IC', num2str(i)] };
end

% reading all events
trials = [];
event = ICADATA.event; %??? mw check

for i = 1 : length(event)
    for j = 1 : length(event(i).times)
        trials( (i-1)*length(event(i).times) + j, 1 ) = event(i).times(1,j) + seg.prestim / 1000 ;
        trials( (i-1)*length(event(i).times) + j, 2 ) = event(i).times(1,j) + seg.poststim / 1000;
        trials( (i-1)*length(event(i).times) + j, 3 ) = event(i).labels; %label - triggery 31,33,35 itd
    end
end

trials = sortrows(trials); % sorting events by time   %CHECK!

%% Artf rejection %%%

clear artifact_smp_s artifact_muscle artifact_trial artifact_trial_singleic artifact_trial_multiic artifact_smp artifact_smp_m_m artifact_smp_m artifact_m artifact_trial_m artifact_trial_mu artifact_m_indexes artifact_m_cnt artifact_m_cnt_vec artifact_trial_s art_cnt

nSamp = ICADATA.nSamp;
samppertr = length(data.trial{1})/size(nSamp,2); % -> no of samples per trial

if ar.ica_ic2screen  %screen only first IC components
    if size((ICADATA.ICA.best_iter.IC_sig),1) < ar.ica_ic2screen
        noICtoscreen = size((ICADATA.ICA.best_iter.IC_sig),1);  
    else
        noICtoscreen = ar.ica_ic2screen;
    end
else
    noICtoscreen = size((ICADATA.ICA.best_iter.IC_sig),1);  
end

if ~noICtoscreen
   disp(['Dataset ' dsname ' has an empty ICA decomposition.']);
   error('Aborting'); 
end

% perform moving aver on ica signal befor art detection 
datamav = data;
if ar.ica_movAver
   datamav.trial{1} = movmean(data.trial{1}, ar.ica_movAver);  
end

for ic = 1:noICtoscreen   %single IC deviation detection
    cfg = [];
    cfg.continuous = 'yes';
    cfg.artfctdef.zvalue.channel = ic;
    cfg.artfctdef.zvalue.cutoff = ar.ica_singleicZthe;
    cfg.artfctdef.zvalue.trlpadding = 0;
    cfg.artfctdef.zvalue.fltpadding = 0;
    cfg.artfctdef.zvalue.artpadding = 0;
    cfg.artfctdef.zvalue.rectify = 'yes';
    cfg.artfctdef.zvalue.interactive='no';
   
    [cfg, artifact_smp_s{ic}] = ft_artifact_zvalue(cfg, datamav);
    artifact_smp_s{ic} = sortrows(artifact_smp_s{ic}); %sorting found artifacts
    trialflag{ic} = ones(size(nSamp,2),1);  %1-ok  0-arttefact
    
    for i = 1:size(artifact_smp_s{ic},1)
        notr_beg{ic} = floor(artifact_smp_s{ic}(i,1)/samppertr)+1;
        notr_end{ic} = floor((artifact_smp_s{ic}(i,2)-1)/samppertr)+1;
        for j=notr_beg{ic}:notr_end{ic}; trialflag{ic}(j)=0; end
    end
    
    artifact_trial_singleic{ic} = find(trialflag{ic}==0);
end

art_cnt_s = 1;
for ic = 1: size(artifact_trial_singleic,2)
    for i = 1: size(artifact_trial_singleic{ic},1)
        artifact_trial_s(art_cnt_s) = artifact_trial_singleic{ic}(i);
        art_cnt_s=art_cnt_s+1;
    end
end

if art_cnt_s ==1; artifact_trial_s=[]; end  %if no artifacts
artifact_trial_s=sort(artifact_trial_s);
artifact_trial_s=unique(artifact_trial_s);

for ic = 1:noICtoscreen   %multiple IC deviation detection
    cfg = [];
    cfg.continuous = 'yes';
    cfg.artfctdef.zvalue.channel = ic;
    cfg.artfctdef.zvalue.cutoff = ar.ica_multiicZThr;
    cfg.artfctdef.zvalue.trlpadding = 0;
    cfg.artfctdef.zvalue.fltpadding = 0;
    cfg.artfctdef.zvalue.artpadding = 0;
    cfg.artfctdef.zvalue.rectify = 'yes';
    cfg.artfctdef.zvalue.interactive='no';
    
    [cfg, artifact_smp_m{ic}] = ft_artifact_zvalue(cfg, datamav);
    artifact_smp_m{ic} = sortrows(artifact_smp_m{ic}); %sorting found artifacts
    trialflag{ic} = ones(size(nSamp,2),1);  %1-ok  0-arttefact
    
    for i = 1:size(artifact_smp_m{ic},1)
        notr_beg{ic} = floor(artifact_smp_m{ic}(i,1)/samppertr)+1;
        notr_end{ic} = floor((artifact_smp_m{ic}(i,2)-1)/samppertr)+1;
        for j=notr_beg{ic}:notr_end{ic}; trialflag{ic}(j)=0; end
    end
    
    artifact_trial_multiic{ic} = find(trialflag{ic}==0);
end

art_cnt_m = 1;
for ic = 1: size(artifact_trial_multiic,2)
    for i = 1: size(artifact_trial_multiic{ic},1)
        artifact_trial_mu(art_cnt_m) = artifact_trial_multiic{ic}(i);
        art_cnt_m=art_cnt_m+1;
    end
end

if art_cnt_m == 1; artifact_trial_m=[]; artifact_trial_mu=[]; end  %if no artifacts
artifact_trial_mu=sort(artifact_trial_mu');
artifact_m_indexes=unique(artifact_trial_mu);
artifact_m_cnt=hist(artifact_trial_mu,artifact_m_indexes);
artifact_m_cnt_vec = artifact_m_cnt>=ar.ica_multiicZCnt;
artifact_trial_m = artifact_m_indexes .* artifact_m_cnt_vec' ;
artifact_trial_m(artifact_trial_m==0)=[];
artifact_trial_m=artifact_trial_m';

artifact_trial=sort(unique([artifact_trial_s artifact_trial_m]));

reporttxt = [dsname newline newline 'REMOVED ' num2str(length(artifact_trial)) '/' num2str(size(ICADATA.nSamp,2)) ' (' num2str(round(length(artifact_trial)/size(ICADATA.nSamp,2)*100))  '%%)' ];
disp (reporttxt);


reporttxtall = [reporttxtall newline newline '---------------------' newline reporttxt];

clear remfilename

if ~isempty(artifact_trial_s)
    reporttxt = [num2str(size(artifact_trial_s,2)) ' trials removed due to single IC var (thr=' num2str(ar.ica_singleicZthe) ')'];
    reporttxtall = [reporttxtall newline reporttxt];
    for i=1:size(artifact_trial_s,2)
        reporttxtall = [reporttxtall newline '   ' num2str(artifact_trial_s(i))];
    end
end
if ~isempty(artifact_trial_m)
    reporttxt = [num2str(size(artifact_trial_m,2)) ' trials removed due to multiple IC simultaneous var (thr=' num2str(ar.ica_multiicZThr) '; cnt=' num2str(ar.ica_multiicZCnt) ')'];
    reporttxtall = [reporttxtall newline reporttxt];
    for i=1:size(artifact_trial_m,2)
        reporttxtall = [reporttxtall newline '   ' num2str(artifact_trial_m(i))];
    end
end

% fclose(fid);

reporttxtall = [reporttxtall newline newline reporttxt];

clear artifact_trial_singleic artifact_smp artifact_smp_m artifact_m artifact_trial_m artifact_trial_mu artifact_m_indexes artifact_m_cnt artifact_m_cnt_vec artifact_trial_s art_cnt
clear ic art_cnt_s art_cnt_m samppertr notr_beg notr_end trialflag artifact_trial_singleic reporttxt artifact_smp_oryg noICtoscreen

