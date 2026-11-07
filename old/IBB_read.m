applyICA = 1;

chdir('/mnt/devv/SourceConn/Exp/MarkusData/Andreas_IAPS/');

% dsName = 'A0938_tDCS-IAPS_20140204_02.ds';
dsName = '/mnt/devv/SourceConn/Exp/MarkusData/Andreas_IAPS/data_raw/A0286_tDCS-IAPS_20140221_01.ds';

printOutFile = 'Results.ps';
if exist(printOutFile, 'file'), delete(printOutFile); end

hdr = ft_read_header(dsName);
%             evt = ft_read_event(dsName);

megInd = find(strcmp(hdr.chantype, 'meggrad')); meglabel = hdr.label(megInd);
chanUsed = meglabel;

% preprocessing of raw data
cfg = [];
cfg.dataset     = dsName;
cfg.channel = {'MEG' 'MEGREF'};
cfg.continuous  = 'yes';
rawData        = ft_preprocessing(cfg);

% define noise balancing (synthetic gradiometer order)
cfg = [];
cfg.gradient = 'G3BR';
rawData = ft_denoise_synthetic(cfg, rawData);

%% use only MEG channels
cfg = [];
cfg.channel = meglabel;

rawData = ft_preprocessing(cfg, rawData);

%% split in event related epochs
cfg = [];
cfg.dataset = dsName;
%     cfg.channel = channelOI;

cfg.trialdef.prestim        = 0.3;
cfg.trialdef.poststim       = 0.5; %0.5

% cfg.trialdef.eventtype = 'pos';
cfg.trialdef.eventtype = 'neg';

cfg.trialfun = 'ft_trialfun_general';

cfg = ft_definetrial(cfg);

trlOrg = cfg.trl;

cfg = [];
cfg.dataset = dsName;
%     cfg.channel = channelOI;
cfg.channel = chanUsed;
cfg.trl = trlOrg;

epochData = ft_redefinetrial(cfg, rawData);

%% ICA
if applyICA
    cfg        = [];
    cfg.method = 'runica'; % this is the default and uses the implementation from EEGLAB
    cfg.runica.pca = 30;
    comp = ft_componentanalysis(cfg, epochData);

    cfg = [];
    cfg.layout = 'CTF275_helmet.mat'; % specify the layout file that should be used for plotting
    cfg.viewmode = 'component';
    ft_databrowser(cfg, comp);
    browserFig = gcf;    

    % define components to be rejected
%     pause

    x = inputdlg('Enter space-separated numbers:', 'Components to reject', [1 50]);
    compDel = str2num(x{:});

    set(browserFig, 'PaperOrientation', 'landscape');
    set(browserFig, 'PaperType', 'a4');

    print(browserFig, printOutFile, '-dpsc', '-fillpage', '-append');

    %                 close(topoFig);
    close(browserFig);

    %remove artifact components
    cfg = [];
    % cfg.component = [9 10 14 24]; % to be removed component(s); this could be added to the subject_script
    cfg.component = compDel; % to be removed component(s); this could be added to the subject_script
    chopData = ft_rejectcomponent(cfg, comp, epochData);

    clearvars comp
end % end ICA

%% mw

cfg=[];
cfg.layout = 'CTF275_helmet.mat';
cfg.component = 1;
ft_topoplotIC(cfg, compa);




%% average epochs
cfg = [];
cfg.channel = meglabel;
avgData  = ft_timelockanalysis(cfg, epochData);

% perform some further processing on the averaged data
cfg = [];
cfg.continuous = 'no';
% if LPfreqAvg > 0,
%     cfg.lpfilter = 'yes';
%     cfg.LPfreq = LPfreqAvg;
%     fprintf(1, '\nlow pass filter of %f Hz will be applied\n', LPfreqAvg);
% end

cfg.demean = 'yes';
cfg.baselinewindow = [-0.275 -0.025];

avgData = ft_preprocessing(cfg, avgData);

%% determine GMF and GMF maxima
cfg = [];
cfg.channel = meglabel;
cfg.method = 'amplitude';
cfg.latency = [0.1 0.2];
[gmfMaxLat, ~, gmf] =  aw_ft_determineGMFmaximum(cfg, avgData);

%% visualize averaged data
figure;
plot(avgData.time, avgData.avg);
xlabel('lateny [s]');
ylabel('B [T]');
title({'Event related average'; 'condition neg'});

set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperType', 'a4');

print(gcf, printOutFile, '-dpsc', '-fillpage', '-append');

%% make a topographic plot of the ERF
cfg = [];
% cfg.xlim = [gmfMaxLat-0.005 gmfMaxLat];

cfg.comment = 'xlim';
cfg.commentpos = 'title';
cfg.showxlim = 'no';
cfg.showzlim = 'no';
cfg.interactive = 'yes';
cfg.colorbar = 'EastOutside';

cfg.layout = 'CTF275_helmet.mat';
% cfg.layout = 'CTF275.lay';

ft_topoplotER(cfg, avgData);

set(gcf, 'PaperOrientation', 'landscape');
set(gcf, 'PaperType', 'a4');

print(gcf, printOutFile, '-dpsc', '-fillpage', '-append');