%function [] = ica_meg

maxNumIter = 150;  %def = 200

warning off;

load('colors.mat');
code_dir = pwd;

set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[40 120 1200 800]);
% set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[80 120 1000 680]);   per schermi con risoluzione 1024x768


%----------------------------------
%----> Set path and file name <----
%----------------------------------

% [path_raw, path_data] = find_path;
path_raw='/mnt/iSCSI1/Users/adaml/Devv/SourceConn/Exp/Sara/dfbdtl92_0201';
path_data='/mnt/iSCSI1/Users/adaml/Devv/SourceConn/Exp/Sara/dfbdtl92_0201';


% if nargin < 1
    cd(path_raw);
    [f d]  = uigetfile({'*.raw','MEG file (*.raw)'});
% end
filename = fullfile(d,f);
% indx=strfind(filename,'/');
% filename(indx) = '/';
% path_data = strcat(path_data);
cd(path_data);

tmp_name = [f(1:end-4) '_tmp.mat'];
nome_file = f(1:end-4);
filename_par = fullfile(path_data,strcat(f(1:end-4),'.par'));



%-----------------------
%----> Read header <----
%-----------------------
 
% system_str = computer;
system_str = 'PCWIN';

% if(strcmp(system_str,'PCWIN'))
    header = lcreadheader(filename); 
% elseif(strcmp(system_str,'PCWIN64'))
%     filename_h = strcat(path_data,f(1:end-4),'_mhd.mat');
%     load(filename_h);
% else
%     error('operating system not supported!'); 
% end

if header.raw_header_type == header.header_type
    warning('warning! master header not loaded...'); 
end


%%%%%%%%%%%%%%%%%%%%%%%%%
% Read good channels
%%%%%%%%%%%%%%%%%%%%%%%%%

gch = set_channels(header,'MAG','working');
nch = length(gch);
leng = header.ntpdata;

Fs=header.smpfq;

lab_channels=cell(nch,1);
for i=1:nch
    lab_channels{i} = header.ch(gch(i)).label;
    pos_channels(i,1:3) = header.ch(gch(i)).pos(1).r_s.comp; 
end

pos_channels = mk_sensors_plane_channels_id(pos_channels,0,0,gch-1);
pos_channels = pos_channels(:,2:4);
close all


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set parameters for analysis 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%------> read parameters from text file

[h_filtering,l_filtering,freq_notch, dec, ica_method,ica_iter, num_segments, skipped_intervals, study, file_evt, ...
    ncond, event, low_freq, up_freq, ech, res_chan] = read_par_file(filename_par);

%------> set MAXIMAL DATA LENGTH
block = leng;
% if block > 100000  %%% Attenzione: per le mie elaborazioni
%     block=100000;
% end

%------> set DECIMATION

dec_ntp = round(leng/block);
dec_opt = round(0.8*Fs/(2*l_filtering));

%decimazione possibile a scelta dell'utente con verifica sul numero max e min di punti
% if dec > dec_opt
%     dec = dec_opt;
% end
% 
% if dec > dec_ntp
%     dec = dec_ntp;
% end

if length(freq_notch) > 0
    offsetx=10000;
else
    offsetx=3000;
end
offset=round(offsetx/dec);

Fsnew=Fs/dec;

%------> set TIME AXIS

timeline_dec = 1/Fsnew*[1:round(leng/dec)];
time_position=ones(size(timeline_dec));
for z=1:size(skipped_intervals,1)
    time_position(timeline_dec >= skipped_intervals(z,1) & timeline_dec <= skipped_intervals(z,2)) = 0;
end

time_position(1:offset) = 0;
time_position(end-offset+1:end) = 0;
time_flag = find(time_position==1);

block = min(block,length(time_flag));  %%% Maximal data length for ICA block = 100000: 
time_ica = timeline_dec(time_flag(1:block));   

tmp_dir = pwd;

