function sc_realplot(headmodel, elec1, elec2orfid, savefile)

                ff = figure;
                ft_plot_headmodel(headmodel, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
                hold on;
                ft_plot_sens(elec1, 'label', 'on', 'elecshape', 'disc');
                hold on;
                ft_plot_sens(elec2orfid, 'label', 'on', 'elecshape', 'sphere', 'edgecolor', 'red');
                % hold on;
                % ft_plot_sens(elec_itab, 'label', 'on', 'elecshape', 'disc');
                savefig(savefile);
                close(ff);

end