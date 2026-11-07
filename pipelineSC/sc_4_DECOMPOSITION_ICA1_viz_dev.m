function sc_4_DECOMPOSITION_ICA1_viz_dev(data_decomp_ica1, chan, rc, seg, ica, ar, filter)

%%% --- General Plot Parameters --- %%%
set( 0, 'DefaultLineLineWidth', 1, 'defaultFigurePosition', [40 120 3800 2000] );

saveFolder = fullfile(rc.analysisFolder, '4_ICA1');
saveFolderds = fullfile(rc.analysisFolder, '4_ICA1', data_decomp_ica1.dsname);
dir2 = fullfile(saveFolder, data_decomp_ica1.dsname);

dsname = data_decomp_ica1.dsname;
ncond = length(data_decomp_ica1.event);
Fsnew = data_decomp_ica1.fsample;
nSamp = data_decomp_ica1.sampleinfo(:,2) - data_decomp_ica1.sampleinfo  (:,1) +1;

time_ica = 1/Fsnew * (1:round( size(data_decomp_ica1.ICA.iter(1).IC_sig,2)/1));


%%% --- ELEC PLOT --- %%%%
if isfield(chan,"elec")
    nelech = length(chan.elec); %number of electric channels
else
    nelech = 0;
end
if nelech
    figure ('visible','off');

    % Elec features extraction:
    chan2ica_indexes = [find(strcmp(data_decomp_ica1.hdr.actualchantype, 'eeg'))' find(strcmp(data_decomp_ica1.hdr.actualchantype, 'mag'))' find(strcmp(data_decomp_ica1.hdr.actualchantype, 'meg'))' find(strcmp(data_decomp_ica1.hdr.actualchantype, 'meggrad'))' find(strcmp(data_arj.hdr.actualchantype, 'megmag'))'];
    elec_indexes = ( setxor(1:length(data_decomp_ica1.hdr.actualchantype), chan2ica_indexes) )';
    
    elec = zeros( n_elec, sum(nSamp));
    
    for tr = 1 : length(data_decomp_ica1.trial)
        begsample = sum( nSamp(1:(tr-1)) ) + 1;
        endsample = sum( nSamp(1:tr) );
        elec(: , begsample:endsample ) = data_decomp_ica1.trial{tr}(elec_indexes, :);
    end


    for i = 1:nelech

        if std(elec(i,:)) > 0; sige=(elec(i,:)-mean(elec(i,:)))/std(elec(i,:)); end
        sige = decimate(sige,dec);

        subplot(ceil(nelech/2),2,i); plot(time_ica,sige); axis tight;
        ylabel(['ELC ' num2str(i-1)]); xlabel('seconds');
    end
    close;   
end
        %%% --- GENERAL ICA PLOT --- %%%


for it = 1 : ica.ICA1_numIter
    n_IC = data_decomp_ica1.ICA.iter(it).total_ic_number;
    if n_IC>0
        IC_mix = data_decomp_ica1.ICA.iter(it).mixing;
        IC_sig = data_decomp_ica1.ICA.iter(it).IC_sig;
    
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
        base = time_ica;


        %--------------------------------------
        %----> ICA Topography plot <----

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





        %--------------------------------------
        %----> Evoked Responses - ERD/ERS <----

        cd(dir2)

        if strcmp(seg.studyType, 'ER')
            for ind = 1:ncond
                figure ('visible','off');
                for ix = 1:n_IC

                    ave_curr = average(IC_sig(ix,:),data_decomp_ica1.event(ind).peaks_pos,...
                        round(data_decomp_ica1.event(ind).t_pre*Fsnew/1000),round(data_decomp_ica1.event(ind).t_post*Fsnew/1000),...
                        round(data_decomp_ica1.event(ind).t_baseline_on*Fsnew/1000),round(data_decomp_ica1.event(ind).t_baseline_off*Fsnew/1000));
                 

                    subplot(lat,lat,ix), plot([round(data_decomp_ica1.event(ind).t_pre*Fsnew/1000):round(data_decomp_ica1.event(ind).t_post*Fsnew/1000)]*(1/Fsnew),...
                        squeeze(ave_curr)); ylabel(['IC_sig ' num2str(ix)]); axis tight;
                    if ix == ceil(lat/2)
                        title( [dsname ': ERP' data_decomp_ica1.event(ind).name ' ;  ITER ', num2str(it, '%02.0f')],'FontSize',13);
                    end
                end
                print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_ERP', data_decomp_ica1.event(ind).name, '.jpg'), '-djpeg','-r150');
                close;
            end
        end
        
        %--------------------------------------        
        %----> IC_sig time course <----
        
        fg = figure ('visible','off');
        for ix=1:noICvis
            sig = IC_sig(ix,:);
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
        exportgraphics(fg, '~/myfigure.jpg', 'Resolution', 300); 

        close(fg);

        %----> IC_sig time course after moving aver<----

        if ar.ica_movAver
            IC_sig_mvav = movmean(IC_sig, ar.ica_movAver);
            figure ('visible','off');
            parfor ix=1:noICvis
                sig = IC_sig_mvav(ix,:);
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
        
        win = 1024*ceil( 4/(1+1) );
           
        
        figure ('visible','off');
        IC_sigep = reshape(IC_sig, size(IC_sig,1), length(data_decomp_ica1.sampleinfo  ), []);
        spectral_estimator = spectrum.welch('Hamming',win,0);

        for ix=1:noICvis

            
            Power_Spectrum = psd(spectral_estimator,IC_sigep(ix,:),'NFFT',win,'Fs',Fsnew);
            
            Prms = sqrt((Fsnew/win)*Power_Spectrum.Data)';
            subplot(ceil(noICvis/2),2,ix),plot(Power_Spectrum.Frequencies,Prms,'r');
            
            if filter.HPfreq ==0  &&  filter.LPfreq==0
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
                title( [dsname ': IC spectra; ITER ', num2str(it, '%02.0f')],'FontSize',9);
            end
        end
        fontsize(6,'points')
        print( strcat(dir2, '/', dsname, '_iter', num2str(it, '%02.0f'), '_FREQ.jpg'), '-djpeg','-r150');
        close;

    end
end

