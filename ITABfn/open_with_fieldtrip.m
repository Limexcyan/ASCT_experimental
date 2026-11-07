

filename = '/mnt/devv/SourceConn/Exp/ITAB-sim2/0_raw/mrtlne88_0101.raw';

cfg = [];
cfg.dataset = filename;
cfg.trialdef.eventtype      = 'trigger';
cfg.trialdef.eventvalue     = {31,33,35, 41, 43, 45}; %3 sek 
%cfg.trialdef.eventvalue     = {11,13,15, 21, 23, 25}

cfg.trialdef.prestim        = 0.3;
cfg.trialdef.poststim       = 3;
cfg = ft_definetrial(cfg);     

cfg = ft_rejectartifact(cfg);

hdr = ft_read_header(filename);
bad_channel = find([hdr.orig.ch.flag]==1);
good_channel = setdiff(find([hdr.orig.ch.type]==2),bad_channel);
cfg.channel = [hdr.label(good_channel)];
cfg.continuous         = 'yes';
data = ft_preprocessing(cfg);

%to generate topoplot
cfg=[];
cfg.grad = grad_150;
lay=ft_prepare_layout(cfg);


%AL
% for ic = 1: 16
%     figure;
%     plot(ICA.best_iter.IC(ic,1000:2000));
% end