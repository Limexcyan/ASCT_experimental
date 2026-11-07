function data_ica2 = sc_4_DECOMPOSITION_ICA2_fn_dev(data_ica1, dsname, chan, rc, seg, ica, filter,ds,q)

%%%%%%%%% ICA DECOMPOSITION %%%%%%

warning off;
if isfield(chan,'elec')
    n_elec = length(chan.elec); %number of electric channels
else
    n_elec = 0;
end
if strcmp(rc.dataFormat, 'itab-sim') | strcmp(rc.dataFormat, 'syn-sim')
    n_elec = 0;   % elec disabled for synthetic data: no classification needed
end

saveFolderds = fullfile(rc.analysisFolder, '6_ICA2', dsname);

if ~exist(saveFolderds)
    mkdir(saveFolderds);
end

n_meeg = length( data_ica1.label ) - n_elec; %number of remaining eeg channels (afters artifact rejection)
dec = 1;
Fsnew = data_ica1.fsample;

%%% MEEG SIGNAL %%%

%coverting epoched data format into a structure that can be swallowed by ICA script

nSamp = zeros( 1 , length(data_ica1.trial) );
for tr = 1 : length(data_ica1.trial)
    nSamp(tr) = size( data_ica1.trial{tr} , 2); %checking second dimesion, which is time dimension
