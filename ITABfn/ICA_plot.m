
clear all;
warning off;

load('colors.mat');
code_dir = pwd;

set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[40 120 1200 800]);
% set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[80 120 1000 680]);   per schermi con risoluzione 1024x768


%----------------------------------
%----> Set path and file name <----
%----------------------------------

[path_raw, path_data] = find_path;
cd(path_data);
[f d]  = uigetfile({'*.mat','ICA separation file (*.ICA)'});
filename = fullfile(d,f);
indx = strfind(filename,'\');
filename(indx) = '/';
path_data = strcat(path_data,f(1:11),'\');
cd(path_data);
nome_file = f(1:end-8);
dir2 = strcat(path_data,nome_file,'_sig\');
filename_par = fullfile(path_data,strcat(f(1:end-8),'.par'));

[h_filtering,l_filtering,freq_notch, dec, ica_method,ica_iter, num_segments,skipped_intervals, study, file_evt, ...
     ncond, event, low_freq, up_freq, ech, res_chan] = read_par_file(filename_par);
% % clear event;
load(filename)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%
% Read good channels
%%%%%%%%%%%%%%%%%%%%%%%%%

gch = set_channels(header,'MAG','working');
nch = length(gch);
% leng = header.ntpdata;

lab_channels=cell(nch,1);
for i=1:nch
    lab_channels{i}=header.ch(gch(i)).label;
    pos_channels(i,1:3) = header.ch(gch(i)).pos(1).r_s.comp; 
end
pos_channels = mk_sensors_plane_channels_id(pos_channels,0,0,gch-1);
pos_channels = pos_channels(:,2:4);
close all

Fsnew = header.smpfq/ica_par.dec_fact;
ncond = size(event,2);

%----------------------------------
%----> Set path and file name <----
%----------------------------------

[nIC, nptIC] = size(ICA.best_iter.IC);
AA = ICA.iteration(ICA.best_iter.index).mixing;
lat=ceil(sqrt(nIC));
  
%-----------------------------------------------
%------ POWER SPECTRAL DENSITY ESTIMATION  -----
%-----------------------------------------------

win = 1024*ceil(4/(ica_par.dec_fact+1));
for ix=1:nIC
    spectral_estimator = spectrum.welch('Hamming',win,0);
    Power_Spectrum = psd(spectral_estimator,ICA.best_iter.IC(ix,:),'NFFT',win,'Fs',Fsnew);
    mspettro(ix,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
    F = Power_Spectrum.Frequencies;
end

    %--------------------------
    %----> IC time course <----
    %--------------------------
    
    figure;
    base = ica_par.time_ica;
    for ix=1:nIC
        sig = ICA.best_iter.IC(ix,:);
        subplot(ceil(nIC/2),2,ix),plot(base,sig);
        axis([base(1) base(end) min(sig)-0.1*(max(sig)-min(sig)) max(sig)+0.1*(max(sig)-min(sig))]);
        ylabel(['IC ' num2str(ix)]);
        if ix==1
            title('IC timecourses','FontSize',14);
        end
    end
    clear sig;

    
    %----------------------------------
    %----> Power Spectral Density <----
    %----------------------------------
    
    figure;
    for ix=1:nIC
        Prms = mspettro(ix,:);
        subplot(ceil(nIC/2),2,ix),plot(F,Prms,'r');
        lags = find(F>h_filtering & F<min(100,l_filtering));
        max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
        axis([h_filtering min(100,l_filtering) 0 max_val]);
        ylabel(['IC ' num2str(ix)]);
        if ix==1
            title('IC power spectra','FontSize',14);
        end
    end


    
    %-----------------------------------------------------
    %----> Topological maps of mixing matrix columns <----
    %-----------------------------------------------------
    
    figure;
    for ix=1:nIC
        subplot(lat,lat,ix), showfield(AA(:,ix),pos_channels);
        xlabel(['IC ' num2str(ix)],'color','k'); colormap(Cx_map);
        if ix==ceil(lat/2)
            title('IC sensor maps','FontSize',14);
        end
    end
   
   disp('PRESS!!!!')
   pause
        
    ButtonName='Yes';
    hh = figure;
    while ~strcmp(ButtonName,'No')
        ButtonName=questdlg('Do you want to plot a single IC?', ...
            'Question', ...
            'Yes','No','No');
        close(hh)
        if strcmp(ButtonName,'Yes')
            risposta = inputdlg({'Fill in the number of electric channels'},'Electric channel selection for artifact detection',1,{num2str(1:nIC)});
            ICA_list = [str2num(risposta{1})];
            hh = figure;
            lags = find(F>h_filtering & F<min(100,l_filtering));
            for ix=1:length(ICA_list)
                jj = ICA_list(ix);
                sig = ICA.best_iter.IC(jj,:);
                subplot(length(ICA_list),3,(ix-1)*3+1),plot(base,sig);
                ylabel(strcat('IC n. ',num2str(jj)));
                
                Prms = mspettro(jj,:);
                subplot(length(ICA_list),3,(ix-1)*3+2),plot(F,Prms,'r');
                max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
                axis([h_filtering min(100,l_filtering) 0 max_val]);
                
                subplot(length(ICA_list),3,(ix-1)*3+3), showfield(AA(:,jj),pos_channels);
                colormap(Cx_map);
                
            end
            pause
        end
    end
    
    close('all')