if study > 0

    %----> Load triggers from evt
    triggers = load_evt(file_evt);

    %----> Checking triggers and find trigger time lags
    if study ~= 2
        for k = 1:ncond
            codes(k) = event(k).labels;
        end
    else
        for k = 1:ncond
            codes(k) = event(k).labels_on;
            codes(k+ncond) = event(k).labels_off;
        end
    end

    disp('checking triggers...');
    del_trig=[];

    for i = 1:length(triggers)
        timex = triggers(i,1);
        condx = triggers(i,2);
        
        if study ~= 2
            zz = find(codes == condx);
        else
            zz = find(codes == condx);
            if zz > ncond, zz = zz-ncond; end
        end
        if ~isempty(zz)
            if min(abs(timex+event(zz).t_pre/1000-time_ica)) > 1/Fsnew | min(abs(timex+event(zz).t_post/1000-time_ica)) > 1/Fsnew | min(abs(timex-time_ica)) > 1/Fsnew
                del_trig = [del_trig i];
                disp(['trigger time : ' num2str(timex) ' sec - deleted!']);
            else
                disp(['trigger time : ' num2str(timex) ' sec - OK']);
            end
        end
    end
    triggers(del_trig,:)=[];

    if study ~= 2
        for zz=1:ncond
            event(zz).times = triggers(find(triggers(:,2)==codes(zz)),1)';
            for cont = 1:length(event(zz).times)
                [tmp,peaks_pos] = min(abs(event(zz).times(cont)-time_ica));
                event(zz).peaks_pos(cont) = peaks_pos;
            end
        end
    else
        for zz=1:ncond
            event(zz).times_on = triggers(find(triggers(:,2)==codes(zz)),1)';
            event(zz).times_off = triggers(find(triggers(:,2)==codes(ncond+zz)),1)';
            for cont=1:length(event(zz).times_on)
                [tmp,peaks_pos_on] = min(abs(event(zz).times_on(cont)-time_ica));
                event(zz).peaks_pos_on(cont) = peaks_pos_on;
            end
            for cont=1:length(event(zz).times_off)
                [tmp,peaks_pos_off] = min(abs(event(zz).times_off(cont)-time_ica));
                event(zz).peaks_pos_off(cont) = peaks_pos_off;
            end
        end
    end
end

%----> Set dir path for ICA

dir2=strcat(path_data,'/',nome_file,'_sig/');
vdir=pwd;
if not(isfolder(dir2))
    cd(d);
    mkdir(dir2);
end
cd(vdir);


% ----------------------------------------------
% ----> LOAD AND PROCESS ELECTRIC CHANNELS <----
% ----------------------------------------------

tch = set_channels(header,'ELEC','all');
tch=[tch tch(end)+1];  % For respiration channel
dummy = set_channels(header,'ELEC','all');

disp('loading and preprocessing ELC and AUX data...');
% if(strcmp(system_str,'PCWIN64'))
%     offset_ele = dummy(1);
%     tch = tch-offset_ele+1;
%     filename_data = strcat(path_data,f(1:end-4),'.mat');
%     load(filename_data)
% end
% if(strcmp(system_str,'PCWIN'))||(ech>10)
    ech = ech-dummy(1)+1;
% end

% --- Respiration channel is the first after electric channel
% --- If loaded, it is included

%%% N.B. Ricordarsi di aggiungere il canale agli elettrici nel
%%% trasformatore 64 bit ---- 

if strcmp(res_chan,'Yes')
    ech = [ech length(tch)];
end
tch = tch(ech);

for cont=1:length(tch)
    i = tch(cont);
%     if(strcmp(system_str,'PCWIN'))
        sig = lcreaddata(i,0,leng,filename);
%     elseif(strcmp(system_str,'PCWIN64'))
%         sig = ele_data(i,:);
%     end
    for z = 1:length(freq_notch)
        sig = filter_notch(sig,freq_notch(z),Fs);
    end
    sig = lh_filtering(sig, h_filtering, l_filtering, Fs);
    
    disp([ num2str(cont) ' / ' num2str(length(tch))]);
    if std(sig) > 0
        sig=(sig-mean(sig))/std(sig);
    end
    
    sig = decimate(sig,dec);
    elec(cont,:) = sig;
  
