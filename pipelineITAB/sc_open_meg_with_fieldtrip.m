
% filename = '/mnt/iSCSI1/Users/adaml/Devv/SourceConn/Exp/Sara/ccrmhl93_0209';
% 
% cfg = [];
% cfg.dataset = infile{1};
% cfg.trialdef.eventtype      = 'trigger';
% cfg.trialdef.eventvalue     = {31,33,35, 41, 43, 45}; %3 sek 
% %cfg.trialdef.eventvalue     = {11,13,15, 21, 23, 25}
% 
% cfg.trialdef.prestim        = 0.3;
% cfg.trialdef.poststim       = 3;
% cfg = ft_definetrial(cfg);     
% 
% cfg = ft_rejectartifact(cfg);
cfg = [];
cfg.dataset = infile{1};
hdr = ft_read_header(infile{1});
bad_channel = find([hdr.orig.ch.flag]==1);
good_channel = setdiff(find([hdr.orig.ch.type]==2),bad_channel);
cfg.channel = [hdr.label(good_channel)];
cfg.continuous         = 'yes';
data = ft_preprocessing(cfg);

cfg             = [];
    cfg.hpfilter    = 'yes';     % enables high-pass filtering
    cfg.hpfilttype  = filter.HPtype;
    cfg.HPfreq      = filter.HPfreq;       % sets up the frequency for high-pass filter
    cfg.hpfiltord   = filter.HPord;
        
    cfg.lpfilter    = 'yes';     % enables low-pass filtering
    cfg.lpfilttype  = filter.LPtype;
    cfg.LPfreq      = filter.LPfreq;        % sets up the frequency for low-pass filter
    cfg.lpfiltord   = filter.LPord;
    
    cfg.plotfiltresp  = 'yes';
      
    data_all_prep(ds)  = ft_preprocessing(cfg, data); 

%to generate topoplot
% cfg=[];
% cfg.grad = grad_150;
% lay=ft_prepare_layout(cfg);


%AL
% for ic = 1: 16
%     figure;
%     plot(ICA.best_iter.IC(ic,1000:2000));
% end
