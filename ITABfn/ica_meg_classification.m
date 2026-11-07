
clear all;
warning off;

load('colors.mat');
code_dir = pwd;

set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[40 120 1200 800]);
% set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[80 120 1000 680]);   per schermi con risoluzione 1024x768

study = 1 %check !! temporary

%----------------------------------
%----> Set path and file name <---- 
%----------------------------------

% [path_raw, path_data] = find_path;
path_raw='/mnt/devv/SourceConn/Exp/Sara/';
path_data='/mnt/devv/SourceConn/Exp/Sara/';
cd(path_data);
[f d]  = uigetfile({'*.mat','ICA separation file (*.ICA)'});
filename = fullfile(d,f); 
% indx = strfind(filename,'\');
% filename(indx) = '/';
% path_data = fullfile(path_data, f(1:13));
cd(path_data);
% tmp_name=[f(1:end-4) '_tmp.mat'];
nome_file = f(1:end-10);
dir2 = strcat(path_data, nome_file, '/', nome_file, '_sig/');
filename_par = fullfile(path_data,strcat(f(1:end-10),'.par'));

% [h_filtering,l_filtering,freq_notch, dec, ica_method,ica_iter, num_segments,skipped_intervals, study, file_evt, ...
%     ncond, event, low_freq, up_freq, ech, res_chan] = read_par_file(filename_par);
clear event;
load(filename)

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


if ~isfolder(dir2); mkdir(dir2); end

%----------------------------------
%----> Set path and file name <----
%----------------------------------


disp('IC identification...');

[nIC, nptIC] = size(ICA.best_iter.IC);
clas = zeros(1,nIC);
best_iter = ICA.best_iter.index;
clas(ICA.iteration(best_iter).brain_ic) = 1;

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

window = 10;          %expressed in seconds
window_base = find(ica_par.time_ica >= ica_par.time_ica(1) & ica_par.time_ica < window+ica_par.time_ica(1));     % expressed in number of points

flag = 0;
while flag == 0

    b_ic = [];
    g_ic = [];

    for i = 1:nIC
        sig = ICA.best_iter.IC(i,:);
        
        switch study
            case 0
                 figure;
                 subplot(2,5,1:3), plot(ica_par.time_ica,sig);
                   axis tight; title('time course'); xlabel('s');
                 subplot(2,2,3), plot(ica_par.time_ica(window_base),sig(window_base));
                   axis tight; title('time course'); xlabel('seconds');
                 subplot(2,2,4), plot(F,mspettro(i,:),'r');
                   axis([0 min(100,ica_par.filter.freq_high) 0 1.1*max(mspettro(i,:))]); title('power spectrum'); xlabel('Hertz');
                 subplot(2,5,4:5), showfield(ICA.iteration(best_iter).mixing(:,i),pos_channels); colormap(Cx_map);

                 title(strcat('IC no. ',num2str(i)),'FontSize',12);
                 print(strcat(dir2, nome_file, '_ic', num2str(i), '_classification.tif'),'-dtiff','-r200');
            case 1
                 for ind = 1:ncond
                     figure;
                     subplot(2,5,1:3), plot(ica_par.time_ica,sig);
                       axis tight; title('time course'); xlabel('s');
                     ave = average(sig,event(ind).peaks_pos,round(event(ind).t_pre*Fsnew/1000),round(event(ind).t_post*Fsnew/1000),...
                        round(event(ind).t_baseline_on*Fsnew/1000),round(event(ind).t_baseline_off*Fsnew/1000));
                     subplot(2,2,4), plot(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,length(ave)),ave);
                        axis( [event(ind).t_pre/1000 event(ind).t_post/1000 1.1*min(min(ave)) 1.1*max(max(ave)) ]);
                        title('ERF'); xlabel('ms'); 
                     subplot(2,2,3), plot(F,mspettro(i,:),'r');
                       axis([ 0  min(100,ica_par.filter.freq_high)  0  1.1*max(mspettro(i,:)) ]); title('power spectrum'); xlabel('Hertz');
                       title('power spectrum'); xlabel('Hz');
                     subplot(2,5,4:5), showfield(ICA.iteration(best_iter).mixing(:,i),pos_channels); colormap(Cx_map);

                     title(strcat('IC no. ',num2str(i),' - condition ',event(ind).name),'FontSize',12);
                     print([dir2, nome_file, '_ic', num2str(i), '_cond', event(ind).name, '_class.jpg'],'-djpeg','-r100');
                 end
             case 2
                 for ind = 1:ncond
                    figure;
                    subplot(2,5,1:3), plot(ica_par.time_ica,sig);
                      axis tight; title('time course'); xlabel('s');

                    [X,Fx,decx] = calculate_spec(sig,Fsnew,l_filtering);
                    
                    mx_on = (resample((average_erd_ers(X,round(event(ind).peaks_pos_on/decx),round(event(ind).t_pre*Fsnew/(decx*1000)),round(event(ind).t_post*Fsnew/(decx*1000)),...
                        round(event(ind).t_baseline_on*Fsnew/(decx*1000)),round(event(ind).t_baseline_off*Fsnew/(decx*1000))))',decx,1))';
                    mx_off = (resample((average_erd_ers(X,round(event(ind).peaks_pos_off/decx),round(event(ind).t_pre*Fsnew/(decx*1000)),round(event(ind).t_post*Fsnew/(decx*1000)),...
                        round(event(ind).t_baseline_on*Fsnew/(decx*1000)),round(event(ind).t_baseline_off*Fsnew/(decx*1000))))',decx,1))';

                    ave_on = mean((mx_on(find(Fx > low_freq & Fx < up_freq),:)));
                    ave_off = mean((mx_off(find(Fx > low_freq & Fx < up_freq),:)));
            
                    subplot(4,5,13), plot(linspace(event(ind).t_pre/1000, event(ind).t_post/1000,length(ave_on)),ave_on);
                    axis([event(ind).t_baseline_on/1000 event(ind).t_post/1000-0.1 min(ave_on)-0.1*(max(ave_on)-min(ave_on)) max(ave_on)+0.1*(max(ave_on)-min(ave_on))]);
                      title('ERD & ERS plots - ON'); 
                    subplot(4,5,18), plot(linspace(event(ind).t_pre/1000, event(ind).t_post/1000,length(ave_off)),ave_off);
                      axis([event(ind).t_baseline_on/1000 event(ind).t_post/1000-0.1 min(ave_off)-0.1*(max(ave_off)-min(ave_off)) max(ave_off)+0.1*(max(ave_off)-min(ave_off))]);
                      title('ERD & ERS plots - OFF');xlabel('s');
                    subplot(4,5,[14 19]), imagesc(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,size(mx_on,1)),Fx,mx_on);
                      fvect = find(Fx > low_freq & Fx < up_freq);
                      axis ([event(ind).t_pre/1000 event(ind).t_post/1000 Fx(fvect(1)) Fx(fvect(end))]);
                      title('ERD/ERS map - ON');  caxis([-100 100]); colormap(Cx_image); colorbar('horiz'); ylabel('Hz'); xlabel('s');
                    subplot(4,5,[15 20]), imagesc(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,size(mx_off,1)),Fx,mx_off); 
                      axis ([event(ind).t_pre/1000 event(ind).t_post/1000 Fx(fvect(1)) Fx(fvect(end))]);
                      title('ERD/ERS map - OFF');  caxis([-200 200]); colormap(Cx_image); colorbar('horiz'); ylabel('Hz'); xlabel('s');

                      subplot(4,5,[11 12 16 17]), plot(F,mspettro(i,:),'r');
                       axis([ 0  min(100,ica_par.filter.freq_high)  0  1.1*max(mspettro(i,:)) ]); title('power spectrum'); xlabel('Hertz');
                       title('power spectrum'); xlabel('Hz');
                     subplot(2,5,4:5), showfield(ICA.iteration(best_iter).mixing(:,i),pos_channels); colormap(Cx_map);
                     title(['IC no. ' num2str(i) ' - condition ' event(ind).name],'FontSize',12);
                     print([dir2, nome_file, '_ic', num2str(i), '_condition_', event(ind).name, '_classification.tif'],'-dtiff','-r200');
                 end
 
            case 3
                 for ind=1:ncond
                     figure;
                     subplot(2,5,1:3), plot(ica_par.time_ica,sig);
                       axis tight; title('time course'); xlabel('s');
                    
                     [X,Fx,decx] = calculate_spec(sig,Fsnew,l_filtering);
                     mx_on = (resample((average_erd_ers(X,round(event(ind).peaks_pos/decx),round(event(ind).t_pre*Fsnew/(decx*1000)),round(event(ind).t_post*Fsnew/(decx*1000)),...
                       round(event(ind).t_baseline_on*Fsnew/(decx*1000)),round(event(ind).t_baseline_off*Fsnew/(decx*1000))))',decx,1))';
                     
                     ave_on = mean((mx_on(find(Fx > low_freq & Fx < up_freq),:)));

                     subplot(4,5,13), plot(linspace(event(ind).t_pre/1000, event(ind).t_post/1000,length(ave_on)),ave_on);
                       axis([event(ind).t_baseline_on/1000 event(ind).t_post/1000-0.1 min(ave_on)-0.1*(max(ave_on)-min(ave_on)) max(ave_on)+0.1*(max(ave_on)-min(ave_on))]);
                       title('ERD & ERS plots');
 
                     subplot(4,5,[14 15 19 20]),imagesc(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,size(mx_on,1)),Fx,mx_on);
                       fvect = find(Fx > low_freq & Fx < up_freq);
                       axis ([event(ind).t_pre/1000 event(ind).t_post/1000 Fx(fvect(1)) Fx(fvect(end))]);
                       title('ERD or ERS map');  caxis([-100 100]);
                       colormap(Cx_image); colorbar('vert');  ylabel('Hz');
 
                     subplot(4,5,[11 12 16 17]), plot(F,mspettro(i,:),'r');
                       axis([ 0  min(100,ica_par.filter.freq_high)  0  1.1*max(mspettro(i,:)) ]); title('power spectrum'); xlabel('Hertz');
                       title('power spectrum'); xlabel('Hz');
                     subplot(2,5,4:5), showfield(ICA.iteration(best_iter).mixing(:,i),pos_channels); colormap(Cx_map);
                     title(strcat('IC no. ', num2str(i), ' - condition ', event(ind).name),'FontSize',12);
                    
                     ave = average(sig,event(ind).peaks_pos,round(event(ind).t_pre*Fsnew/1000),round(event(ind).t_post*Fsnew/1000),...
                        round(event(ind).t_baseline_on*Fsnew/1000),round(event(ind).t_baseline_off*Fsnew/1000));
                     subplot(4,5,18), plot(linspace(event(ind).t_pre,event(ind).t_post,length(ave)),ave);
                        axis( [event(ind).t_pre event(ind).t_post 1.1*min(min(ave)) 1.1*max(max(ave)) ]);
                        title('ERF'); xlabel('ms');
 
                     print(strcat(dir2, nome_file, '_ic', num2str(i), '_condition_', event(ind).name, '_classification.tif'),'-dtiff','-r200');
                 end

        end
%         pause;
        
        if clas(i) > 0
            ButtonName=questdlg('How do you classify this component?', ...
                'Independent Components classification','Brain signal','Artifact','Brain signal');
            disp(['component no. ' num2str(i) ' - automatic classification : ',ButtonName]);

        else
            ButtonName=questdlg('How do you classify this component?', ...
                'Independent Components classification','Brain signal','Artifact','Artifact');
             disp(['component no. ' num2str(i) ' - automatic classification : ',ButtonName]);
        end

        if strcmp(ButtonName,'Brain signal')
            g_ic = [g_ic i];
        else
            b_ic = [b_ic i];
        end
        close all;
    end

    clear sig mat;

    ButtonName=questdlg('Are you sure that the classification is correct?', ...
        'Independent Components classification','Yes','No','Yes');

    if strcmp(ButtonName,'Yes')
        flag=1;
    end 
        
end

ICA.iteration(best_iter).brain_ic_number = length(g_ic);
ICA.iteration(best_iter).brain_ic = g_ic;

%%% DA QUI

fx = [nome_file '_meg2_class.mat'];
path_file = strcat(path_data,fx);

% % save(path_file,...
%     'ica_par',...%struct with IC decomposition parameters
%     'ICA',...%struct with results of IC decomposition for each iteration
%     'event',...%struct with analysis type and conditions 
%     'header'); %original mhd 

% clear all
