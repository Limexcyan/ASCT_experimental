% creates individual head (from segmented T1 scan) and source models (from FreeSurfer based cortical reconstruction
% called only for individual head/source models

function sc_createSrcModel(rc, subjectname)

mripath = char(fullfile( rc.expFolder, rc.mriRawFolder, subjectname));
datapath = fullfile(mripath,'workbench');
scpath = fullfile(mripath, 'SC');

%%% reading downsampled data ACPC-coordinates
if ~exist(fullfile(scpath, 'sourcemodel_indiv_acpc.mat'))
    
    filename = fullfile(datapath,[subjectname,'.L.midthickness.8k_fs_LR.surf.gii']);
    
    if ~exist(filename)

        cprintf('magenta', '\n\n-----------------------------------------------------------------------------------------------------------------------\n');
        % fprintf(['\n\n<strong>FreeSurfer reconstructions not found</strong>\nThe file ' filename ' is missing.\n']);
        cprintf('*magenta', 'NO FreeSurfer RECONSTRUCTION FOUND. MOST LIKELY RECONSTRUCTION HAS NOT BEEN PERFORMED. RUN recon-all BEFORE CONTIMUING ASCT\n');
        cprintf('magenta', '-----------------------------------------------------------------------------------------------------------------------\n');
        cprintf('black', 'Use relevant script from the ASCT/tools (FS-recon or FS-recon-docker) and run before continuing\n\n');

        input("Please press Ctrl+C")
        error();
    end
    
    disp ('Creating individual source model...');

    % create indiv source model from the recon mesh
    sourcemodel_indiv_acpc = ft_read_headshape( {filename, strrep(filename, '.L.', '.R.')} );
    
    % load(fullfile(scpath, 'transform_vox2itab'));
    % load(fullfile(scpath, 'transform_vox2acpc'));
    
    % if strcmp(rc.mriCoordsys, 'itab') || strcmp(rc.mriCoordsys, 'ras')
    % transform_acpc2itab = transform_vox2itab/transform_vox2acpc;
    % sourcemodel_indiv_itab = ft_transform_geometry(transform_acpc2itab, sourcemodel_indiv_acpc);
    % end
    
    save( fullfile(scpath, 'sourcemodel_indiv_acpc.mat'), 'sourcemodel_indiv_acpc');
    % save( fullfile(scpath, 'sourcemodel_indiv_itab.mat'), 'sourcemodel_indiv_itab');
    
else
    disp('Source model found. Skipping sourcemodel creation...');
    load(fullfile(scpath, 'sourcemodel_indiv_acpc.mat'));
end

% check realignment
% figure('visible', 'on');
% ft_plot_headmodel(headmodel_indiv_itab, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
% hold on;
% ft_plot_sens(elec_itab, 'label', 'on');
% hold on;
% ft_plot_mesh(sourcemodel_indiv_itab);


% transform headmodel / segmented MRI to ACPC



%%% REALIG IMG %%%

if ~exist(fullfile(scpath, 'realignment_acpc.fig'))
    
    disp('realigment image save...');
    
    if ~exist('sourcemodel_indiv_acpc', 'var')
        load (fullfile(scpath, 'sourcemodel_indiv_acpc.mat'));
    end
    if ~exist('headmodel_indiv_acpc', 'var')
        load (fullfile(scpath, 'headmodel_indiv_acpc.mat'));
    end
    
    hFig = figure ('visible','off');
    ft_plot_headmodel(headmodel_indiv_acpc, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
    hold on;
    ft_plot_mesh(sourcemodel_indiv_acpc, 'maskstyle', 'opacity', 'facecolor', 'black', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5);
    hold on;

    load (fullfile(scpath, 'sens_acpc.mat'));
    if rc.eeg
        ft_plot_sens(sens_acpc, 'elecshape', 'disc', 'label', 'on');
    else
        ft_plot_sens(sens_acpc, 'coilshape', 'disc', 'label', 'on');
    end
    title(subjectname);
    
    set(hFig, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');   % Set CreateFcn callback to make it visible after opening
    
    savefig(hFig, fullfile(scpath, 'realignment_acpc.fig'))
    close(hFig);
else
    disp('Realignment image found. Skipping...');
end


end