end
clear sig;

dleng = length(elec);
elec = elec(:,time_flag(1:block));
nelec = length(ech);

nfigs = length(tch);
if strcmp(res_chan,'Yes')
    nfigs = length(tch)-1;
end
figure;
for i = 1:nfigs
    subplot(ceil(nfigs/2),2,i); plot(time_ica,elec(i,:)); axis tight;
    ylabel(['ELC ' num2str(i-1)]); xlabel('seconds');
end
close;

% ---> Save electric channels
for cont = 1:nelec
    icy = elec(cont,:);
    save(strcat(dir2, nome_file,'_ch',num2str(tch(cont)),'_elec.mat'),'icy');
end
clear icy;

% ---> Time course of power of electric channels

step=20;    % in ms 
window=400;    % in ms
step2=round(Fsnew*step/1000);     % in points
window2=round(Fsnew*window/1000);      % in points

nwin=fix((block-window2)/step2);
pelec=zeros(nelec,nwin);

for cont=1:nelec
    sigt=elec(cont,:).^2;
    for k=1:nwin
        pelec(cont,k) = mean(sigt((k-1)*step2+1:(k-1)*step2+window2));
    end
end
clear sigt;

% ---> Power Spectral Estimation of electric channels

win=1024*ceil(4/(dec+1));
spectral_estimator = spectrum.welch('Hamming',win,0);
for cont = 1:nelec
    Power_Spectrum_ele = psd(spectral_estimator,elec(cont,:),'NFFT',win,'Fs',Fsnew);
    selec(cont,:) = sqrt((Fsnew/win)*Power_Spectrum_ele.Data)';
end

% ----------------------------------------------
% ----> LOAD AND PROCESS MAGNETIC CHANNELS <----
% ----------------------------------------------

sigs=zeros(nch,dleng);

disp('loading and preprocessing MAG data...');
for cont=1:nch
    i=gch(cont);
%     if(strcmp(system_str,'PCWIN'))
        sig =(lcreaddata(i,0,leng,filename));
%     elseif(strcmp(system_str,'PCWIN64'))
%         sig = data(i,:);
%     end
    for z=1:length(freq_notch)
        sig = filter_notch(sig,freq_notch(z),Fs);
    end
    sig = lh_filtering(sig, h_filtering, l_filtering, Fs);
    
    disp([ num2str(cont) ' / ' num2str(nch)]);
    sig = decimate(sig,dec);
    sigs(cont,:) = sig;
dbquiend
sigs = sigs(:,time_flag(1:block));

clear sig data ele_data;

% --------------------------
% --------------------------
% ----> PERFORMING ICA <----
% --------------------------

disp('performing ICA...');
[nch,len]=size(sigs);

tic;

