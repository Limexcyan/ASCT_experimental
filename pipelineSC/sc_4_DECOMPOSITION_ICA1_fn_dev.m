function [decomp_ica1,plot_ica1] = sc_4_DECOMPOSITION_ICA1_fn_dev(data_arj, dsname, chan, rc, seg, ica, ar, filter,q)
% function [augmentedSet,decomp_ica1] = sc_4_DECOMPOSITION_ICA1_fn(data_arj, dsname, chan, rc, sedata_decomp_ica1g, ica, ar, filter)
%%%%%%%%% ICA DECOMPOSITION %%%%%%
% Consists of:
% ICA decomposition
% IC1 classification


%%% DECOMPOSITION %%%
%%%%%%%%%%%%%%%%%%%%%

warning off;

saveFolder = fullfile(rc.analysisFolder, '4_ICA1');
saveFolderds = fullfile(rc.analysisFolder, '4_ICA1', dsname);

if ~exist(saveFolder)
    mkdir(saveFolder);
end

dir2 = fullfile(saveFolder, dsname);

if not( isfolder(dir2) )
    %cd( strcat( saveFolder , '/' ) );
    mkdir( dir2 );
end

dec = 1;  % decimation disable - just for backward compatibility
Fsnew = data_arj.fsample;

actualchantype = data_arj.hdr.actualchantype;

%% MEEG SIGNAL %%%

%coverting epoched data format into a structure that can be swallowed by ICA script
nSamp = zeros( 1 , length(data_arj.trial) );

for tr = 1 : length(data_arj.trial)
    nSamp(tr) = size( data_arj.trial{tr} , 2); %checking second dimesion, which is time dimension
end

if length(data_arj.label) ~= length(data_arj.hdr.actualchantype); error('header incoistency. channel number / description do not match'); end
if length(data_arj.label) ~= size(data_arj.trial{1},1); error('header incoistency regarding the number of channels'); end


