% loc.ROI(1).pos = [-2 -57 42];  % mostly for oscil analysis
% loc.ROI(1).name = 'LPrec';
% loc.ROI(2).pos = [3 -64 35];  
% loc.ROI(2).name = 'RPrec';
% loc.ROI(3).pos = [-28 -6 50];    
% loc.ROI(3).name = 'LVis'; 
% loc.ROI(4).pos = [-11 -81 7];    
% loc.ROI(4).name = 'RVis'; 
% loc.ROI(5).pos = [11 -78 9];  
% loc.ROI(5).name = 'L.IPS';  % mostly for conn analysis
% loc.ROI(6).pos = [-38 -78 36];  
% loc.ROI(6).name = 'R.IPS'; 
% loc.ROI(7).pos = [36 -80 26];  
% loc.ROI(7).name = 'dACC'; 
% loc.ROI(8).pos = [-1 10 46];  
% loc.ROI(8).name = 'LaIfO'; 
% loc.ROI(9).pos = [-35 14 5];  
% loc.ROI(9).name = 'RaIfO'; 
% loc.ROI(10).pos = [36 16 4];  
% loc.ROI(10).name = 'R.VFC'; 

% loc.ROI(1).name = 'LVis'; 
% loc.ROI(1).pos = [-11 -81 7];    
% 
% loc.ROI(2).name = 'RVis'; 
% loc.ROI(2).pos = [11 -78 9];    
% 
% loc.ROI(3).name = 'LIPS';  % mostly for conn analysis
% loc.ROI(3).pos = [-38 -48 44];  
% 
% loc.ROI(4).name = 'RIPS'; 
% loc.ROI(4).pos = [32 -52 50];  
% 
% loc.ROI(5).name = 'dACC'; 
% loc.ROI(5).pos = [-1 -10 46];  
% 
% loc.ROI(6).name = 'LaIfO';
% loc.ROI(6).pos = [-35 14 5];   %mostly error monit but also sustained, part of the sustained task network with opercular (Dosenbach, Neuron 2006)
% 
% loc.ROI(7).name = 'RaIfO';
% loc.ROI(7).pos = [36 16 4];  
% 
% loc.ROI(8).name = 'LDLPFC'; % task prepar and exec (no error control) MacDonald III, Cohen, Science 2000
% loc.ROI(8).pos = [-43 18 29];  
% 
% loc.ROI(9).name = 'LPrec';
% loc.ROI(9).pos = [-2 -57 42];  % mostly for oscil analysis
% 
% loc.ROI(10).name = 'RPrec';
% loc.ROI(10).pos = [3 -64 35];  

% design.COND(1).name = {'NEUNS-NEU', 'NEU-NEU', 'IMP-NEG', 'NEUNS-NEG'}; 
% design.COND(1).trig = { {101 102}, {103 104}, {105 106}, {107 108} };

clear all

% loadFolder = '/home/mirek/Sci/Exp/implicit/EEG/back/errorinvisualcoord/oscil+conn_ana1/unc/';
loadFolder = '/mnt/iSCSI2/Exp/implicit/EEG/PCAprepost/7_SOURCEACT/unc/';
infile = sc_reading(loadFolder, '*sigroi_unc.mat');

smpf = 1;    %window sample from !!!
smpt = 254;  %window sample from
ff = 10;     %freq from
ft = 13;     %freq to

roi = [1 2];

parfor  ds = 1 : length(infile)
    [~, dsname, ~] = fileparts(infile{ds});
    disp([' [' num2str( round(100*ds/length(infile) )) '%] Loading reconstruced ROI signals: ', dsname, ' - ', infile{ds}] );
    
    load_file = infile{ds};
    tmpdata = load(load_file,'data_sigroi_unc');
    data_all_roi{ds} = tmpdata.data_sigroi_unc;
end

newtrialen = smpt-smpf+1;

rr=1;          %make signals matrix for selected rois
for r = roi
    for s = 1:length(data_all_roi)
        sigIMP{s,rr} = data_all_roi{s}.IMP_NEG.signal(r,:);
        sigNEG{s,rr} = data_all_roi{s}.NEUNS_NEG.signal(r,:);
    end
    rr=rr+1;
end

    oritrialen = data_all_roi{s}.IMP_NEG.trialen;
    fs = data_all_roi{s}.IMP_NEG.sampling_rate;

for s = 1:size(sigIMP,1)
    for r = 1:size(sigIMP,2)
        epoched = reshape(sigIMP{s,r},oritrialen, [])';
        epochedcut = epoched(:,smpf:smpt);
        sigcutIMP{s,r} = reshape(epochedcut',1,[]);
        epoched = reshape(sigNEG{s,r},oritrialen, [])';
        epochedcut = epoched(:,smpf:smpt);
        sigcutNEG{s,r} = reshape(epochedcut',1,[]);
    end
end

%     notrial = length(sigcutIMP{s,1})/newtrialen;

for s = 1:size(sigIMP,1)
    
        specIMProi1(s,:) = (pwelch(sigcutIMP{s,1}, newtrialen, 0, [], fs))';
        specNEGroi1(s,:) = (pwelch(sigcutNEG{s,1}, newtrialen, 0, [], fs))';
        specIMProi2(s,:) = (pwelch(sigcutIMP{s,2}, newtrialen, 0, [], fs))';
        specNEGroi2(s,:) = (pwelch(sigcutNEG{s,2}, newtrialen, 0, [], fs))';
    
end


avspecIMProi1 = mean(specIMProi1,1);   %for plotting
avspecNEGroi1 = mean(specNEGroi1,1);
avspecIMProi2 = mean(specIMProi2,1);
avspecNEGroi2 = mean(specNEGroi2,1);


avpwIMProi1 = mean(specIMProi1(:,ff:ft),2);
avpwNEGroi1 = mean(specNEGroi1(:,ff:ft),2);
avpwIMProi2 = mean(specIMProi2(:,ff:ft),2);
avpwNEGroi2 = mean(specNEGroi2(:,ff:ft),2);

logavpwIMProi1 = log10(avpwIMProi1) ;
logavpwNEGroi1 = log10(avpwNEGroi1) ;
logavpwIMProi2 = log10(avpwIMProi2) ;
logavpwNEGroi2 = log10(avpwNEGroi2) ;


[h p] = ttest(logavpwIMProi1, logavpwNEGroi1);
disp ('ROI1');
disp (p);
disp (sum(avspecIMProi1));
disp (sum(avspecNEGroi1));
[h p] = ttest(logavpwIMProi2, logavpwNEGroi2);
disp ('ROI2');
disp (p);
disp (sum(avspecIMProi2));
disp (sum(avspecNEGroi2));
% mean(avpwIMProi2)
% mean(avpwNEGroi2)
