function [] = sc_plot_realign(headmodel, sourcemodel, sens, file2save)

if isempty(file2save)
    gcf = figure('Visible', 'on');  % show only when called without saving
else
    gcf = figure('Visible', 'off');
end

ft_plot_headmodel(headmodel, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
hold on;
ft_plot_mesh(sourcemodel, 'maskstyle', 'opacity', 'facecolor', 'black', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5);
hold on;
if isfield(sens, 'fid')  
    if ~isfield(sens.fid, 'pos'); sens.fid.pos=sens.fid.chanpos; end  % a fix for a newer ft 
end
ft_plot_sens(sens, 'label', 'on', 'elecshape', 'disc');


if ~isempty(file2save)
    set(gcf, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');  % save invisible fig with enabled visibility
    savefig(gcf, file2save)

end

