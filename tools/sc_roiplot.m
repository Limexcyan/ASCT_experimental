% load template_grid_MNI_5mm_inside.mat

% function = sc_roiplot

if ~exist('figvis')
    figvis = 1;
end

if figvis
    gcf = figure('visible', 'on');  
else
    gcf = figure('visible', 'off');  
end

sourcemodel = ft_read_headshape('/mnt/devv/ASCT/MNE_functions/standard_mesh_atlases/cortex_20484.surf.gii');

% figure('visible', 'on')

ft_plot_mesh(sourcemodel, 'facecolor', [0.9 0.9 0.9], 'facealpha', 0.1, 'edgecolor', 'none')
camlight
lighting gouraud

hold on;

for i = 1:length(loc.ROI)
x(i)=loc.ROI(i).pos(1);
y(i)=loc.ROI(i).pos(2);
z(i)=loc.ROI(i).pos(3);
t{i}=loc.ROI(i).name;
end
loctbl = table(x,y,z);
plot3(x,y,z,'o', 'MarkerSize',8, 'MarkerFaceColor','red');
text(x+5,y+5,z+5,t, 'FontSize', 12)

