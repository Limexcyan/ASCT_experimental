function [decomp_ica1] = sc_4_DECOMPOSITION_ICA1_fn_brasil(data_arj, dsname, chan, rc, seg, ica, ar, filter)
% function [augmentedSet,decomp_ica1] = sc_4_DECOMPOSITION_ICA1_fn(data_arj, dsname, chan, rc, seg, ica, ar, filter)
%%%%%%%%% ICA DECOMPOSITION %%%%%%
% Consists of:
% ICA decomposition
% IC1 classification


%%% DECOMPOSITION %%%
%%%%%%%%%%%%%%%%%%%%%

warning off;
load('colors.mat');
set( 0, 'DefaultLineLineWidth', 1, 'defaultFigurePosition', [40 120 3800 2000] );

saveFolder = fullfile(rc.analysisFolder, '4_ICA1');
saveFolderds = fullfile(rc.analysisFolder, '4_ICA1', dsname);

if ~exist(saveFolder)
    mkdir(saveFolder);
end

dir2 = fullfile(saveFolder, dsname);

if not( isfolder(dir2) )
    cd( strcat( saveFolder , '/' ) );
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

nelech = length(chan.elec); %number of electric channels
elec_indexes = ( setxor(1:length(data_arj.hdr.actualchantype), chan2ica_indexes) )';


sig = zeros( nmeeg, sum(nSamp)); 

for tr = 1 : length(data_arj.trial)
    begsample = sum( nSamp(1:(tr-1)) ) + 1;
    endsample = sum( nSamp(1:tr) );
    sig(:, begsample:endsample ) = data_arj.trial{tr}(chan2ica_indexes, :);
end


%% ELEC CHANNELS %%%

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
end

%some additional parameters
leng = size(sig,2);
block = leng;
timeline_dec = 1/Fsnew * [1:round(leng)];
time_ica = timeline_dec;

