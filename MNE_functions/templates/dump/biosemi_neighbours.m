
%DEFNING NEIGHBOURS - original code
        cfg = [];
        cfg.method = 'template';
        cfg.template = '_biosemi64_neighb.mat';  % cfg.elec          = structure with electrode positions or filename, see FT_READ_SENS or    cfg.layout        = filename of the layout, see FT_PREPARE_LAYOUT to be put in the future
        neighbours = ft_prepare_neighbours(cfg, data_all_interp(ds) ) ;
        
%DEFNING NEIGHBOURS - from layout
        cfg = [];
        cfg.method = 'triangulation';
        cfg.layout  = '_biosemi64+4+2.sfp';
        neighbours = ft_prepare_neighbours(cfg, data_all_interp(ds) ) ;