end
% 
chan2ica_indexes = [find(strcmp(data_ica1.hdr.actualchantype, 'eeg'))' find(strcmp(data_ica1.hdr.actualchantype, 'mag'))' find(strcmp(data_ica1.hdr.actualchantype, 'meg'))' find(strcmp(data_ica1.hdr.actualchantype, 'meggrad'))' find(strcmp(data_ica1.hdr.actualchantype, 'megmag'))'];
chan2ica_labels = data_ica1.label(chan2ica_indexes);
elec_indexes = ( setxor(1:length(data_ica1.hdr.actualchantype), chan2ica_indexes) )';

sig = zeros( length(chan2ica_labels), sum(nSamp));

for tr = 1 : length(data_ica1.trial)
    begsample = sum( nSamp(1:(tr-1)) ) + 1;
    endsample = sum( nSamp(1:tr) );
    sig(: , begsample:endsample ) = data_ica1.trial{tr}(chan2ica_indexes, :);
end

%%% ELEC CHANNELS %%%
    
    if n_elec  % do only when elec channels exist

        elec = zeros( n_elec, sum(nSamp));

        for tr = 1 : length(data_ica1.trial)
            begsample = sum( nSamp(1:(tr-1)) ) + 1;
            endsample = sum( nSamp(1:tr) );
            elec(: , begsample:endsample ) = data_ica1.trial{tr}(elec_indexes, :);
        end

        %standarizing elec signal

        for i = 1:n_elec

            sige = elec(i,:);
            if std(sige) > 0
                sige=(sige-mean(sige))/std(sige);
            end

            sige = decimate(sige,dec);
            elec(i,:) = sige;
        end
    end


%some additional parameters
leng = size(sig,2);
block = leng;
timeline_dec = 1/Fsnew * [1:round(leng/1)];
time_ica = timeline_dec;

if n_elec  % do only when elec channels exist
    % ---> Save electric channels
    for cont = 1:n_elec
        icy = elec(cont,:);
        save( strcat(saveFolderds, '/',  dsname, '_ch', num2str(chan.elec(cont)), '_elec.mat'), 'icy' );
    end
    %clear icy;
end


%% constructing event-like data type %%%

%since data has been segmented, we create timgin accordingly to the length of epochs
for tt = 1:size(data_ica1.trialinfo,1)
    triggers(tt,1) = seg.prestim + (tt-1)*(seg.prestim+seg.poststim); %( data_all_ica21(ds).sampleinfo(tt,1)/Fsnew + data_all_ica21(ds).sampleinfo(tt,1)/Fsnew + seg.prestim - seg.poststim) / 2;
    triggers(tt,2) = data_ica1.trialinfo(tt,1);
end

event_label = unique(triggers(:,2)); %checks type of triggers - cond corresponds to one type of trigger (e.g. '65281')
ncond = length(event_label);
ncond = 1; % mw

    event.name = '';
    event.labels = '';
    event.t_pre = -1*seg.prestim*1000; %fieldtrip sek, itab milisec
    event.t_post = seg.poststim*1000; %fieldtrip sek, itab milisec
    event.t_baseline_on = seg.baseline*1000; %fieldtrip sek, itab milisec
    event.t_baseline_off = 0;


codes = event.labels;

 event.times = triggers(:,1)';
 for cont = 1:length(event.times)
     [~,peaks_pos] = min(abs(event.times(cont)-time_ica));
     event.peaks_pos(cont) = peaks_pos;
 end

%some additional parameters
step = 20;    % in ms
window = 400;    % in ms
stepms = round(Fsnew*step/1000);     % in points
windowms = round(Fsnew*window/1000);      % in points


% nwin = fix( (block-windowms)/stepms );
% pelec = zeros(n_elec,nwin);

nwin = fix( (nSamp(1)-windowms) / stepms) ; %+ 1;   % no of sliding windows in each epoch
pelec = zeros(n_elec,nwin*(block/nSamp(1)));  % slinding windows * epochs

%POWER
if n_elec  % do only when elec channels exist
    for cont=1:n_elec
        sigt=elec(cont,:).^2;
        for e=1:(block/nSamp(1))   %for each epoch / added mw
            for k=1:nwin   %within each epoch
                pelec(cont,k+(e-1)*nwin) = mean(sigt(    (k-1)*stepms+1  +  (e-1)*nSamp(1)  :   (k-1)*stepms+windowms  +  (e-1)*nSamp(1)   ));
            end
        end
    end
    
    win = nSamp(1);
    spectral_estimator = spectrum.welch('Hamming',win,0);
    
    for cont = 1:n_elec
        psd_ele = psd(spectral_estimator,elec(cont,:),'NFFT',win,'Fs',Fsnew);
        selec(cont,:) = sqrt((Fsnew/win)*psd_ele.Data)';
    end
end

%% %%%%%%% DECOMPOSITION %%%%%%%%%

sigs = sig;

for it = 1 : ica.ICA2_numIter
    
    % DECOMPOSITION ITSELF
    disp([' [ICA2: Decomposing DS: ', dsname, ' by fastICA'] );
    
    clear A W IC pIC good_ic mspettro G G2 G3 H H2 H3 K K2 K3R R2 R3 ave T T1 T2 ave_on ave_off clas potenza order spec_on spec_off IC_pow
        
    % intitializes another seed for each iteration (being more specific, it depends on it)
    randn('state', it);
    i_seed = randn( n_meeg , n_meeg );
    [IC_sig, IC_mix, IC_unmix] = fastica(sigs, 'approach', ica.approach, 'g', ica.ICA2_nonlinearity, 'verbose', 'on', 'displayMode', 'off', 'maxNumIterations', ica.ICA2_maxSteps, 'initGuess', i_seed, 'epsilon', ica.ICA_epsilon,  'interactivePCA' ,'off');
    
    [n_IC , ~] = size(IC_sig);
    
    if n_IC > 0
        
        for ic = 1 : n_IC
            IC_pow(ic) = mean( IC_mix(:,ic).^2 );
        end
        
        [IC_pow , order] = sort( IC_pow );
        IC_pow = fliplr( IC_pow  );
        order = fliplr( order );
        IC_mix = IC_mix( : , order );  %A
        IC_unmix = IC_unmix( order , : ); %W
        IC_sig = IC_sig( order , : );
       
    end
            
    iter(it).mixing = IC_mix;
    iter(it).unmixing = IC_unmix;
    iter(it).IC_sig = IC_sig;
    
    %STUDY
    
    clear ave var %clear var to be sure there is no data in var
    T = [];
    %%
    if strcmp(seg.studyType, 'ER')
        for ind = 1 : 1  % mw - all cond - averageged - length(event_label) %% For each Event 
            for ix = 1 : n_IC
                
                %----> Evoked response and its variance AD
                ave(ind).mat(ix,:) = average( IC_sig(ix,:),event(ind).peaks_pos,round(event(ind).t_pre*Fsnew/1000),round(event(ind).t_post*Fsnew/1000),...
                    round(event(ind).t_baseline_on*Fsnew/1000),round(event(ind).t_baseline_off*Fsnew/1000));
                
                T(ind,ix) = var( squeeze(ave(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end)) );
    

            end

        end
    else
        T = zeros(length(event_label),n_IC);   %empty T (ER) matrix for RS study
    end
    
    %%------ POWER SPECTRAL DENSITY ESTIMATION  -----
    
    win = nSamp(1);
    
    %     Power_SpectrumN = pwelch(IC_sig', win, 0, Fsnew, Fsnew);
    for ix = 1:n_IC
        spectral_estimator = spectrum.welch('Hamming',win,0);
        Power_Spectrum = psd(spectral_estimator,IC_sig(ix,:),'NFFT',win,'Fs',Fsnew);
        mspettro(ix,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
        F = Power_Spectrum.Frequencies;
    end
        
    pIC = zeros( size(IC_mix,2), nwin*(block/nSamp(1)) );
    for cont = 1:size(IC_mix,2)
        sigt = IC_sig(cont,:).^2;
        for e=1:(block/nSamp(1))   %for each epoch
            for k = 1:nwin    % within each epoch
                pIC  (cont,k+(e-1)*nwin) = mean(sigt(   (k-1)*stepms+1 +  (e-1)*nSamp(1)  :  (k-1)*stepms+windowms +  (e-1)*nSamp(1)  ));
            end
        end
    end
    
    clear sigt;
    
    
    %% ----> PLOT AND SAVE IMAGES <----
    
    if ~isfield(ica, 'visualizeLim')
        ica.visualizeLim = 999;
    end
    if ica.visualizeLim >0
        if n_IC > ica.visualizeLim
            noICvis = ica.visualizeLim;
        else
            noICvis = n_IC;
        end
    else
        noICvis = n_IC;
    end
    lat = ceil( sqrt(noICvis) );
    
%----> Topological maps of mixing matrix columns <----
    if rc.eeg
        elecloc_ica = sc_trim_sens(chan2ica_labels, data_ica1.hdr.elec); 
    else
        elecloc_ica = sc_trim_sens(chan2ica_labels, data_ica1.hdr.grad);  %provides labels of chans that survived AR and were used for ICA
    end
    sc_locfile( elecloc_ica, saveFolderds); %trims elc file according to actual no of channels
 
    if n_IC > 0
                
  
        %-------------------------------------
        %--------> FEATURES GENERATION <--------

        if n_IC==0
            good_ic=[]; art_con=1; G=[]; G2=[]; G3=[];
            H=[]; H2=[]; H3=[]; clas=[];
        else
            
            %---> Correlation between ICs and electric channels <---
            
            if n_elec > 0
                
                %---> Correlation between the ICs and electric channels
                R = corrcoef([elec',IC_sig']);
                K = R(n_elec+1:n_elec+size(IC_mix,2),1:n_elec);
                H = max(abs(K'),[],1);
                
                %---> Correlation between the ICs' and electric channels' power in window of 400 ms duration (step = 20 ms)   %CHECK WIN len
                R2 = corrcoef([pelec',pIC']);
                K2 = R2(n_elec+1:n_elec+size(IC_mix,2),1:n_elec);
                H2 = max(abs(K2'),[],1);
                
                %---> Correlation between ICs' electric channels'power spectra between 3 and 40 Hz
                vspec = find(F > 3 & F < 40);
                R3 = corrcoef([selec(:,vspec)',mspettro(:,vspec)']);
                K3 = R3(n_elec+1:n_elec+size(IC_mix,2),1:n_elec);
                H3 = max(abs(K3'),[],1);
            else
                H = zeros(1,size(IC_mix,2)); H2=zeros(1,size(IC_mix,2)); H3=zeros(1,size(IC_mix,2));
            end
            
            %---> Fit with 1/f spectrum, flat spectrum "quantification", IC_sig time kurtosis
            
            g = fittype( {'1/x','1'} );
            frq = [1 13];
            frq2 = [2 78];
            vec = find(F > frq(1) & F < frq(2));
            vec2 = find(F > frq2(1) & F < frq2(2));
            for ix = 1:n_IC
                sspettro = mspettro(ix,:);
                [fitx, goodness] = fit( F(vec), sspettro(vec)', g);
                G(ix) = goodness.rsquare;
                ss = sspettro(vec2);
                G2(ix)= prctile(ss,95)/(median(ss));
                G3(ix)= kurtosis(IC_sig(ix,:));
            end

            %---> classification : 0 = artifact   1 = brain signal <---
            
            clas = zeros(1,n_IC); %AL
            
            % clas( find(G2 > thres_e & G3 < thres_f & H3 < thres_c) ) = 1; %---> Spectrum_flat - Time_kurtosis - Elc_spectrum_correlation
            % 
            
            good_ic = find( clas==1 );
            
            if n_elec > 0
                art_con = mean( H2(good_ic) );
            else
                art_con = 0;
            end
            
        end
        
        %----> SAVE ITERATION RESULTS <----
        
        if n_IC>0
            %                 ss = sspettro(vec2);
            %                 G2(ix)= prctile(ss,95)/(median(ss));
            %                 G3(ix)= kurtosis(IC_sig(ix,:));
            iter(it).total_ic_number=size(IC_mix,2);
            iter(it).brain_ic_number=length(good_ic);
            iter(it).brain_ic=good_ic;
            iter(it).artifact_contamination=art_con;
            iter(it).elc_signal_correlation=H;
            iter(it).elc_power_correlation=H2;
            iter(it).elc_spectrum_correlation=H3;
            iter(it).spectrum_one_over_f=G;
            iter(it).spectrum_flat=G2;
            iter(it).time_kurtosis=G3;
            iter(it).erf_variance=T; %AL
            iter(it).IC_sig = IC_sig;
            %%% additinal saving of some of parameters
            iter(it).T = T;
            iter(it).F = F;
            iter(it).pIC = pIC;
            
            goodness_ic(it,1) = length( good_ic );   % no of brain components
            goodness_ic(it,2) = 1-art_con;           % artifact contamination
            
            disp(['nonlinearity ' ica.ICA2_nonlinearity ' - run ' num2str(it, '%02.0f') ' / ' num2str(ica.ICA2_numIter)]);
            disp(['total number of ICs : ' num2str(size(IC_mix,2)) ' -  number of brain ICs : '  num2str(length(good_ic)) ' -  artifact contamination : ' num2str(art_con)]);
            
        end
    end
    
    ICA.iter = iter;
    
    clear IC_mix IC_unmix IC_sig pIC good_ic mspettro G G2 G3 H H2 H3 K K2 K3 R R2 R3 ave ave_on ave_off T T1 T2 clas  spec_on spec_off;
    
    %----> SAVE GLOBAL RESULTS <----   
    
    if n_IC>0
        
        [~,pos_new] = max( goodness_ic(:,1).*goodness_ic(:,2) );
        IC_mix = ICA.iter(pos_new).mixing;
        IC_unmix = ICA.iter(pos_new).unmixing;
        good_ic = ICA.iter(pos_new).brain_ic;
        disp( ['non-linearity used: ' ica.ICA2_nonlinearity ' - run number ' num2str(mod(pos_new-1,ica.ICA2_numIter)+1)] );
        
        if ~isempty(IC_mix)  % if best iter exist    
            IC_sig = IC_unmix*sigs; %--> Compute Ic set for the best trial
            ICA.best_iter.index = pos_new;
            ICA.best_iter.IC_sig = IC_sig;
            ICA.best_iter.nonlinearity = ica.ICA2_nonlinearity;           
        end
        
        ICA.iter(pos_new).brain_ic_number = length(good_ic);
        ICA.iter(pos_new).brain_ic = good_ic;
        
        
        ica_par.non_linearity = ica.ICA2_nonlinearity;
        ica_par.approach = ica.approach;
        ica_par.iteration_no = ica.ICA2_numIter;
        ica_par.dec_fact = dec;
        ica_par.filter.freq_high = filter.LPfreq;
        ica_par.filter.freq_low = filter.HPfreq;
        ica_par.IC_npt = block;
        ica_par.time_ica = time_ica;
        
        data_ica2.ica_par = ica_par;
        data_ica2.ICA = ICA;
        data_ica2.event = event;
        
        data_ica2.fsample = data_ica1.fsample;
        data_ica2.label = data_ica1.label;
        data_ica2.cfg = data_ica1.cfg;
        data_ica2.hdr = data_ica1.hdr;
        data_ica2.trial = data_ica1.trial;
        data_ica2.time = data_ica1.time;
        data_ica2.trialinfo = data_ica1.trialinfo;
        data_ica2.sampleinfo = data_ica1.sampleinfo;

        % MD - Payload to Parallel Sending
        payload.ds = ds;
        payload.type = "ICA2";
        payload.saveFolder  = fullfile (rc.analysisFolder, '6_ICA2' );
        payload.file_name = fullfile(payload.saveFolder, strcat(dsname, '_ica2.mat'));
        payload.dsname = dsname;
        payload.data = data_ica2;
        send(q, payload);
    else        
        file_name = fullfile(saveFolderds, [dsname '_ICA2_decomp_failed_iter' num2str(it, '%02.0f')]);
        emptyica = 'no convergence';
        save(file_name, 'emptyica');
    end

   
    
end



%% VISUALISATION OF COMPONENTS %%%%%%

%calculates contribution of each component into elecloc_70trode spectra

% for ds = begId : length(sigsa_all_IC)
%
%     [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{ds} ); %extracting name of the current subject file - needs to be provided before converting to eeglab sigsa type
%     sigsa_all_IC(ds).cfg.sigsaname = dsname; % custom name of the sigsaset - possibly NON-STANDARD
%     sigsa_all_IC(ds).cfg.sigsaset = dsname;
%     EEG = sc_ft2eeglab( sigsa_all_IC(ds) );
%
%     [pvaf,pvafs,vars] = eeg_pvaf( EEG, [], 'plot', 'off' );
%
%     %converting contributrion from cumulative to individual
%     comp_contrib = [];
%     comp_contrib(1) = pvaf(1);
%
%     for c = 1 : length(pvaf) - 1
%         comp_contrib(c+1) = pvaf(c+1) - pvaf(c);
%     end
%
%     %setting layout
%     cfg = [];
%     cfg.elecloc     = elecloc_70;
%     cfg.layout      = layout_70;
%     cfg.channel     = 'all';
%     layout          = ft_prepare_layout(cfg, sigsa_all_IC(ds) );
%
%     cfg = [];
%     cfg.component = 1:16;       % specify the component(s) that should be plotted
%     cfg.layout    = layout;
%     cfg.comment   = 'no';
%
%     %plotting
%     set(figure, 'NumberTitle', 'off', 'Name', ['DS ', num2str(ds), ': default - 1Hz'] );
%     sc_ft_topoplotscIC( cfg, sigsa_all_IC(ds), comp_contrib ); % PLOTTING EACH COMPONTN WITH ITS PERCENTAGE PARTICIPATION IN ORIGINAL SPECTRA
%
% end
%
% %%%%%%%%% VISUALISATION of individual IC_sig %%%%%%
%
% % visualisation of individual component, inculting its ERP, powerspectra and time dependence
%
%     load('_EEGchanlocs_70.mat', 'EEGchanlocs_70');
%     EEG.chanlocs = EEGchanlocs_70;
%
%     pop_prop( EEG, 0, 1, NaN, {'freqrange' [2 50] } );
%             %third position speficies which components should be plotted
%             %second position - '0' specifies component analysis
%
%     pop_topoplotsc(EEG, 0, [1:25], '01_2V_ICA_segm', [5 5], 0, 'elecloc_70', 'off');
%
%



% end