if nelech  % do only when elec channels exist   
    
    figure ('visible','off');
    for i = 1:nelech
        subplot(ceil(nelech/2),2,i); plot(time_ica,elec(i,:)); axis tight;
        ylabel(['ELC ' num2str(i-1)]); xlabel('seconds');
    end
    close;   
    
    % ---> Save electric channels
    for cont = 1:nelech
        icy = elec(cont,:);
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% constructing event-like data type %%%

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
        
        
        %--------------------------------
        %----> PLOT AND SAVE IMAGES <----
        
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
        
        %----> user-friendly Topological maps of mixing matrix columns <----

        if rc.eeg
            elecloc_ica = sc_trim_sens(data_arj.label(chan2ica_indexes), data_arj.hdr.elec);  %provides labels of chans that survived AR and were used for ICA
        else
            elecloc_ica = sc_trim_sens(data_arj.label(chan2ica_indexes), data_arj.hdr.grad);  %provides labels of chans that survived AR and were used for ICA
        end
        
        sc_locfile( elecloc_ica, saveFolderds); %creates a elc for topolot function
   
        ff = figure('visible','off');
        tiledlayout(lat,lat);
        for ix=1:noICvis
            nexttile
            if rc.eeg
                topoplot(IC_mix(:,ix), fullfile(saveFolderds, 'ch_trimmed.elc'), 'nosedir', chan.ori, 'verbose','off', 'electrodes', 'labels');
            else
                topoplot(IC_mix(:,ix), fullfile(saveFolderds, 'ch_trimmed.elc'), 'nosedir', chan.ori, 'verbose','off', 'electrodes', 'on');
            end
            title( ['IC ' num2str(ix) ], 'color', 'k')
        end
        print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_MAPS.jpg'),'-djpeg','-r180');
        close(ff);     
        
        %%% Getting Image data for further classification - MD
        
        noIC2clss1 = n_IC;  %MD
        if noIC2clss1 > 20;  noIC2clss1 = 20;  end  % limit the number of ICs for class1
        

        if ~strcmp(ica.ICA1_classMode,'cat')  % cat - modle with numeric features only, w/out figs
            ims = zeros(263, 350,3,size(IC_mix,2)); %3,ICA_Threshold); %Dummy images list
            for k = 1:noIC2clss1
                fig2 = figure();
                set(fig2,'visible','off');
                topoplot(IC_mix(:,k), fullfile(saveFolderds, 'ch_trimmed.elc'), 'nosedir', chan.ori,'verbose','off','electrodes', 'off','style' , 'map','headrad' ,0);
                FFF =imresize(getframe(fig2).cdata,[263, 350]);
                ims(:,:,:,k) = double(FFF);
                close(fig2) %mw
            end

            augmentedSet{it} = augmentedImageDatastore([263 350 3], ims);
        % 
        else
            augmentedSet{it} = [];
        end

        
        %--------------------------------------
        %----> Evoked Responses - ERD/ERS <----

        cd(dir2)

        if strcmp(seg.studyType, 'ER')
            for ind = 1:ncond
                figure ('visible','off');
                for ix = 1:n_IC
                    subplot(lat,lat,ix), plot([round(event(ind).t_pre*Fsnew/1000):round(event(ind).t_post*Fsnew/1000)]*(1/Fsnew),...
                        squeeze(ave(ind).mat(ix,:))); ylabel(['IC_sig ' num2str(ix)]); axis tight;
                    if ix == ceil(lat/2)
                        title( [dsname ': ERP' event(ind).name ' ;  ITER ', num2str(it, '%02.0f')],'FontSize',13);
                    end
                end
                print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_ERP', event(ind).name, '.jpg'), '-djpeg','-r150');
                close;
            end
        end
        
        %----> IC_sig time course <----
        
        fg = figure ('visible','off');
        for ix=1:noICvis
            sig = IC_sig(ix,:);
            base = time_ica;
            subplot(ceil(noICvis/2),2,ix),plot(base,sig);
            axis([base(1) base(end) min(sig)-0.1*(max(sig)-min(sig)) max(sig)+0.1*(max(sig)-min(sig))]);
            xticks([0:nSamp(1)/Fsnew:base(end)]);
            xlabels={};
            for t=1:base(end)/(nSamp(1)/Fsnew)
                xlabels{t}=num2str(t);
            end
            for la=1:length(xlabels)
                if rem(la,5)
                    xlabels{la}='';
                end
            end
            xticklabels(xlabels)
            ax = get(gca,'XTickLabel');  
            set(gca,'XTickLabel',ax,'fontsize',9)
            ax = gca;
            ax.XGrid = 'on';
            ax.YGrid = 'off';
            ylabel(['IC ' num2str(ix)]);
            if ix==1
                title( [dsname ': IC Z-timecourse; ITER ' num2str(it, '%02.0f') '; ICA1'],'FontSize',13);
            end
        end

        print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_ZTIMEC.jpg'), '-djpeg','-r150');
        %exportgraphics(fg, '~/myfigure.jpg', 'Resolution', 300); 

        close(fg);

        %----> IC_sig time course after moving aver<----

        if ar.ica_movAver
            IC_sig_mvav = movmean(IC_sig, ar.ica_movAver);
            figure ('visible','off');
            for ix=1:noICvis
                sig = IC_sig_mvav(ix,:);
                base = time_ica;
                subplot(ceil(noICvis/2),2,ix),plot(base,sig);
                axis([base(1) base(end) min(sig)-0.1*(max(sig)-min(sig)) max(sig)+0.1*(max(sig)-min(sig))]);
                xticks([0:nSamp(1)/Fsnew:base(end)]);
                xlabels={};
                for t=1:base(end)/(nSamp(1)/Fsnew)
                    xlabels{t}=num2str(t);
                end
                for la=1:length(xlabels)
                    if rem(la,5)
                        xlabels{la}='';
                    end
                end
                xticklabels(xlabels)
                ax = get(gca,'XTickLabel');
                set(gca,'XTickLabel',ax,'fontsize',9)
                ax = gca;
                ax.XGrid = 'on';
                ax.YGrid = 'off';
                ylabel(['IC ' num2str(ix)]);
                if ix==1
                    title( [dsname ': IC Z-timecourse-mov-aver; ITER ' num2str(it, '%02.0f') '; ICA1'],'FontSize',13);
                end
            end
            fontsize(6,'points')
            print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_ZTIMEC_MA.jpg'), '-djpeg','-r150');
            close;
        end
        
        clear sig;
        
        %----------------------------------
        %----> Power Spectral Density <----
        
        figure ('visible','off');
        
        for ix=1:noICvis
            Prms = mspettro(ix,:);
            subplot(ceil(noICvis/2),2,ix),plot(F,Prms,'r');
            
            if filter.HPfreq ==0  &&  filter.LPfreq==0
                lags = find(F>0 & F<min(100,100));
                max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
                axis([0 min(100,100) 0 max_val]);
            else
                lags = find(F>filter.HPfreq & F<min(100,filter.LPfreq));
                max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
                axis([filter.HPfreq min(100,filter.LPfreq) 0 max_val]);
                
            end
            ylabel(['IC_sig ' num2str(ix)]);
            if ix==1
                title( [dsname ': IC spectra; ITER ', num2str(it, '%02.0f')],'FontSize',9);
            end
        end
        fontsize(6,'points')
        print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_FREQ.jpg'), '-djpeg','-r150');
        close;
        
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

            %----------------------------------------------------------
            %---> classification : 0 = artifact   1 = brain signal <---
            %----------------------------------------------------------

            % %%% Chieti Classification
            % clas = zeros(1,n_IC); %AL
            % clas( find(G2 > thres_e & G3 < thres_f & H3 < thres_c) ) = 1; %---> Spectrum_flat - Time_kurtosis - Elc_spectrum_correlation
            % for ind = 1:ncond
            %     clas( find( T(ind,:) > thres_g) ) = 1;             %---> High variance in post-trigger period (with respect to pre???)
            % end
            % clas( find(G > thres_d | H > thres_a | H2 > thres_b) ) = 0;   %---> Spectrum_one_over_f - Elc_signal_correlation - Elc_power_correlation
            % good_ic = find( clas==1 );

            % %%% Chieti Classification ENDS

            % if nelech > 0
            %     art_con = mean( H2(good_ic) );
            % else
            %     art_con = 0;
            % end

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
    decomp_ica1.fsample = data_arj.fsample;
    decomp_ica1.label = data_arj.label;
    
    if isfield(data_arj, 'sampleinfo')
    decomp_ica1.sampleinfo = data_arj.sampleinfo;
    end
    
    decomp_ica1.ica_par = ica_par;  %ICA1 results are needed for primary AR, then they can be discarded
    decomp_ica1.ICA = ICA;
    decomp_ica1.event = event;
    decomp_ica1.nSamp = nSamp;
    
    decomp_ica1.dsname = dsname;
    decomp_ica1.actualchantype = actualchantype;
    
    % file_name = fullfile(saveFolder, [dsname '_ICA1_decomp.mat']);
    %         disp( [ '[' num2str(round( 100 * (ds / length(infile)))) '%] Saving DS: ', num2str(ds), ' - ', dsname] );
    % disp( [ 'ICA1 decomp: Saving DS ', dsname] );
    % save(file_name, 'decomp_ica1');   %save ICA1 decomposition only (data after ICA1 AR rej is performed in main sc_4_DECOMPOSITION_ICA wrapper)
    
