% This script is written to review data of different DataConfiguration.
% in order to use this function 'vis_DC_list' and 'ERP_smoothing' parameters must be provided
% ex: vis_DC_list = [1 5]; ERP_smoothing=8 (smoothing window length, set zero to disable)


if isequal(ERP_smoothing, 0)    
    disp('unsmoothed DATA plots');    
    
else
    disp('smoothed DATA plots');
    
    for d = 1:length(DATA)
        DATA_sh{1,d} = DATA{1,d};
        DATA_sh{1,d}.avg = movmean(DATA{1,d}.avg, ERP_smoothing, 2);
    end
end
    
title = [];
for DC = 1:length(vis_DC_list)
    title = [ title ' vs ' NAME{ vis_DC_list(DC) } ];
end
title = title(1, 5:end);

for DC = 1:length(vis_DC_list)
    NAME_DC_LIST{DC} = NAME{ vis_DC_list(DC) };
end

cfg = [];

if isfield(chan, 'layout_type')  % for compatibility with older analyses
    cfg.layout = chan.layout_type;
else
    load(fullfile(analysisFolder, '1_PREPROCESSED', 'layout.mat'));
     cfg.layout = layout;
end


cfg.fontsize = 12;
cfg.linewidth   = 1.5;
%cfg.xlim = [xlim_start xlim_end];
cfg.xlim = xlim;
cfg.ylim = ylim;  %for autoscaling use 'maxmin'
cfg.showlabels = 'yes'; %shows labels AF7, CPz and so on
cfg.figurename  = title;
cfg.dataname  = NAME_DC_LIST; % used when naming DC in ft_sigleplot
cfg.showlegend  = 'yes'; %uses NAME{i} to create legend with DC names.
cfg.baseline = 'no';
cfg.axes = 'yes';
cfg.interactive = 'yes'; % enables interactive selecion of given channels by useing ft_singleplot
cfg.showoutline = 'yes'; % draws outerline of the head model on multiplot
cfg.showscale = 'no'; %in order to avoid plotting an extra box with axes' limits.
cfg.showcomment = 'yes'; % yes if youw want to see axes limits and name of each DataConfiguration.
cfg.linecolor   = 'bgrkym';
if exist('colloc','var')
    if colloc; cfg.layout = 'butterfly'; end
end

if isequal(ERP_smoothing, 0)
    
    instr_plot = 'ft_multiplotER(cfg, '; %again, instruction for ft_multiplotER must be built manually

    for DC = 1:length(vis_DC_list)
        instr_plot = [ instr_plot 'DATA{1,' num2str( vis_DC_list(DC) ) '}, ' ];
    end

    instr_plot = instr_plot(1,1:end-2); %removes last coma
    instr_plot = [instr_plot ');'];
    
    fig = figure('Name', title ,'NumberTitle','on');
    eval(instr_plot); % finall call of ft_multiplotER( cfg, DATA{1,vis_DC_list(1)}, ..., DATA{1, vis_DC_list(length(vis_DC_list))} )
    set(gcf,'name', title ,'numbertitle','off'); %since cfg.figure name applies only to ft_singleplot the multiplot's name needs to be changed here.
    
else
    
    instr_plot = 'ft_multiplotER(cfg, '; %again, instruction for ft_multiplotER must be built manually

    for DC = 1:length(vis_DC_list)
        instr_plot = [ instr_plot 'DATA_sh{1,' num2str( vis_DC_list(DC) ) '}, ' ];
    end

    instr_plot = instr_plot(1,1:end-2); %removes last coma
    instr_plot = [instr_plot ');'];

    fig = figure('Name', [title '_smoothed'],'NumberTitle','on');
    eval(instr_plot); % finall call of ft_multiplotER( cfg, DATA{1,vis_DC_list(1)}, ..., DATA{1, vis_DC_list(length(vis_DC_list))} )
    set(gcf,'name', [title '_smoothed'] ,'numbertitle','off'); %since cfg.figure name applies only to ft_singleplot the multiplot's name needs to be changed here.
    
end

if ~exist('figfontsize')
    figfontsize = 14;
end
fontsize(fig, figfontsize, "points");
set(gcf,'position',[100,700,2000,1800])



% legend = [];
% for DC = 1:length(vis_DC_list)
%         legend = [ legend ', ' NAME{vis_DC_list(DC)} ];
% end
% legend = legend(1, 3:end);