approach = 'defl';
ica_nonlinearity = 'tanh';
for j=1:ica_iter
    clear A W IC pIC good_ic mspettro G G2 G3 H H2 H3 K K2 K3R R2 R3 ave T  T1 T2 ave_on ave_off clas potenza order spec_on spec_off
    
    pack;
    randn('state',j);
    % max_num_IC deve essere pari al numero di canali
    mat_iniz = randn(nch,nch);
    
    [IC, A, W] = fastica(sigs,'approach',approach,'numOfIC',nch,'g',ica_nonlinearity,'verbose','on','displayMode','off','maxNumIterations',maxNumIter,'initGuess',mat_iniz);
    
    [chan, Nc]=size(A);
    [Nc,len]=size(IC);
    
    if Nc > 0
        
        for i=1:Nc
            potenza(i) = mean(A(:,i).^2);
        end
        
        [potenza,order]=sort(potenza);
        potenza=fliplr(potenza);
        order=fliplr(order);
        A=A(:,order);
        W=W(order,:);
        IC=IC(order,:);
    end
    
    
    iteration(j).mixing=A;
    iteration(j).unmixing=W;
    
    %---------------------------------------------------------------
    %------> EVOKED RESPONSE/BAND POWER MODULATION EVALUATION <-----
    %---------------------------------------------------------------
    
    switch study
        
        case 1
            
            T = [];
            for ind = 1:ncond
                for ix=1:Nc
                    
                    %----> Evoked response and its variance
                    ave(ind).mat(ix,:) = average(IC(ix,:),event(ind).peaks_pos,round(event(ind).t_pre*Fsnew/1000),round(event(ind).t_post*Fsnew/1000),...
                        round(event(ind).t_baseline_on*Fsnew/1000),round(event(ind).t_baseline_off*Fsnew/1000));
                    T(ind,ix) = var(squeeze(ave(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end)));
                end
            end
            
        case 2
            
            T1 = [];
            T2 = [];
            for ind = 1:ncond
                for ix = 1:Nc
                    
                    %----> ERD/ERS and t-value
                    [X,Fx,decx] = calculate_spec(IC(ix,:),Fsnew,l_filtering);
                    
                    mx_on = (resample((average_erd_ers(X,round(event(ind).peaks_pos_on/decx),round(event(ind).t_pre*Fsnew/(decx*1000)),round(event(ind).t_post*Fsnew/(decx*1000)),...
                        round(event(ind).t_baseline_on*Fsnew/(decx*1000)),round(event(ind).t_baseline_off*Fsnew/(decx*1000))))',decx,1))';
                    mx_off = (resample((average_erd_ers(X,round(event(ind).peaks_pos_off/decx),round(event(ind).t_pre*Fsnew/(decx*1000)),round(event(ind).t_post*Fsnew/(decx*1000)),...
                        round(event(ind).t_baseline_on*Fsnew/(decx*1000)),round(event(ind).t_baseline_off*Fsnew/(decx*1000))))',decx,1))';
                    nfc = size(mx_on,1);
                    ntc = size(mx_on,2);
%                     if ind == 1 & ix == 1
%                         spec_on = zeros(ncond,Nc,nfc,ntc);
%                         spec_off = zeros(ncond,Nc,nfc,ntc);
%                         ave_on = zeros(ncond,Nc,ntc);
%                         ave_off = zeros(ncond,Nc,ntc);
%                     end
                    spec_on(ind).mat(ix,:,:) = mx_on;
                    spec_off(ind).mat(ix,:,:) = mx_off;
                    
                    ave_on(ind).mat(ix,:) = mean(squeeze(spec_on(ind).mat(ix,find(Fx > low_freq & Fx < up_freq),:)));
                    ave_off(ind).mat(ix,:) = mean(squeeze(spec_off(ind).mat(ix,find(Fx > low_freq & Fx < up_freq),:)));
                    
                    [h,p,ci,stats] = ttest2(ave_on(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end),ave_on(ind).mat(ix,1:-round(event(ind).t_pre*Fsnew/1000))); T1(ind,ix)=(stats.tstat)/sqrt(length(event(ind).times_on));
                    [h,p,ci,stats] = ttest2(ave_off(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end),ave_off(ind).mat(ix,1:-round(event(ind).t_pre*Fsnew/1000))); T2(ind,ix)=(stats.tstat)/sqrt(length(event(ind).times_off));
                end
            end
            clear X;
            
        case 3
            
            T1 = [];
            T = [];
            for ind = 1:ncond
                
                for ix = 1:Nc
                    
                    %----> ERD/ERS and t-value
                    [X,Fx,decx] = calculate_spec(IC(ix,:),Fsnew,l_filtering);
                    mx_on = (resample((average_erd_ers(X,round(event(ind).peaks_pos/decx),round(event(ind).t_pre*Fsnew/(decx*1000)),round(event(ind).t_post*Fsnew/(decx*1000)),...
                        round(event(ind).t_baseline_on*Fsnew/(decx*1000)),round(event(ind).t_baseline_off*Fsnew/(decx*1000))))',decx,1))';
                    nfc = size(mx_on,1); ntc=size(mx_on,2);
%                     if ind == 1 & ix == 1
%                         spec_on = zeros(ncond,Nc,nfc,ntc);
%                         ave_on = zeros(ncond,Nc,ntc);
%                     end
                    spec_on(ind).mat(ix,:,:) = mx_on;
                    ave_on(ind).mat(ix,:) = mean(squeeze(spec_on(ind).mat(ix,find(Fx > low_freq & Fx < up_freq),:)));
                    [h,p,ci,stats] = ttest2(ave_on(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end),ave_on(ind).mat(ix,1:-round(event(ind).t_pre*Fsnew/1000)));
                    T1(ind,ix) = (stats.tstat)/sqrt(length(event(ind).times));
                    
                    %----> Evoked response and its variance
                    ave(ind).mat(ix,:) = average(IC(ix,:),event(ind).peaks_pos,round(event(ind).t_pre*Fsnew/1000),round(event(ind).t_post*Fsnew/1000),...
                        round(event(ind).t_baseline_on*Fsnew/1000),round(event(ind).t_baseline_off*Fsnew/1000));
                    T(ind,ix) = var(squeeze(ave(ind).mat(ix,-round(event(ind).t_pre*Fsnew/1000)+1:end)));
                    
                end
            end
            clear X;
            
    end
    
    %-----------------------------------------------
    %------ POWER SPECTRAL DENSITY ESTIMATION  -----
    %-----------------------------------------------
    
    win=1024*ceil(4/(dec+1));
    for ix=1:Nc
        spectral_estimator = spectrum.welch('Hamming',win,0);
        Power_Spectrum = psd(spectral_estimator,IC(ix,:),'NFFT',win,'Fs',Fsnew);
        mspettro(ix,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
        F = Power_Spectrum.Frequencies;
    end
    
    %--------------------------------
    %----> IC POWER TIME COURSE <----
    %--------------------------------
    
    pIC = zeros(size(A,2),nwin);
    for cont = 1:size(A,2)
        sigt = IC(cont,:).^2;
        for k = 1:nwin
            pIC(cont,k) = mean(sigt((k-1)*step2+1:(k-1)*step2+window2));
        end
    end
    clear sigt;
    
    %--------------------------------
    %--------------------------------
    %----> PLOT AND SAVE IMAGES <----
    %--------------------------------
    
    lat=ceil(sqrt(Nc));
    
    %--------------------------------------
    %----> Evoked Responses - ERD/ERS <----
    %--------------------------------------
    
    switch study
        
        case 1
            for ind = 1:ncond
                figure;
                for ix = 1:Nc
                    subplot(lat,lat,ix), plot([round(event(ind).t_pre*Fsnew/1000):round(event(ind).t_post*Fsnew/1000)]*(1/Fsnew),...
                        squeeze(ave(ind).mat(ix,:))); ylabel(['IC ' num2str(ix)]); axis tight;
                    if ix == ceil(lat/2)
                        title([event(ind).name ' : ERF'],'FontSize',14);
                    end
                end
                print(strcat(dir2, nome_file, '_nonlinearity_', ica_nonlinearity, '_iteration_', num2str(j), '_', event(ind).name, '_erf.tif'),'-dtiff','-r100');
                close;
            end
            
        case 2
            for ind=1:ncond
                figure;
                for ix=1:Nc
                    mat = squeeze(ave_on(ind).mat(ix,:));
                    subplot(lat,lat,ix)
                    plot(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,size(mat,2)),mat);
                    ylabel(['IC ' num2str(ix)]);
                    axis([event(ind).t_baseline_on/1000 event(ind).t_post/1000-0.1 min(mat)-0.1*(max(mat)-min(mat)) max(mat)+0.1*(max(mat)-min(mat))]);
                    if ix==ceil(lat/2)
                        title([event(ind).name ' : ERD/ERS signal'],'FontSize',14);
                    end
                end
                print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_' event(ind).name '_onset.tif'],'-dtiff','-r100');
                close;
                figure;
                for ix=1:Nc
                    mat = squeeze(ave_off(ind).mat(ix,:));
                    subplot(lat,lat,ix)
                    plot(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,size(mat,2)),mat);
                    plot([event(ind).t_pre/1000:(event(ind).t_post/1000-event(ind).t_pre/1000)/(size(mat,1)-1):event(ind).t_post/1000],mat);
                    axis([event(ind).t_baseline_on/1000 event(ind).t_post/1000-0.1 min(mat)-0.1*(max(mat)-min(mat)) max(mat)+0.1*(max(mat)-min(mat))]);
                    ylabel(['IC ' num2str(ix)]); 
                    if ix==ceil(lat/2)
                        title([event(ind).name ' : ERD/ERS signal'],'FontSize',14);
                    end
                end
                print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_' event(ind).name '_offset.tif'],'-dtiff','-r100');
                close;
            end
            clear mat;
            
        case 3
            for ind = 1:ncond
                figure;
                for ix=1:Nc
                    mat = squeeze(ave_on(ind).mat(ix,:));
                    subplot(lat,lat,ix);
                    plot(linspace(event(ind).t_pre/1000,event(ind).t_post/1000,size(mat,2)),mat);
                    ylabel(['IC ' num2str(ix)]);
                    axis([event(ind).t_baseline_on/1000 event(ind).t_post/1000-0.1 min(mat)-0.1*(max(mat)-min(mat)) max(mat)+0.1*(max(mat)-min(mat))]);
                    if ix==ceil(lat/2)
                        title([event(ind).name ' : ERD or ERS signal'],'FontSize',14);
                    end
                end
                print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_' event(ind).name '_onset.tif'],'-dtiff','-r100');
                close;
            end
            clear mat;
            
            for ind = 1:ncond
                figure;
                for ix=1:Nc
                    subplot(lat,lat,ix)
                    plot([round(event(ind).t_pre*Fsnew/1000):round(event(ind).t_post*Fsnew/1000)]*(1/Fsnew),squeeze(ave(ind).mat(ix,:)));
                    ylabel(['IC ' num2str(ix)]); axis tight;
                    if ix==ceil(lat/2)
                        title([event(ind).name ' : ERF'],'FontSize',14);
                    end
                end
                print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_' event(ind).name '_erf.tif'],'-dtiff','-r100');
                close;
            end
            
    end
    
    %--------------------------
    %----> IC time course <----
    %--------------------------
    
    figure;
    for ix=1:Nc
        sig = IC(ix,:);
        base = time_ica;
        subplot(ceil(Nc/2),2,ix),plot(base,sig);
        axis([base(1) base(end) min(sig)-0.1*(max(sig)-min(sig)) max(sig)+0.1*(max(sig)-min(sig))]);
        ylabel(['IC ' num2str(ix)]);
        if ix==1
            title('IC timecourses','FontSize',14);
        end
    end
    clear sig;
    print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_time.tif'],'-dtiff','-r100');
    close;
    
    %----------------------------------
    %----> Power Spectral Density <----
    %----------------------------------
    
    figure;
    for ix=1:Nc
        Prms = mspettro(ix,:);
        subplot(ceil(Nc/2),2,ix),plot(F,Prms,'r');
        lags = find(F>h_filtering & F<min(100,l_filtering));
        max_val = max(Prms(lags))+0.1*(max(Prms(lags))-min(Prms(lags)));
        axis([h_filtering min(100,l_filtering) 0 max_val]);
        ylabel(['IC ' num2str(ix)]);
        if ix==1
            title('IC power spectra','FontSize',14);
        end
    end
    print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_freq.tif'],'-dtiff','-r100');
    close;
    
    %-----------------------------------------------------
    %----> Topological maps of mixing matrix columns <----
    %-----------------------------------------------------
    
    figure;
    for ix=1:Nc
        subplot(lat,lat,ix), showfield(A(:,ix),pos_channels);
        xlabel(['IC ' num2str(ix)],'color','k'); colormap(Cx_map);
        if ix==ceil(lat/2)
            title('IC sensor maps','FontSize',14);
        end
    end
    print([dir2 nome_file '_nonlinearity_' ica_nonlinearity '_iteration_' num2str(j) '_maps.tif'],'-dtiff','-r100');
    close;
    
    
    %-------------------------------------
    %-------------------------------------
    %--------> IC CLASSIFICATION <--------
    %-------------------------------------
    
    if Nc==0
        good_ic=[]; art_con=1; G=[]; G2=[]; G3=[];
        H=[]; H2=[]; H3=[]; clas=[];
    else
        
        %-------------------------------------------------------
        %---> Correlation between ICs and electric channels <---
        %-------------------------------------------------------
        
        if nelec > 0
            
            %---> Correlation between the ICs and electric channels
            R = corrcoef([elec',IC']);
            K = R(nelec+1:nelec+size(A,2),1:nelec);
            H = max(abs(K'),[],1);
            
            %---> Correlation between the ICs' and electric channels' power in window of 400 ms duration (step = 20 ms)
            R2 = corrcoef([pelec',pIC']);
            K2 = R2(nelec+1:nelec+size(A,2),1:nelec);
            H2 = max(abs(K2'),[],1);
            
            %---> Correlation between ICs' electric channels'power spectra between 3 and 40 Hz
            vspec = find(F > 3 & F < 40);
            R3 = corrcoef([selec(:,vspec)',mspettro(:,vspec)']);
            K3 = R3(nelec+1:nelec+size(A,2),1:nelec);
            H3 = max(abs(K3'),[],1);
        else
            H = zeros(1,size(A,2)); H2=zeros(1,size(A,2)); H3=zeros(1,size(A,2));
        end
        
        %------------------------------------------------------------------
        %---> Fit with 1/f spectrum, flat spectrum "quantification", IC time kurtosis
        %------------------------------------------------------------------
        
        g = fittype({'1/x','1'});
        frq = [1 13];
        frq2 = [2 78];
        vec = find(F > frq(1) & F < frq(2));
        vec2 = find(F > frq2(1) & F < frq2(2));
        for ix = 1:Nc
            sspettro = mspettro(ix,:);
            [fitx,goodness] = fit(F(vec),sspettro(vec)',g);
            G(ix) = goodness.rsquare;
            ss = sspettro(vec2);
            G2(ix)= prctile(ss,95)/(median(ss));
            G3(ix)= kurtosis(IC(ix,:));
        end
        
        %---> Set thresholds for ICs' classification
        thres_a = 0.10; thres_b = 0.25; thres_c = 0.95;
        thres_d = 0.5;  thres_e = 2;    thres_f = 15;
        thres_g = 0.1;  thres_h = 15;
        
        %----------------------------------------------------------
        %---> classification : 0 = artifact   1 = brain signal <---
        %----------------------------------------------------------
        
        clas = zeros(1,Nc);
        
        clas(find(G2 > thres_e & G3 < thres_f & H3 < thres_c)) = 1; %---> Spectrum_flat - Time_kurtosis - Elc_spectrum_correlation
        
        switch study
            case 1
                for ind = 1:ncond
                    clas(find(T(ind,:) > thres_g)) = 1;             %---> High variance in post-trigger period (with respect to pre???)
                end
            case 2
                for ind = 1:ncond
                    clas(find(abs(T1(ind,:)) > thres_h | abs(T2(ind,:)) > thres_h)) = 1;   %---> High band-power difference in post with respect to pre period
                end
                
            case 3
                for ind = 1:ncond
                    clas(find(abs(T1(ind,:)) > thres_h)) = 1;    %---> High band-power difference in post with respect to pre period
                end
        end
        
        clas(find(G > thres_d | H > thres_a | H2 > thres_b)) = 0;   %---> Spectrum_one_over_f - Elc_signal_correlation - Elc_power_correlation
        
        good_ic = find(clas==1);
        
        if nelec > 0
            art_con = mean(H2(good_ic));
        else
            art_con = 0;
        end
        
    end
    
    %----------------------------------
    %----------------------------------
    %----> SAVE ITERATION RESULTS <----
    %----------------------------------
    
    iteration(j).total_ic_number=size(A,2);
    iteration(j).brain_ic_number=length(good_ic);
    iteration(j).brain_ic=good_ic;
    iteration(j).artifact_contamination=art_con;
    iteration(j).elc_signal_correlation=H;
    iteration(j).elc_power_correlation=H2;
    iteration(j).elc_spectrum_correlation=H3;
    iteration(j).spectrum_one_over_f=G;
    iteration(j).spectrum_flat=G2;
    iteration(j).time_kurtosis=G3;
    
    switch study
        case 1
            iteration(j).erf_variance=T;
        case 2
            iteration(j).tscore_onset=T1;
            iteration(j).tscore_offset=T2;
        case 3
            iteration(j).tscore_onset=T1;
            iteration(j).erf_variance=T;
            
    end
    
    goodness_ic(j,1) = length(good_ic);
    goodness_ic(j,2) = 1-art_con;
    
    disp(['nonlinearity ' ica_nonlinearity ' - run ' num2str(j) ' / ' num2str(ica_iter)]);
    disp(['total number of ICs : ' num2str(size(A,2)) ' -  number of brain ICs : '  num2str(length(good_ic)) ' -  artifact contamination : ' num2str(art_con)]);
    
    %---------------------------------
    %---> Elapsed time estimation <---
    %---------------------------------
    
    tt=toc;
    tt_elap=ceil(tt/60);         %--> time elapsed in minutes
    run_totali=length(ica_nonlinearity)*ica_iter;
    run_elaborati=j;
    run_da_elaborare=run_totali-run_elaborati;
    tt_left=ceil(tt_elap*run_da_elaborare/run_elaborati);       %--> time left in minutes
    if run_da_elaborare > 0
        if tt_left < 60
            disp(['time left ' num2str(tt_left) ' minutes']);
        else
            disp(['time left ' num2str(0.1*round(10*tt_left/60)) ' hours']);
        end
    else
        disp(['ICA processing completed!']);
    end
%     save(tmp_name);
end

ICA.iteration = iteration;

clear A W IC pIC good_ic mspettro G G2 G3 H H2 H3 K K2 K3 R R2 R3 ave ave_on ave_off T T1 T2 clas  spec_on spec_off;

%-------------------------------
%-------------------------------
%----> SAVE GLOBAL RESULTS <----
%-------------------------------

[tmp,pos_new] = max(goodness_ic(:,1).*goodness_ic(:,2));

A = ICA.iteration(pos_new).mixing;
W = ICA.iteration(pos_new).unmixing;
good_ic = ICA.iteration(pos_new).brain_ic;
disp(['non-linearity used: ' ica_nonlinearity ' - run number ' num2str(mod(pos_new-1,ica_iter)+1)]);

IC = W*sigs; %--> Compute Ic set for the best trial
ICA.best_iter.index = pos_new;
ICA.best_iter.IC = IC;
ICA.best_iter.nonlinearity = ica_nonlinearity;
ICA.iteration(pos_new).brain_ic_number = length(good_ic);
ICA.iteration(pos_new).brain_ic = good_ic;

ica_par.non_linearity = ica_nonlinearity;
ica_par.approach = approach;
ica_par.iteration_no = ica_iter;
ica_par.dec_fact = dec;
ica_par.filter.freq_notch = freq_notch;
ica_par.filter.freq_high = l_filtering;
ica_par.filter.freq_low = h_filtering;
ica_par.intervals.skipped_intervals = skipped_intervals;
ica_par.intervals.offset = offset;
ica_par.IC_npt = block;
ica_par.time_ica = time_ica;

fx = [nome_file '_meg.mat'];
path_file = strcat(path_data,'/',fx);

save(path_file,...
    'ica_par',...%--> struct with IC decomposition parameters
    'ICA',...%--> struct with results of IC decomposition for each iteration
    'event',...%--> struct with analysis type and conditions 
    'header'); %--> original mhd 

delete('tmp_name')