else
    
    file_name = fullfile(saveFolder, [dsname '_ICA1_FAILED.mat']);
    emptyica = 'no convergence';
    save(file_name, 'emptyica');
    
    decomp_ica1.fsample = [];
    decomp_ica1.label = [];
    decomp_ica1.sampleinfo = [];
    decomp_ica1.ica_par = [];
    decomp_ica1.ICA = [];
    decomp_ica1.event = [];
    decomp_ica1.nSamp = [];
    decomp_ica1.dsname = dsname;
    
    augmentedSet = [];
    
end

%% ICA1 CLASS

load (ica.ICA1_classModel); %Load Model

     if ~isempty(decomp_ica1.ICA)

                % [~, dsname, ~] = fileparts( infile{ds} );
                ic_stat{1} = dsname;

                for it = 1:length(decomp_ica1.ICA.iter)    % loop by iterations
                    if ~isempty(decomp_ica1.ICA.iter(it).mixing)
                        % continue
                        % end
                        %%% Classifying with Categorical Model - MD

                        noIC2clss1 = decomp_ica1.ICA.iter(it).IC_sig;  %MD
                        if noIC2clss1 > 20;  noIC2clss1 = 20;  end  % limit the number of ICs for class1

                        if ~strcmp(ica.ICA1_classMode,'image')
                            % 
                            XTest2 = array2table(normalize(decomp_ica1.ICA.iter(it).elc_signal_correlation'),'VariableNames',{'elc_signal_corr'});
                            XTest2.Elc_spectrum_corr = normalize(decomp_ica1.ICA.iter(it).elc_spectrum_correlation');
                            XTest2.Spect_one_over_f = normalize(decomp_ica1.ICA.iter(it).spectrum_one_over_f');
                            XTest2.Spect_flat = normalize(decomp_ica1.ICA.iter(it).spectrum_flat');
                            XTest2.Kurtosis = normalize(decomp_ica1.ICA.iter(it).time_kurtosis');
                            XTest2.elc_power_corr = normalize(decomp_ica1.ICA.iter(it).elc_power_correlation');
                            setenv('gpuShouldBeUsed','false')
                            predictions_features = predict(IF_mlp_model,XTest2,'ExecutionEnvironment','cpu');


                            threshold = 0.5;
                            predictions_features = decomp_ica1.ICA.iter(it).elc_power_correlation<threshold & decomp_ica1.ICA.iter(it).elc_signal_correlation<threshold;

                            if strcmp(ica.ICA1_classMode,'cat'); predictions = predictions_features; end
                        end

                        %%% Classifying with image Model - MD
                        if ~strcmp(ica.ICA1_classMode,'cat')

                            % Get Predictions Upon
                            predictions_images = predict(IF_conv_model,augmentedSet{it},...
                                'MiniBatchSize',2);
                            if strcmp(ica.ICA1_classMode,'image')
                                predictions = predictions_images;
                            end
                        end

                        %%% Classifying with Joint Model - MD
                        if strcmp(ica.ICA1_classMode,'full')
                            predictions = (predictions_features(:,2) + predictions_images(:,1))/2;
                        end
                        clear predictions_images predictions_features
                        
                        if rc.resetGPU
                            if ~isempty(gpuDeviceTable)
                                try
                                    reset(gpuDevice(1));
                                catch
                                    parallel.gpu.enableCUDAForwardCompatibility(true)   % for too new cards
                                    reset(gpuDevice(1));

                                end
                            end
                        end
                        
                        Classif = predictions > 0.5;

                        good_ic = find( Classif==1 );

                        if ~isempty(chan.elec) > 0
                            art_con = mean(decomp_ica1.ICA.iter(it).elc_power_correlation(good_ic) );
                        else
                            art_con = NaN;
                        end

                        decomp_ica1.ICA.iter(it).artifact_contamination=art_con;
                        decomp_ica1.ICA.iter(it).predictions_proba = predictions;
                        decomp_ica1.ICA.iter(it).brain_ic_number=length(good_ic);
                        decomp_ica1.ICA.iter(it).brain_ic=good_ic;
                        clear predictions

                        goodness_ic(it,1) = length( good_ic );
                        goodness_ic(it,2) = 1-art_con;

                    else
                        goodness_ic(it,1) = 0;
                        goodness_ic(it,2) = NaN;

                    end

                end                

                if (max( goodness_ic(:,1).*goodness_ic(:,2) )>0)
                    [~,pos_best_iter] = max( goodness_ic(:,1).*goodness_ic(:,2) );
                else
                    max_poor_ic = decomp_ica1.ICA.iter(1).total_ic_number;  %if no brain_ic found, set best_iter using the highest no_ic
                    if isempty(max_poor_ic); max_poor_ic=0; end
                    pos_best_iter = 1;
                    for ii = 2:size(decomp_ica1.ICA.iter,2)
                        if decomp_ica1.ICA.iter(ii).total_ic_number > max_poor_ic
                            max_poor_ic = decomp_ica1.ICA.iter(ii).total_ic_number;
                            pos_best_iter = ii;
                        end
                    end
                end

                good_ic = decomp_ica1.ICA.iter(pos_best_iter).brain_ic;
                disp( strcat('non-linearity used: ', ica.ICA1_nonlinearity, ' - run number:', num2str(mod(pos_best_iter-1,ica.ICA1_numIter)+1)));
                decomp_ica1.ICA.best_iter.index = pos_best_iter;
                ic_stat{2} = pos_best_iter;
                decomp_ica1.ICA.best_iter.IC_sig =  decomp_ica1.ICA.iter(pos_best_iter).IC_sig;
                decomp_ica1.ICA.iter(pos_best_iter).brain_ic_number = length(good_ic);
                ic_stat{4} = length(good_ic);
                ic_stat{3} = decomp_ica1.ICA.iter(pos_best_iter).total_ic_number;
                decomp_ica1.ICA.iter(pos_best_iter).brain_ic = good_ic;
                saveFolder = fullfile(rc.analysisFolder, '4_ICA1');
                file_name = fullfile(saveFolder, [dsname '_ICA1_decomp.mat']);
                disp( strcat( 'ICA1 decomp: Saving DS ', dsname) );
                decomp_ica1.ic_stat = ic_stat;

                save(file_name, 'decomp_ica1');   %save ICA1 decomposition only (data after ICA1 AR rej is performed in main sc_4_DECOMPOSITION_ICA wrapper)
                clear goodness_ic

            end

end