chan2ica_indexes = [find(strcmp(data_arj.hdr.actualchantype, 'eeg'))' find(strcmp(data_arj.hdr.actualchantype, 'meg'))' find(strcmp(data_arj.hdr.actualchantype, 'mag'))' find(strcmp(data_arj.hdr.actualchantype, 'meggrad'))' find(strcmp(data_arj.hdr.actualchantype, 'megmag'))'];
chan2ica_labels = data_arj.label(chan2ica_indexes);
nmeeg = numel(chan2ica_indexes );

if isfield(chan,'elec')
    nelech = length(chan.elec); %number of electric channels
else
    nelech = 0;
end
elec_indexes = ( setxor(1:length(data_arj.hdr.actualchantype), chan2ica_indexes) )';


sig = zeros( nmeeg, sum(nSamp)); 

for tr = 1 : length(data_arj.trial)
    begsample = sum( nSamp(1:(tr-1)) ) + 1;
    endsample = sum( nSamp(1:tr) );
    sig(:, begsample:endsample ) = data_arj.trial{tr}(chan2ica_indexes, :);
end


%some additional parameters
leng = size(sig,2);
block = leng;
timeline_dec = 1/Fsnew * (1:round(leng));
time_ica = timeline_dec;


%% ELEC CHANNELS %%%
plot_ica1.elec_viz.time = time_ica;

if nelech  % do only when elec channels exist
    
    elec = zeros( nelech, sum(nSamp));
    
    for tr = 1 : length(data_arj.trial)
        begsample = sum( nSamp(1:(tr-1)) ) + 1;
        endsample = sum( nSamp(1:tr) );
        elec(: , begsample:endsample ) = data_arj.trial{tr}(elec_indexes, :); %ASSIGNING last nelech CHANNELS AS ELECTRIC CHANNELS FOR CORRELATION
    end
    
    %standarizing elec signal 
    for i = 1:size(elec,1)
        sige = elec(i,:);
        if std(sige) > 0
            sige=(sige-mean(sige))/std(sige);
        end
        % sige = decimate(sige,dec);
        elec(i,:) = sige;
    end

    plot_ica1.dsname = dsname;
    plot_ica1.elec_viz.time = time_ica;
    plot_ica1.elec_viz.elec = elec;

    % ---> Save electric channels
    for cont = 1:nelech
        icy = elec(cont,:);
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% % constructing event-like data type %%%

%since data has been segmented, we create timgin accordingly to the length of epochs
for tt = 1:size(data_arj.trialinfo,1)
    triggers(tt,1) = seg.prestim + (tt-1)*(seg.prestim+seg.poststim); %( data_arj.sampleinfo(tt,1)/Fsnew + data_arj.sampleinfo(tt,1)/Fsnew + seg.prestim - seg.poststim) / 2;
    triggers(tt,2) = data_arj.trialinfo(tt,1);
end

event_label = unique(triggers(:,2)); %checks type of triggers - cond corresponds to one type of trigger (e.g. '65281')
ncond = length(event_label);

% creating event-like structure for itab
for ee = 1:length(event_label)
    event(ee).name = num2str(event_label(ee));
    event(ee).labels = event_label(ee);
    event(ee).t_pre = -1*seg.prestim*1000; %fieldtrip sek, itab milisec
    event(ee).t_post = seg.poststim*1000; %fieldtrip sek, itab milisec
    event(ee).t_baseline_on = seg.baseline*1000; %fieldtrip sek, itab milisec
    event(ee).t_baseline_off = 0;
end

for k = 1:length(event_label)
    codes(k) = event(k).labels;
end

%automatic calculation of some parameters
for zz=1:length(event_label)
    event(zz).times = triggers(find(triggers(:,2)==codes(zz)),1)';
    for cont = 1:length(event(zz).times)
        [~,peaks_pos] = min(abs(event(zz).times(cont)-time_ica));
        event(zz).peaks_pos(cont) = peaks_pos;
    end
end

%some additional parameters
step = 20;    % in ms
window = 400;    % in ms
step2 = round(Fsnew*step/1000);     % in points
window2 = round(Fsnew*window/1000);      % in points

nwin = fix( (block-window2)/step2 );
pelec = zeros(nelech,nwin);

%POWER   
if nelech  % do only when elec channels exist
    for cont=1:nelech
        sigt=elec(cont,:).^2;
        for k=1:nwin
            pelec(cont,k) = mean(sigt((k-1)*step2+1:(k-1)*step2+window2));
        end
    end
    
    win=1024*ceil(4/(dec+1));
    spectral_estimator = spectrum.welch('Hamming',win,0);
    
    for cont = 1:nelech
        Power_Spectrum_ele = psd(spectral_estimator,elec(cont,:),'NFFT',win,'Fs',Fsnew);
        selec(cont,:) = sqrt((Fsnew/win)*Power_Spectrum_ele.Data)';
    end
    
end

%% DECOMPOSITION %%%%%%%%%

ica_failed = 1;  % will be cleared if any ICA iteration converges
sigs = sig;

plot_ica1.ICA.IC_mix= {};
 plot_ica1.ICA.n_IC = [];
for it = 1 : ica.ICA1_numIter
    
    % DECOMPOSITION ITSELF
    %     disp([' [' num2str( round( 100 * (ds/ length(data_all_arj) ))) '%] Decomposing DS', num2str(ds), ' - ', dsname, ' file by fastICA'] );
    disp([' [ICA1: Decomposing DS: ', dsname, ' by fastICA; run: ' num2str(it) ' of ' num2str(ica.ICA1_numIter)]);
    
    clear A W IC pIC good_ic mspettro G G2 G3 H H2 H3 K K2 K3R R2 R3 ave T T1 T2 ave_on ave_off clas potenza order spec_on spec_off IC_pow
    % pack;
    
    % intitializes another seed for each iteration (being more specific, it depends on it)
    randn('state', it);
    i_seed = randn( nmeeg , nmeeg );
    
    [IC_sig, IC_mix, IC_unmix] = fastica(sigs, 'approach', ica.approach, 'g', ica.ICA1_nonlinearity, 'verbose', 'on', 'displayMode', 'off', 'maxNumIterations', ica.ICA1_maxSteps, 'initGuess', i_seed, 'epsilon', ica.ICA_epsilon,  'interactivePCA' ,'off');
    [n_IC , ~] = size(IC_sig);
    
    % if n_IC == 0  %temporary increase iter no when no components found
    %     disp('no convergence.... retrying with more steps');
    %     [IC_sig, IC_mix, IC_unmix] = fastica(sigs, 'approach', ica.approach, 'g', ica.ICA1_nonlinearity, 'verbose', 'on', 'displayMode', 'off', 'maxNumIterations', round(ica.ICA1_maxSteps*1.25), 'initGuess', i_seed, 'epsilon', ica.ICA_epsilon,  'interactivePCA' ,'off');
    %     [n_IC , ~] = size(IC_sig);
    % %     if n_IC == 0
    % %         disp('retrying even harder...');
    % %         [IC_sig, IC_mix, IC_unmix] = fastica(sigs, 'approach', ica.approach, 'g', ica.ICA1_nonlinearity, 'verbose', 'on', 'displayMode', 'off', 'maxNumIterations', round(ica.ICA1_maxSteps*2), 'initGuess', i_seed, 'epsilon', ica.ICA_epsilon,  'interactivePCA' ,'off');
    % %         [n_IC , ~] = size(IC_sig);
    % %     end
    % end

    
    if n_IC > 0       
        for ic = 1 : n_IC
            IC_pow( ic ) = mean( IC_mix(:,ic).^2 );
        end
        
        [IC_pow , order] = sort( IC_pow );
        IC_pow = fliplr( IC_pow  );
        order = fliplr( order );
        IC_mix = IC_mix( : , order );
        IC_unmix = IC_unmix( order , : ); %AL
        IC_sig = IC_sig( order , : );
    end
    
    iter(it).mixing = IC_mix;
    iter(it).unmixing = IC_unmix;
    
    %STUDY
    if n_IC>0
        clear ave var %clear var to be sure there is no data in var
        T = [];
        
        if strcmp(seg.studyType, 'ER')
            
            for ind = 1 : length(event_label)
                for ix = 1 : n_IC    
                    %----> Evoked response and its variance
                    ave(ind).mat(ix,:) = average( IC_sig(ix,:),event(ind).peaks_pos,round(event(ind).t_pre*Fsnew/1000),round(event(ind).t_post*Fsnew/1000),...
                        round(event(ind).t_baseline_on*Fsnew/1000),round(event(ind).t_baseline_off*Fsnew/1000));
                    
                    T(ind,ix) = var( squeeze(ave(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end)) );                 
                end
            end
        else
            T = zeros(length(event_label),n_IC);   %empty T (ER) matrix for RS study
        end
        
        %-----------------------------------------------
        %------ POWER SPECTRAL DENSITY ESTIMATION  -----
        
        win = 1024*ceil( 4/(dec+1) );
        for ix = 1:n_IC
            spectral_estimator = spectrum.welch('Hamming',win,0);
            %                         Power_Spectrum = psd(spectral_estimator,IC_sig(ix,:),'NFFT',win,'Fs',Fsnew);   %orig itab for cointinuous ICA  
            
            IC_sigep = reshape(IC_sig, size(IC_sig,1), length(data_arj.trial), []);
            % Power_Spectrum_epo=zeros(
            % for epo = 1:length(data_arj.trial)
            Power_Spectrum = psd(spectral_estimator,IC_sigep(ix,:),'NFFT',win,'Fs',Fsnew);
            % end
            
            mspettro(ix,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
            F = Power_Spectrum.Frequencies;
        end
        
        %--------------------------------
        %----> IC_sig POWER TIME COURSE <----
        pIC = zeros( size(IC_mix,2), nwin );
        for cont = 1:size(IC_mix,2)
            sigt = IC_sig(cont,:).^2;
            for k = 1:nwin
                pIC(cont,k) = mean( sigt((k-1)*step2+1:(k-1)*step2+window2) );
            end
        end
        clear sigt;
        
               
       
        
        %----> user-friendly Topological maps of mixing matrix columns <----
        if rc.eeg
            elecloc_ica = sc_trim_sens(data_arj.label(chan2ica_indexes), data_arj.hdr.elec);  %provides labels of chans that survived AR and were used for ICA
        else
            elecloc_ica = sc_trim_sens(data_arj.label(chan2ica_indexes), data_arj.hdr.grad);  %provides labels of chans that survived AR and were used for ICA
        end
        
        sc_locfile( elecloc_ica, saveFolderds); %creates a elc for topolot function
   
              
        
        %-------------------------------------
        %--------> FEATURES GENERATION <--------
         
        if n_IC==0
            good_ic=[]; art_con=1; G=[]; G2=[]; G3=[];
            H=[]; H2=[]; H3=[]; clas=[];
        else
            
            %-------------------------------------------------------
            %---> Correlation between ICs and electric channels <---
            
            if nelech > 0
                
                %---> Correlation between the ICs and electric channels
                R = corrcoef([elec',IC_sig']);
                K = R(nelech+1:nelech+size(IC_mix,2),1:nelech);
                H = max(abs(K'),[],1);
                
                %---> Correlation between the ICs' and electric channels' power in window of 400 ms duration (step = 20 ms)   %CHECK WIN len
                R2 = corrcoef([pelec',pIC']);
                K2 = R2(nelech+1:nelech+size(IC_mix,2),1:nelech);
                H2 = max(abs(K2'),[],1);
                
                %---> Correlation between ICs' electric channels'power spectra between 3 and 40 Hz
                vspec = find(F > 3 & F < 40);
                R3 = corrcoef([selec(:,vspec)',mspettro(:,vspec)']);
                K3 = R3(nelech+1:nelech+size(IC_mix,2),1:nelech);
                H3 = max(abs(K3'),[],1);
            else
                H = zeros(1,size(IC_mix,2)); H2=zeros(1,size(IC_mix,2)); H3=zeros(1,size(IC_mix,2));
            end
            
            %------------------------------------------------------------------
            %---> Fit with 1/f spectrum, flat spectrum "quantification", IC_sig time kurtosis
            %------------------------------------------------------------------
            
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
            
            %---> Set thresholds for ICs' classification
            thres_a = 0.10; thres_b = 0.25; thres_c = 0.95;
            thres_d = 0.5;  thres_e = 2;    thres_f = 15;
            thres_g = 0.1;  thres_h = 15;

                
            art_con = -1;
            good_ic = -1; %fake values, classification will be performed later in the main sc_4_SECOMPOSITION_ICA

        end

        %----------------------------------
        %----> SAVE ITERATION RESULTS <----

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
        clear predictions
        %%% additinal saving of some of parameters
        iter(it).T = T;
        iter(it).F = F;
        iter(it).pIC = pIC;
        
        %%% saving IC sig for further manual class
        iter(it).IC_sig = IC_sig;
        
        %%%
        
        goodness_ic(it,1) = length( good_ic );
        goodness_ic(it,2) = 1-art_con;
        
        % disp(['nonlinearity ' ica.ICA1_nonlinearity ' - run ' num2str(it, '%02.0f') ' / ' num2str(ica.ICA1_numIter)]);
        % disp(['total number of ICs : ' num2str(size(IC_mix,2)) ' -  number of brain ICs : '  num2str(length(good_ic)) ' -  artifact contamination : ' num2str(art_con)]);
        ica_failed = 0;
    else
        augmentedSet{it} = [];
        warning('ITER1 zero results');
        goodness_ic(it,1) = 0; 
        goodness_ic(it,2) = 1;
    end
   
end

ICA.iter = iter;

clear IC_mix IC_unmix IC_sig pIC good_ic mspettro G G2 G3 H H2 H3 K K2 K3 R R2 R3 ave ave_on ave_off T T1 T2 clas  spec_on spec_off;

%% ----> SAVE GLOBAL RESULTS <----


if ~ica_failed
      
    % [~,pos_new] = max( goodness_ic(:,1).*goodness_ic(:,2) );
    [~,best_iteration] = max( goodness_ic(:,1) );

    
    IC_mix = ICA.iter(best_iteration).mixing;
    IC_unmix = ICA.iter(best_iteration).unmixing;
    good_ic = ICA.iter(best_iteration).brain_ic;
    disp( ['non-linearity used: ' ica.ICA1_nonlinearity ' - run number ' num2str(mod(best_iteration-1,ica.ICA1_numIter)+1)] );
    if ~isempty(IC_mix)  % if best iter exist

        IC_sig = IC_unmix*sigs; %--> Compute Ic set for the best trial
        ICA.best_iter.index = best_iteration;
        ICA.best_iter.IC_sig = IC_sig;
        ICA.best_iter.nonlinearity = ica.ICA1_nonlinearity;
    end
    ICA.iter(best_iteration).brain_ic_number = length(good_ic);
    ICA.iter(best_iteration).brain_ic = good_ic;
    
    ica_par.non_linearity = ica.ICA1_nonlinearity;
    ica_par.approach = ica.approach;
    ica_par.iteration_no = ica.ICA1_numIter;
    ica_par.dec_fact = dec;
    %ica_par.filter.freq_notch = freq_notch;
    ica_par.filter.freq_high = filter.LPfreq;
    ica_par.filter.freq_low = filter.HPfreq;
    %ica_par.intervals.skipped_intervals = skipped_intervals;
    %ica_par.intervals.offset = offset;
    ica_par.IC_npt = block;
    ica_par.time_ica = time_ica;
    
    
    %  decomp_ica1(ds) = data_arj;
    decomp_ica1.hdr = data_arj.hdr;
    decomp_ica1.fsample = data_arj.fsample;
    decomp_ica1.label = data_arj.label;
    decomp_ica1.ic_stat = {};
    if isfield(data_arj, 'sampleinfo')
    decomp_ica1.sampleinfo = data_arj.sampleinfo;
    end
    
    decomp_ica1.ica_par = ica_par;  %ICA1 results are needed for primary AR, then they can be discarded
    decomp_ica1.ICA = ICA;
    decomp_ica1.event = event;
    decomp_ica1.nSamp = nSamp;
    
    decomp_ica1.dsname = dsname;
    decomp_ica1.actualchantype = actualchantype;
    decomp_ica1.ic_stat = {};

else
    
    file_name = fullfile(saveFolder, [dsname '_ICA1_FAILED.mat']);
    emptyica = 'no convergence';
    save(file_name, 'emptyica');
    decomp_ica1.ic_stat = {};

    decomp_ica1.fsample = [];
    decomp_ica1.label = [];
    decomp_ica1.sampleinfo = [];
    decomp_ica1.ica_par = [];
    decomp_ica1.ICA = [];
    decomp_ica1.event = [];
    decomp_ica1.nSamp = [];
    decomp_ica1.dsname = dsname;
        
end

payload.type = "ICA1_decomp";
payload.saveFolder = fullfile(rc.analysisFolder, '4_ICA1');
payload.file_name = fullfile(saveFolder, [dsname '_ICA1_decomp.mat']);
payload.dsname = dsname;
payload.data = decomp_ica1;
payload.rc = rc;
payload.chan = chan;
payload.ica = ica;
send(q, payload);

% saveFolder = fullfile(rc.analysisFolder, '4_ICA1');
% file_name = fullfile(saveFolder, [dsname '_ICA1_decomp.mat']);
% disp( strcat( 'ICA1 decomp: Saving DS ', dsname) );

% save(file_name, 'decomp_ica1');   %save ICA1 decomposition only (data after ICA1 AR rej is performed in main sc_4_DECOMPOSITION_ICA wrapper)
% clear goodness_ic


end
