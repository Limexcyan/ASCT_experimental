clear all
load('template_grid_MNI');
sourcemodel = template_grid_MNI;
clear template_grid_MNI
stay = find(sourcemodel.inside==1);
template_grid_MNI.pos = sourcemodel.pos(stay, :);
template_grid_MNI.inside = sourcemodel.inside(stay);
template_grid_MNI.dim = sourcemodel.dim;
template_grid_MNI.unit = 'mm';
template_grid_MNI.cfg = sourcemodel.cfg;

figure; 
ft_plot_headmodel(headmodel_indiv, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
hold on;
ft_plot_mesh(sourcemodel_indiv, 'maskstyle', 'opacity', 'facecolor', 'black', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5); 
hold on;
ft_plot_mesh(template_grid_warped.pos(template_grid_warped.inside,:), 'maskstyle', 'opacity', 'vertexcolor', 'blue', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5);