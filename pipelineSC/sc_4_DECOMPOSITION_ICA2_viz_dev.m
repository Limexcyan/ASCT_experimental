function sc_4_DECOMPOSITION_ICA2_viz_dev(data_ica2, chan, rc, seg, ica, filter)

set( 0, 'DefaultLineLineWidth', 1, 'defaultFigurePosition', [40 120 1500 800]);

saveFolderds = fullfile(rc.analysisFolder, '6_ICA2', data_ica2.hdr.dsname);

dsname = data_ica2.hdr.dsname;
ncond  = length(data_ica2.event);
Fsnew  = data_ica2.fsample;
nSamp  = data_ica2.sampleinfo(:,2) - data_ica2.sampleinfo  (:,1) +1;

time_ica = 1/Fsnew * (1:round( size(data_ica2.ICA.iter(1).IC_sig,2)/1));

chan2ica_indexes = [find(strcmp(data_ica2.hdr.actualchantype, 'eeg'))' find(strcmp(data_ica2.hdr.actualchantype, 'mag'))' find(strcmp(data_ica2.hdr.actualchantype, 'meg'))' find(strcmp(data_ica2.hdr.actualchantype, 'meggrad'))' find(strcmp(data_ica2.hdr.actualchantype, 'megmag'))'];
chan2ica_labels = data_ica2.label(chan2ica_indexes);

olddir = pwd;
cd(saveFolderds)
if rc.eeg
    elecloc_ica = sc_trim_sens(chan2ica_labels, data_ica2.hdr.elec); 
else
    elecloc_ica = sc_trim_sens(chan2ica_labels, data_ica2.hdr.grad);  %provides labels of chans that survived AR and were used for ICA
end
sc_locfile( elecloc_ica, saveFolderds); %trims elc file according to actual no of channels
cd(olddir)


%%% --- ELEC PLOT --- %%%%
if isfield(chan,"elec")
    nelech = length(chan.elec); %number of electric channels
else
    nelech = 0;
end
if nelech
     
    % Elec features extraction:
    elec_indexes = ( setxor(1:length(data_ica2.hdr.actualchantype), chan2ica_indexes) )';
    
    elec = zeros( n_elec, sum(nSamp));
    
    for tr = 1 : length(data_ica2.trial)
        begsample = sum( nSamp(1:(tr-1)) ) + 1;
        endsample = sum( nSamp(1:tr) );
        elec(: , begsample:endsample ) = data_ica2.trial{tr}(elec_indexes, :);
    end

    figure ('visible','off');
    for i = 1:nelech
        if std(elec(i,:)) > 0; sige=(elec(i,:)-mean(elec(i,:)))/std(elec(i,:)); end
        sige = decimate(sige,dec);

        subplot(ceil(nelech/2),2,i); plot(time_ica,sige); axis tight;
        ylabel(['ELC ' num2str(i-1)]); xlabel('seconds');
    end
    close;   
end
        %%% --- GENERAL ICA PLOT --- %%%

for it = 1 : ica.ICA2_numIter
    disp(strcat(' [', num2str( round(it/length(ica.ICA2_numIter)*100)), '%] Loading ICA1 Iter: ',it));

    n_IC = data_ica2.ICA.iter(it).total_ic_number;

    if n_IC > 0

        % Prepare Data for Viz (Power, Signal Mixing) 
        IC_mix = data_ica2.ICA.iter(it).mixing;
        IC_sig = data_ica2.ICA.iter(it).IC_sig;
        for ic = 1 : n_IC
            IC_pow(ic) = mean( IC_mix(:,ic).^2 );
        end

        [IC_pow , ~] = sort( IC_pow );
        IC_pow = fliplr( IC_pow  );

        
        % Viz Limits 
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
            
      
      
        %---->  Power Spectrum Plot <----- %
        pwrp = figure('Visible', 'off');
        plot(IC_pow)
        curtick = get(gca, 'xTick');
        xticks(unique(round(curtick)));
        set(gca, 'FontSize', 10);
        print( strcat(saveFolderds, '/', dsname, '_iter', num2str(it, '%02.0f'), '_ICpower.jpg'),'-djpeg','-r180');
        close(pwrp)


        
        %---->  Topographic Plot <----- %
        ff = figure ('visible','off');
        set(ff,'position',[0,0,3000,2000])
        tiledlayout(lat,lat);   %original subplot layout
        % for ix=noICvis:-1:1
        for ix=1:noICvis
            nexttile
            if rc.eeg
                topoplotsc(IC_mix(:,noICvis-ix+1), char(fullfile(saveFolderds, 'ch_trimmed.elc')), 'nosedir', chan.ori, 'electrodes', 'labels');
            else
                topoplotsc(IC_mix(:,noICvis-ix+1), char(fullfile(saveFolderds, 'ch_trimmed.elc')), 'nosedir', chan.ori, 'electrodes', 'on');
            end
 
            title( ['IC ' num2str(noICvis-ix+1) ], 'color', 'k')
        end
        
        print( strcat(saveFolderds, '/', dsname, '_iter', num2str(it, '%02.0f'), '_MAPS.jpg'),'-djpeg','-r180');        
        close(ff);

        
        %----> Evoked Responses - ERD/ERS <----
        cd(saveFolderds)
        if strcmp(seg.studyType, 'ER')
            
            for ind = 1:ncond
                figure ('visible','off');
                for ix = 1:n_IC


                    ave_curr = average(IC_sig(ix,:),data_ica2.event(ind).peaks_pos,...
                        round(data_ica2.event(ind).t_pre*Fsnew/1000),round(data_ica2.event(ind).t_post*Fsnew/1000),...
                        round(data_ica2.event(ind).t_baseline_on*Fsnew/1000),round(data_ica2.event(ind).t_baseline_off*Fsnew/1000));
                 

                    subplot(lat,lat,ix), plot([round(data_ica2.event(ind).t_pre*Fsnew/1000):round(data_ica2.event(ind).t_post*Fsnew/1000)]*(1/Fsnew),...
                        squeeze(ave_curr)); ylabel(['IC_sig ' num2str(ix)]); axis tight;
                    if ix == ceil(lat/2)
                        title( [dsname ': ERP' data_ica2.event(ind).name ' ;  ITER ', num2str(it, '%02.0f')],'FontSize',10);
                    end
                end
                print( strcat(saveFolderds, '/', dsname, '_iter', num2str(it, '%02.0f'), '_ERP', data_ica2.event(ind).name, '.jpg'), '-djpeg','-r180');
                close;
            end
        end
        
        
        %% --------------------------
        %----> IC_sig time course <----
        
        figure ('visible','off');
        
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
            xticklabels(xlabels)
            xticklabels(xlabels)
            ax = gca;
            ax.XGrid = 'on';
            ax.YGrid = 'off';
            ylabel(['IC ' num2str(ix)]);
            if ix==1
                title( [dsname ': IC timecourse; ITER ' num2str(it, '%02.0f') '; ICA2'],'FontSize',10);
            end
        end
        
        
        clear sig;
        print( strcat(saveFolderds, '/', dsname, '_iter', num2str(it, '%02.0f'), '_TIMEC.jpg'), '-djpeg','-r180');
        close;
        
        %% ----> Power Spectral Density <----
        win = 1024*ceil( 4/(1+1) );

        figure ('visible','off');
        IC_sigep = reshape(IC_sig, size(IC_sig,1), length(data_ica2.sampleinfo  ), []);
        spectral_estimator = spectrum.welch('Hamming',win,0);

        for ix=1:noICvis
            Power_Spectrum = psd(spectral_estimator,IC_sigep(ix,:),'NFFT',win,'Fs',Fsnew);
            Prms = sqrt((Fsnew/win)*Power_Spectrum.Data)';

            subplot(ceil(noICvis/2),2,ix),plot(Power_Spectrum.Frequencies,Prms,'r');
            if filter.HPfreq ==0  ||  filter.LPfreq==0
                lags = find(Power_Spectrum.Frequencies>0 & Power_Spectrum.Frequencies<min(100,100));
                max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
                axis([0 min(100,100) 0 max_val]);
            else
                lags = find(Power_Spectrum.Frequencies>filter.HPfreq & Power_Spectrum.Frequencies<min(100,filter.LPfreq));
                max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
                axis([filter.HPfreq min(100,filter.LPfreq) 0 max_val]);
                
            end
            ylabel(['IC_sig ' num2str(ix)]);
            if ix==1
                title( [dsname ': IC spectra; ITER ' num2str(it, '%02.0f') '; ICA2'],'FontSize',10);
            end
        end
        
        
        print( strcat(saveFolderds, '/', dsname, '_iter', num2str(it, '%02.0f'), '_FREQ.jpg'), '-djpeg','-r180');
        close;
        
    end
            

end
