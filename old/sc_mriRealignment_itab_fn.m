
%%  OBSOLETE FUNCTION

function sc_mriRealignment_itab_fn(rc, mriname, infile, chan)

infile_subj = infile(contains(infile, mriname)); % contains all DSes for the current subject. realigment is performed for each DS separately


%%% MRI REALIGNEMENT %%%

mri_path = char(fullfile( rc.expFolder, rc.mriRawFolder ));
mri_file = char(fullfile( rc.expFolder, rc.mriRawFolder, [mriname, '.' ,rc.mriExt] ));
MRIsaveFolder = char(fullfile( rc.expFolder, rc.mriRawFolder, mriname, 'SC' ));
if ~exist(MRIsaveFolder)
    mkdir(MRIsaveFolder)
end


mri = ft_read_mri( mri_file );
mri = ft_determine_coordsys(mri, 'interactive', 'no');
mri = ft_convert_units(mri, 'mm');
%ft_sourceplot([],mri);

%interpolation of volument into 256x256x256 format
    % cfg  = [];
    % mri = ft_volumereslice(cfg, mri);
%ft_sourceplot([],mri);

% To be changed into case structure when having already markus coordsys alignement

switch rc.mriCoordsys
    
    case  {'itab', 'itab-sim', 'syn-sim'}
        
        cfg          = [];
        cfg.method   = 'interactive';
        cfg.coordsys = rc.mriCoordsys;
        mri_itab = ft_volumerealign(cfg, mri); %requires specification of lpa, rpa, nas and positive z-value point
        
        if 0  % old style ITAB realignment. now header grad positions are already aligned
            %importing asc file data for auto-realignment
            elec_info = importdata( fullfile( mri_path, strcat(mriname, '.asc')) , ' ', 1); %AL
            elec_nasrpalpa = elec_info.data([1 2 3],2:4)*10; % dopasowywanie sensorów
            
            %%% AUTO realign the mri with the ITAB head/sensor coordinate system.
            %%% will calculate the transformation matrix according to measurement of
            %%% fiducials in a space common with sensors
            %input  = ft_warp_apply(mri_rlg.transform, [ mri_rlg.cfg.fiducial.nas; mri_rlg.cfg.fiducial.rpa; mri_rlg.cfg.fiducial.lpa],'homogeneous');
            input  = ft_warp_apply(mri_itab.transform, [ mri_itab.cfg.fiducial.nas; mri_itab.cfg.fiducial.rpa; mri_itab.cfg.fiducial.lpa],'homogeneous');
            % cfg.fid are represented in vox; the above is just recal fiducials to mm. it is identical with: mri_ra.transform * [fidx,fidy,fidz,1]
            target = elec_nasrpalpa;
            [result, tra] = ft_warp_optim(input, target, 'rigidbody');
            % the above determines rigid tra params (xyzrpy) to move mri fiducials [mm] to measured fid [mm] (from asc file)
            R = ft_warp_apply([0 0 0 tra(4:6)],eye(3),'rigidbody')'; % rotation params
            transform = [R tra(1:3)'; 0 0 0 1]; % add translation params and create transf matrix
            mri_itab.transform = transform*mri_itab.transform;
        end
        
    otherwise
        mri_itab = mri;
end

%ft_sourceplot([],mri_rlg);

if rc.indivHSmodels
    
    transform_vox2itab = mri_itab.transform;
    
    if ~strcmp(rc.dataFormat, 'itab-sim') %fixme
    save( fullfile(MRIsaveFolder,'mri_itab.mat'), 'mri_itab');
    save( fullfile(MRIsaveFolder,'transform_vox2itab.mat'), 'transform_vox2itab');
    end
    % segmentation for itab headmodel
    
    cfg        = [];
    cfg.interactive = 'no';
    cfg.output      = 'brain';
    cfg.mri.coordsys = 'itab';
    cfg.brainthreshold = 0.5;
    mri_itab_seg         = ft_volumesegment(cfg, mri_itab);
    mri_itab_seg.anatomy = mri_itab.anatomy;
    
    % preparing headmodel
    cfg = [];
    cfg.method = 'singleshell';
    headmodel_indiv_itab = ft_prepare_headmodel(cfg , mri_itab_seg); % creates a headmodel
    
    load(char(infile))
    grad_itab = sc_trim_sens(data_ica2.label, data_ica2.hdr.grad);
    
    % saving headmodel (to be used for leadfield)
    % if ~strcmp(rc.dataFormat, 'itab-sim') %fixme

        save( fullfile(MRIsaveFolder, 'mri_itab_seg.mat'), 'mri_itab_seg');
        save( fullfile(MRIsaveFolder, 'headmodel_indiv_itab.mat'), 'headmodel_indiv_itab');
        save( fullfile(MRIsaveFolder, 'grad_itab.mat'), 'grad_itab');
    % end
    
     
    
    %%% WARPING %%%
    % create the subject specific grid, using template_grid_MNI
%     % will be used for group comparisons (finding matches between subjects in indiv grids)
%     cfg           = [];
%     cfg.warpmni   = 'yes';
%     cfg.template  = template_grid_MNI;
%     cfg.nonlinear = 'yes';
%     cfg.mri       = mri_itab_seg; %loading segmented data - the same one which is used for freesurfer (do freesurfer dajemy mri_acpc, a tutaj dajemy seg)
%     cfg.unit      = 'mm';
%     cfg.interactive = 'no';
%     cfg.spmmethod = 'new';
%     template_grid_warped_itab = ft_prepare_sourcemodel(cfg);
%     
%     save( fullfile(path_raw, 'SC', 'template_grid_warped_itab.mat'), 'template_grid_warped_itab');

    
    %%% ACPC coregistration (needed for freesurfer)
    cfg          = [];
    cfg.method   = 'interactive';
    cfg.coordsys = 'acpc';
    mri_acpc     = ft_volumerealign(cfg, mri_itab);
    
    transform_vox2acpc = mri_acpc.transform;

    % if ~strcmp(rc.dataFormat, 'itab-sim') %fixme
        save (fullfile(MRIsaveFolder, 'mri_acpc.mat'), 'mri_acpc' );
        save (fullfile(MRIsaveFolder, 'transform_vox2acpc.mat'), 'transform_vox2acpc' );
    % end
    
    %ft_sourceplot([],mri_rlg_acpc);
    
    %transform_vox2acpc_bef = mri_rlg_acpc.transform;
    % Reslicing (anatomical volume into ispotropic voxels)
    % cfg            = [];
    % cfg.resolution = 1;
    % cfg.dim        = [256 256 256];
    % mri_rlg_acpc   = ft_volumereslice(cfg, mri_rlg_acpc);
    
    % if ~strcmp(rc.dataFormat, 'itab-sim') %fixme
        % Saving the acpc-coregistered anatomical image
        cfg          = [];
        cfg.filename = fullfile( MRIsaveFolder, sprintf( '%s.mgz', mriname) );
        cfg.filetype = 'mgz';
        cfg.parameter = 'anatomy';
        cfg.datatype = 'double';
        ft_volumewrite(cfg, mri_acpc);
    % end
    
end

% figure; 
% ft_plot_mesh(sourcemodel_indiv_FS_itab, 'maskstyle', 'opacity', 'facecolor', 'black', 'facealpha', 0.1, 'edgecolor', 'white',   'edgeopacity', 0.5); 
% hold on;
% ft_plot_headmodel(headmodel_indiv_itab, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
% hold on;
% ft_plot_mesh(template_grid_warped_itab.pos(template_grid_warped_itab.inside,:));

%%% Saving

% fx = fullfile(mri_subjectname, 'ica_save_meg_2');
% path_file = fullfile(mri_path, fx);

% save(path_file, 'mri_rlg', '-append');
% save(path_file, 'transform_vox2coordsys', '-append');

% clearvars -except mri_rlg transform_vox2coordsys
