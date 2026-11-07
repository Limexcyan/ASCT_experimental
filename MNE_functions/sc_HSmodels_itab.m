
%%% reading downsampled data ACPC-coordinates 
sourcemodel_indiv_FS = ft_read_headshape( {filenameFS, strrep(filenameFS, '.L.', '.R.')} ); %i to przechodzi z volumetrycznych na mesh % bo gii można oglądać przez programy, które rysują dane volumetryczne
transform_acpc2itab = transform_vox2itab/transform_vox2acpc;
sourcemodel_indiv_FS_itab = ft_transform_geometry(transform_acpc2itab, sourcemodel_indiv_FS);
    sourcemodel_indiv_FS_itab.inside = sourcemodel_indiv_FS_itab.atlasroi>0;
    sourcemodel_indiv_FS_itab = rmfield(sourcemodel_indiv_FS_itab, 'atlasroi');
save( fullfile(path_data , 'SC', 'sourcemodel_indiv_FS_itab.mat'), 'sourcemodel_indiv_FS_itab');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Segment the anatomical MRI ITAB %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cfg        = [];
cfg.interactive = 'no';
cfg.output      = 'brain';
cfg.mri.coordsys = 'itab';
cfg.brainthreshold = 0.5;
mri_rlg_itab_brain         = ft_volumesegment(cfg, mri_rlg_itab);
mri_rlg_itab_brain.anatomy = mri_rlg_itab.anatomy;

% preparing headmodel
cfg = [];
cfg.method = 'singleshell';
headmodel_indiv_itab = ft_prepare_headmodel(cfg , mri_rlg_itab_brain); % creates a headmodel

% saving headmodel (to be used for leadfield)
save( fullfile(path_raw, 'SC', 'headmodel_indiv_itab.mat'), 'headmodel_indiv_itab');

%%%%%%%%%%%%%%%
%%% WARPING %%%    
%%%%%%%%%%%%%%%
% create the subject specific grid, using template_grid_MNI
% will be used for group comparisons (finding matches between subjects in indiv grids)
cfg           = [];
cfg.warpmni   = 'yes';
cfg.template  = template_grid_MNI;
cfg.nonlinear = 'yes';
cfg.mri       = mri_rlg_itab_brain; %loading segmented data - the same one which is used for freesurfer (do freesurfer dajemy mri_acpc, a tutaj dajemy seg)
cfg.unit      = 'mm';
cfg.interactive = 'no';
cfg.spmmethod = 'new';
template_grid_warped_itab = ft_prepare_sourcemodel(cfg); 

save( fullfile(path_raw, 'SC', 'template_grid_warped_itab.mat'), 'template_grid_warped_itab');
save( fullfile(path_raw, 'SC', 'headmodel_indiv_itab.mat'), 'headmodel_indiv_itab');



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% make a figure of the subject headmodel, and grid ITAB %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure; 
ft_plot_mesh(sourcemodel_indiv_FS_itab, 'maskstyle', 'opacity', 'facecolor', 'black', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5); 
hold on;
ft_plot_headmodel(headmodel_indiv_itab, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
hold on;
ft_plot_mesh(template_grid_warped_itab.pos(template_grid_warped_itab.inside,:));
%ft_plot_mesh(sourcemodel_indiv_FS, 'maskstyle', 'opacity', 'facecolor', 'green', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5); 
%ft_plot_mesh(template_grid_warped.pos(template_grid_warped.inside,:), 'maskstyle', 'opacity', 'vertexcolor', 'blue', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5);



