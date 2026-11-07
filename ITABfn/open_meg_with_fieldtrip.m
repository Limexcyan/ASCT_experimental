data_path = '/home/devv/SourceConn/Exp/Sara/data/';

d = dir(data_path);
isub = [d(:).isdir];
names_all = {d(isub).name}';
names_all = names_all(3:end-3);
for i = 1:length(names_all)
    ds_all(i) = fullfile(data_path,names_all(i),strcat(names_all(i) ,'.raw'));
end


for i = 1:length(names_all)
    current_name = names_all(i);
    infile =  ds_all(i); %'/home/devv/SourceConn/Exp/Sara/data/mrogne94_0201/mrogne94_0201.raw';
    % 
    % infile = 'mrtlne88_0101.raw';



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
    cfg.dataset = infile;
    hdr = ft_read_header(infile);
    bad_channel = find([hdr.orig{1}.orig.ch.flag]==1);
    good_channel = setdiff(find([hdr.orig{1}.orig.ch.type]==2), bad_channel);
    cfg.channel = [hdr.label(good_channel)];
    cfg.continuous         = 'yes';
    data = ft_preprocessing(cfg);

    cfg             = [];
    cfg.hpfilter    = 'yes';     % enables high-pass filtering
%     cfg.hpfilttype  = filter.HPtype;
    cfg.HPfreq      = 1;       % sets up the frequency for high-pass filter
%     cfg.hpfiltord   = filter.HPord;
        
    cfg.lpfilter    = 'yes';     % enables low-pass filtering
%     cfg.lpfilttype  = filter.LPtype;
    cfg.LPfreq      = 50;        % sets up the frequency for low-pass filter
%     cfg.lpfiltord   = filter.LPord;
    
    cfg.plotfiltresp  = 'yes';
      
    data_meg  = ft_preprocessing(cfg, data); 

    % to generate topoplot
    % cfg=[];
    % cfg.grad = grad_153;
    % lay=ft_prepare_layout(cfg);
    % 
    % cfg          = [];
    % cfg.method   = 'summary';
    % cfg.alim     = 1e-12;
    % dummy        = ft_rejectvisual(cfg,data_meg);
    % 
    % var_g = [];
    % 
    % for g = 1 : size(data_meg.trial{1,1},1)
    %     var_g(g) = var( data_meg.trial{1,1}(g,:) );
    % end
    % 
    % s_g =[];
    % s_g = std(var_g);
    % 
    % z_var = [];
    % for g = 1 : size(data_meg.trial{1,1},1)
    %     z_var(g) = var_g(g)/s6 15 14 13 12 11 10_g;
    % end


    % cfg = [];
    % cfg.layout = lay;
    % % layout = ft_prepare_layout(cfg);
    % 
    % figure
    % ft_plot_layout(lay);
    % 
    % 
    % 
    % 
    % cfg = [];
    % ft_layoutplot([], lay);
    %AL
    % for ic = 1: 16
    %     figure;
    %     plot(ICA.best_iter.IC(ic,1000:2000));
    % end
    data_prep = data_meg;
    data_prep.hdr.dsname = current_name{1};
    save_folder = strcat('/mnt/iSCSI3/Users/michald/Dev/SourceConn/Exp/Sara/Analysis_MD/1_PREPROCESSED/',current_name,'_PREP.mat');
    save(save_folder{1},'data_prep')
end