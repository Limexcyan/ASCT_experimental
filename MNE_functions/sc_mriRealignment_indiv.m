% provides realigment for all corridante systems needed (T1, sensors) and prepared acpc data for FS recon
% called only for individual head/source models

function sc_mriRealignment_indiv(rc, mrisubj, infile, chan, loc)

for ms = 1:length(mrisubj)

    mriname = char(mrisubj(ms));
    % infile_subj = infile(contains(infile, mriname)); % contains all DSes for the current subject. realigment is performed for each DS separately
    MRIloadFolder = char(fullfile( rc.expFolder, rc.mriRawFolder));
    SCfolder = char(fullfile( rc.expFolder, rc.mriRawFolder, mriname, 'SC'));

    if ~isfolder(SCfolder); mkdir(SCfolder); end

    cprintf('*blue', ['Starting with realignment / haead- and source model\nsubj: ' mriname '\n']);

    %% T1 NAS/LPA/RPA realign

    % ft_sourceplot([],mri);

    if ~exist(fullfile(SCfolder, 'mri_real.mat')) % || ~exist(fullfile(SCfolder, 'transform_vox2itab.mat'))  % skip if some realignment stuff is already present

        orygfname = fullfile (MRIloadFolder, strcat(rc.mriPrefix, mriname, rc.mriExt));
        tmpfname = fullfile (SCfolder, strcat(mriname, '.', rc.mriExt(end-2:end)));
        copyfile (orygfname, tmpfname);
        mri = ft_read_mri( tmpfname ); %reading mri data

        if exist(fullfile(MRIloadFolder,'mriCoordsys.mat'), 'file')   % if already detemined, read coords from the file - they should be the same for all scans
            load(fullfile(MRIloadFolder,'mriCoordsys.mat'));
        else   % determine orientation of axes
            mriCoordsys = ft_determine_coordsys(mri).coordsys;
            save(fullfile(MRIloadFolder, 'mriCoordsys.mat'), 'mriCoordsys')
        end

        % coordsys provided by ft_deteminecoordsys are not recognized by
        % other FT functions. here's the fix:

        if contains(mriCoordsys, 'ras')
            fixedCoordsys='itab';
        elseif contains(mriCoordsys, 'als')
            fixedCoordsys='ctf';
        elseif contains(mriCoordsys, 'rps')
            fixedCoordsys='paxinos';
        else
            disp('-------------- unknown corrdinate system of MRI scans. only RAS, ALS and RPS orientations are recognized ---------------')
            error('unknown coordinate system');
        end

        mri.coordsys = fixedCoordsys;
        rc.mriCoordsys = fixedCoordsys;

        mri = ft_convert_units(mri, 'mm');

        cprintf('magenta', '\n\n-------------------------------------------------------------------------------------------------\n');
        cprintf('*magenta',    'now, please mark NAS (n), LPA (l), RPA (r) fiducials, and any Z+ point (z). press (q) to finalize\n');
        cprintf('magenta',     '--------------------------------------------------------------------------------------------------\n\n');


        cfg          = [];
        cfg.method   = 'interactive';
        cfg.coordsys = fixedCoordsys;

        pfp = get(0,'defaultfigureposition'); % (prev fig position) temporary increase size of realign win
        maxmon = get(0,'MonitorPositions');
        maxmon(size(maxmon,1),:); % full monitor or the full second monitor if exist
        maxmon = maxmon(size(maxmon,1),:); % full monitor or the full second monitor if exist

        set(0,'defaultfigureposition',maxmon); % maximize rel window
        mri_real = ft_volumerealign(cfg, mri); %requires specification of lpa, rpa, nas and positive z-value point
        set(0,'defaultfigureposition',pfp); % get back to previous fig params

        transform_vox2itab = mri_real.transform;
        save (fullfile(SCfolder, 'mri_real.mat'), 'mri_real' );
        save (fullfile(SCfolder, 'transform_vox2itab'), 'transform_vox2itab' );
        % t=mri_real.transform;   (vox2itab)  t*[128;128;128;1] % calculate from fi voxel x y z to physical space in mm

    else
        disp('Some Realignment stuff found. Skipping Nas/LPA/RPA T1 realign.');
    end

end


%% switch to ACPC coords

for ms = 1:length(mrisubj)

    mriname = char(mrisubj(ms));
    infile_subj = infile(contains(infile, mriname)); % contains all DSes for the current subject. realigment is performed for each DS separately
    MRIloadFolder = char(fullfile( rc.expFolder, rc.mriRawFolder, mriname ));
    SCfolder = char(fullfile( rc.expFolder, rc.mriRawFolder, mriname, 'SC'));

    if ~exist(fullfile( SCfolder, 'mri_acpc.mat')) || ~exist(fullfile( SCfolder, 'transform_vox2acpc.mat'))

        % clear
        disp('Reading T1 scan for ACPC realignment...');
        disp(fullfile(SCfolder, 'mri_real.mat'));
        mri_real = ft_read_mri(fullfile(SCfolder, 'mri_real.mat'));
        load(fullfile(SCfolder, 'transform_vox2itab.mat'));

        cprintf('magenta', '\n\n-------------------------------------------------------------------------------------------\n');
        cprintf('*magenta',    'now, please mark AC (a), PC (p), and any Z+ (z) and right (r) points. press (q) to finalize\n ');
        cprintf('magenta',     '-------------------------------------------------------------------------------------------\n\n');

        % tmp_mri = load(fullfile(SCfolder, 'mri_real.mat'));
        % mri_real = tmp_mri.mri_real;
        % clear tmp_mri

        pfp = get(0,'defaultfigureposition'); % (prev fig position) temporary increase size of realign win
        maxmon = get(0,'MonitorPositions');
        maxmon = maxmon(size(maxmon,1),:); % full monitor or the full second monitor if exist
        set(0,'defaultfigureposition',maxmon);

        %%% ACPC coregistration (needed for freesurfer)
        cfg          = [];
        cfg.method   = 'interactive';
        cfg.coordsys = 'acpc';
        mri_acpc     = ft_volumerealign(cfg, mri_real);

        transform_vox2acpc = mri_acpc.transform;

        set(0,'defaultfigureposition',pfp); % get back to previous fig params

        % Saving the acpc-coregistered anatomical image
        cfg          = [];
        % cfg.filename = fullfile( MRIloadFolder, sprintf( '%s.mgz', mriname ));
        cfg.filename = fullfile( MRIloadFolder, 'SC', sprintf( '%s.mgz', mriname ));
        cfg.filetype = 'mgz';
        cfg.parameter = 'anatomy';
        cfg.datatype = 'double';
        ft_volumewrite(cfg, mri_acpc);
        %ft_sourceplot([],mri_rlg_acpc)

        if isempty(rc.elecRealPos)  % nifti volume is needed only for deformation field when no digitized sensors are available
            cfg          = [];
            % cfg.filename = fullfile( MRIloadFolder, 'SC', sprintf( '%s.nii', mriname ));
            cfg.filename = fullfile( MRIloadFolder, 'SC', 'mri_acpc.nii');
            cfg.filetype = 'nifti';
            cfg.parameter = 'anatomy';
            cfg.datatype = 'double';
            ft_volumewrite(cfg, mri_acpc);
        end

        save(fullfile( SCfolder, 'mri_acpc.mat') ,'mri_acpc');
        save(fullfile( SCfolder, 'transform_vox2acpc.mat') ,'transform_vox2acpc');
    else
        disp('Some realignment stuff found. Skipping ACPC conversion.');
        mri_acpc = ft_read_mri(fullfile( SCfolder, 'mri_acpc.mat'));
    end

end

for ms = 1:length(mrisubj)

    mriname = char(mrisubj(ms));
    MRIloadFolder = char(fullfile( rc.expFolder, rc.mriRawFolder, mriname ));
    SCfolder = char(fullfile( rc.expFolder, rc.mriRawFolder, mriname, 'SC'));

    %% segmentation of realigned (acpc) T1

    disp(['DS:', mriname, '; Segmenting of ACPC T1'])

    if ~exist(fullfile(SCfolder, 'mri_acpc_seg.mat'))

        mri_acpc = ft_read_mri(fullfile( SCfolder, 'mri_acpc.mat'));

        cfg        = [];
        cfg.interactive = 'no';

        if rc.eeg
            switch loc.headmodelMethod
                case {'openmeeg', 'bemcp', 'dipoli'}
                    cfg.output    = {'brain','skull','scalp'};
                case {'simbio'}
                    cfg.output    = {'gray','white','csf','skull','scalp'};
            end
        end
        if rc.meg
            cfg.output      = 'brain';
            cfg.mri.coordsys = 'itab';
            cfg.brainthreshold = 0.5;
        end

        % cfg.mri.coordsys = 'itab';
        mri_acpc_seg = ft_volumesegment(cfg, mri_acpc);
        mri_acpc_seg.anatomy = mri_acpc.anatomy;

        save( fullfile(SCfolder, 'mri_acpc_seg.mat'), 'mri_acpc_seg');
    else
        disp('Segmented MRI scan found. Using existing file...');
    end


    %% create indiv headmodel

    if ~exist (fullfile(SCfolder, 'headmodel_indiv_acpc.mat'))

        mri_acpc_seg = ft_read_mri(fullfile( SCfolder, 'mri_acpc_seg.mat'));

        cfg        = [];
        switch loc.headmodelMethod
            case {'simbio'}
                cfg.shift  = 0.3;
                cfg.method = 'hexahedral';
                if ~exist(fullfile(SCfolder, 'simbiomesh.mat'), 'file') || loc.reslice
                    if loc.reslice
                        mri_acpc_seg = ft_volumereslice([], mri_acpc_seg);
                    end
                    simbiomesh = ft_prepare_mesh(cfg,mri_acpc_seg);  %additional mesh needed for simbio
                    save(fullfile(SCfolder, 'simbiomesh.mat'), 'simbiomesh')
                else
                    load(fullfile(SCfolder, 'simbiomesh.mat'));
                end
                cfg = [];
                cfg.method = loc.headmodelMethod;
                cfg.conductivity = [0.33 0.14 1.79 0.01 0.43];   % order follows mesh.tissuelabel
                try
                    headmodel_indiv_acpc = ft_prepare_headmodel(cfg, simbiomesh);
                    headmodelok = 1;
                catch
                    disp('ERROR: headmodel not created!')
                    headmodelok = 0;
                end
            case {'openmeeg', 'dipoli', 'bemcp'}
                cfg.method = loc.headmodelMethod;
                try
                    headmodel_indiv_acpc = ft_prepare_headmodel(cfg, mri_acpc_seg);
                    headmodelok = 1;
                catch
                    disp('ERROR: headmodel not created!')
                    headmodelok = 0;
                end

            case {'singleshell'}
                cfg = [];
                cfg.method = 'singleshell';
                try
                    headmodel_indiv_acpc = ft_prepare_headmodel(cfg , mri_acpc_seg); % creates a headmodel
                    headmodelok = 1;
                catch
                    disp('ERROR: headmodel not created!')
                    headmodelok = 0;
                end
                % error()
                % load(char(infile))
                % grad_itab = sc_trim_sens(data_ica2.label, data_ica2.hdr.grad);

        end

        % if ~strcmp(loc.headmodelMethod,'simbio')   % why was this needed?
        % which method? so currently disabled
        %     headmodel_indiv_acpc.bnd(1).coordsys = 'acpc';
        %     headmodel_indiv_acpc.bnd(2).coordsys = 'acpc';
        %     headmodel_indiv_acpc.bnd(3).coordsys = 'acpc';
        % end

        if headmodelok
            save( fullfile(SCfolder, 'headmodel_indiv_acpc.mat'), 'headmodel_indiv_acpc');
        end
    else
        disp('Headmodel found. Skipping.');
        load(fullfile(SCfolder, 'headmodel_indiv_acpc.mat'));

    end


    %% coregister the electrodes to the ACPC system using fiducials

    if ~exist (fullfile(SCfolder, 'sens_acpc.mat'))

        if rc.eeg  

            if ~isempty(rc.elecRealPos)      % rigid coregistration based on indov T1 and digitized electrodes

                disp('Loading ICA2 data...');
                dsdata = load(char(infile_subj));

                [di, fi, ~] = fileparts(char(infile_subj));
                di = strrep(di, '6_ICA2', '7_SOURCEACT');
                dsFolder = fullfile (di, strrep(fi, '_ica2', ''));
                if ~isfolder(dsFolder); mkdir(dsFolder); end

                n_elec = length(chan.elec); %number of electric channels
                labels = dsdata.data_ica2.label(1:length(dsdata.data_ica2.label)-n_elec);
                labels(length(labels)+1)={'LPA'};
                labels(length(labels)+1)={'RPA'};
                labels(length(labels)+1)={'Nz'};

                sens_origpos = sc_readSensors(rc, labels);

                %% recalculate fiducial coordinates to itab system

                % determine the same marker locations in voxel coordinates, e.g., [57,127,15])

                if ~exist ("mri_real","var"); load(fullfile(SCfolder, 'mri_real.mat')); end
                if ~exist ("transform_vox2itab","var"); load(fullfile(SCfolder, 'transform_vox2itab.mat')); end


                mri_vox_Nas = mri_real.cfg.fiducial.nas;  % fiducials saved in mri structure expressed in voxels
                mri_vox_LPA = mri_real.cfg.fiducial.lpa;
                mri_vox_RPA = mri_real.cfg.fiducial.rpa;

                % transform voxel indices to itab head coordinates  (similar to: transform_vox2itab * vox_Nas [with added '1' line)
                mri_real_nas          = ft_warp_apply(transform_vox2itab, mri_vox_Nas, 'homogenous'); % nasion
                mri_real_lpa          = ft_warp_apply(transform_vox2itab, mri_vox_LPA, 'homogenous'); % Left preauricular
                mri_real_rpa          = ft_warp_apply(transform_vox2itab, mri_vox_RPA, 'homogenous'); % Right preauricular

                % fiducials in itab coords
                fid_acpc.elecpos = [mri_real_nas; mri_real_lpa; mri_real_rpa];
                fid_acpc.chanpos = fid_acpc.elecpos;
                fid_acpc.label = {'nas'; 'lpa'; 'rpa'};
                fid_acpc.unit  = 'mm';


                cprintf('*magenta', 'Using digitized real position of sensors for realignment with T1 scan...');
                cfg = [];
                cfg.method    = 'fiducial';   % rigid transform of realistic elec pos
                cfg.elec      = sens_origpos;
                cfg.fiducial = {'nas', 'lpa', 'rpa'};
                cfg.casesensitive = 'no';
                cfg.feedback = 'yes';
                cfg.target.pos(1,:) = [fid_acpc.chanpos(1,1) fid_acpc.chanpos(1,2) fid_acpc.chanpos(1,3) ];     % location of the nose
                cfg.target.pos(2,:) = [fid_acpc.chanpos(2,1) fid_acpc.chanpos(2,2) fid_acpc.chanpos(2,3) ];     % location of the left ear
                cfg.target.pos(3,:) = [fid_acpc.chanpos(3,1) fid_acpc.chanpos(3,2) fid_acpc.chanpos(3,3) ];     % location of the right ear
                try  % try realigment with different names of fiducials
                    cfg.target.label = {'Nz', 'LPA', 'RPA'};
                    sens_acpc = ft_electroderealign(cfg);
                catch
                    cfg.target.label = {'nas', 'lpa', 'rpa'};
                    sens_acpc = ft_electroderealign(cfg);
                end

                % sc_realplot(headmodel_indiv_itab, sens_acpc, fid_itab, fullfile(SCfolder, 'elecrealignment_itab.fig'));

            else     % warping standard 10-20 electrodes to indiv head using SPM deformation field from normalizing T1 to template

                cprintf('*magenta', '10-20 sensors realigment to T1 scans...\n');

                if exist(fullfile( MRIloadFolder, 'SC', 'y_mri_acpc.nii'), 'file')   % use deform field if exists, if not, calculate it
                    forward_def = fullfile( MRIloadFolder, 'SC', 'y_mri_acpc.nii');
                else
                    sc_rmpaths('external/spm12');   % removes fieldtrip-bundled spm that messes up with regular spm
                    [forward_def, ~] = sc_getDeformationField(fullfile( MRIloadFolder, 'SC', 'mri_acpc.nii'));
                end

                sens_origpos = sc_readSensors(rc);
                sens_acpc = sens_origpos;
                sens_acpc.chanpos = sc_appyDeformation(forward_def, sens_origpos.chanpos);
                sens_acpc.elecpos = sens_acpc.chanpos;

            end

            %%  fine realigment (step 2) - projections on surface to fit them perfectly

            sens_acpc1 = sens_acpc;  % before projection
            cfg = [];
            cfg.method    = 'project';   %projected onto realistic headshape
            cfg.elec      = sens_acpc1;
            if strcmp(loc.headmodelMethod, 'dipoli'); cfg.headshape = headmodel_indiv_acpc.bnd(1); end    %points at skin layer
            if strcmp(loc.headmodelMethod, 'openmeeg'); cfg.headshape = headmodel_indiv_acpc.bnd(1); end    %points at skin layer
            if strcmp(loc.headmodelMethod, 'bemcp'); cfg.headshape = headmodel_indiv_acpc.bnd(3); end
            if strcmp(loc.headmodelMethod, 'simbio')
                if ~exist('simbiomesh', 'var'); load(fullfile(SCfolder, 'simbiomesh.mat')); end
                cfg.headshape = simbiomesh;
            end
            sens_acpc = ft_electroderealign(cfg);

        end

        if rc.meg

            disp('Loading ICA2 data...');
            dsdata = load(char(infile_subj));

            [di, fi, ~] = fileparts(char(infile_subj));
            di = strrep(di, '6_ICA2', '7_SOURCEACT');
            dsFolder = fullfile (di, strrep(fi, '_ica2', ''));
            if ~isfolder(dsFolder); mkdir(dsFolder); end

            n_elec = length(chan.elec); %number of electric channels
            labels = dsdata.data_ica2.label(1:length(dsdata.data_ica2.label)-n_elec);
            labels(length(labels)+1)={'LPA'};
            labels(length(labels)+1)={'RPA'};
            labels(length(labels)+1)={'Nz'};

            sens_origpos = sc_readSensors(rc, labels);
            sens_origpos = ft_convert_units(sens_origpos,'mm');

            nas_sspace = dsdata.data_ica2.fid.NAS;
            lpa_sspace = dsdata.data_ica2.fid.LPA;
            rpa_sspace = dsdata.data_ica2.fid.RPA;
            fid.unit = 'mm';

            nch = length(sens_origpos.label);
            sens_origpos.label(nch+1) = {'NAS'}; sens_origpos.label(nch+2) = {'LPA'}; sens_origpos.label(nch+3) = {'RPA'};
            sens_origpos.chanori(nch+1,:) = [0, 0, 0]; sens_origpos.chanori(nch+2,:) = [0, 0, 0]; sens_origpos.chanori(nch+3,:) = [0, 0, 0];
            sens_origpos.chanpos(nch+1,:) = nas_sspace; sens_origpos.chanpos(nch+2,:) = lpa_sspace; sens_origpos.chanpos(nch+3,:) = rpa_sspace;
            sens_origpos.coilpos(nch+1,:) = nas_sspace; sens_origpos.coilpos(nch+2,:) = lpa_sspace; sens_origpos.coilpos(nch+3,:) = rpa_sspace;
            sens_origpos.coilori(nch+1,:) = [0, 0, 0]; sens_origpos.coilori(nch+2,:) = [0, 0, 0]; sens_origpos.coilori(nch+3,:) = [0, 0, 0];
            sens_origpos.chantype(nch+1) = {'fid'}; sens_origpos.chantype(nch+2) = {'fid'}; sens_origpos.chantype(nch+3) = {'fid'};
            sens_origpos.chanunit(nch+1) = {'mm'}; sens_origpos.chanunit(nch+2) = {'mm'}; sens_origpos.chanunit(nch+3) = {'mm'};
            sens_origpos.elecpos = sens_origpos.chanpos;

            if ~exist ("mri_real","var"); load(fullfile(SCfolder, 'mri_real.mat')); end
            if ~exist ("transform_vox2acpc","var"); load(fullfile(SCfolder, 'transform_vox2acpc.mat')); end

            mri_vox_Nas = mri_real.cfg.fiducial.nas;  % fiducials saved in mri structure expressed in voxels
            mri_vox_LPA = mri_real.cfg.fiducial.lpa;
            mri_vox_RPA = mri_real.cfg.fiducial.rpa;

            % transform itab indices to acpc head coordinates
            mri_acpc_nas          = ft_warp_apply(transform_vox2acpc, mri_vox_Nas, 'homogenous'); % nasion
            mri_acpc_lpa          = ft_warp_apply(transform_vox2acpc, mri_vox_LPA, 'homogenous'); % Left preauricular
            mri_acpc_rpa          = ft_warp_apply(transform_vox2acpc, mri_vox_RPA, 'homogenous'); % Right preauricular

            % fiducials in acpc coords
            fid_acpc.elecpos = [mri_acpc_nas; mri_acpc_lpa; mri_acpc_rpa];
            fid_acpc.chanpos = fid_acpc.elecpos;
            fid_acpc.label = {'nas'; 'lpa'; 'rpa'};
            fid_acpc.unit  = 'mm';

            cprintf('*magenta', 'Using digitized real position of sensors for realignment with T1 scan...');
            cfg = [];
            cfg.method    = 'fiducial';   % rigid transform of realistic elec pos
            cfg.elec      = sens_origpos;
            cfg.fiducial = {'nas', 'lpa', 'rpa'};
            cfg.casesensitive = 'no';
            cfg.feedback = 'no';
            cfg.target.pos(1,:) = [fid_acpc.chanpos(1,1) fid_acpc.chanpos(1,2) fid_acpc.chanpos(1,3) ];     % location of the nose
            cfg.target.pos(2,:) = [fid_acpc.chanpos(2,1) fid_acpc.chanpos(2,2) fid_acpc.chanpos(2,3) ];     % location of the left ear
            cfg.target.pos(3,:) = [fid_acpc.chanpos(3,1) fid_acpc.chanpos(3,2) fid_acpc.chanpos(3,3) ];     % location of the right ear
            % chantype = sens_origpos.chantype;
            try  % try realigment with different names of fiducials
                cfg.target.label = {'Nz', 'LPA', 'RPA'};
                sens_dummy = ft_electroderealign(cfg);
            catch
                cfg.target.label = {'nas', 'lpa', 'rpa'};
                sens_dummy = ft_electroderealign(cfg);
            end
            T = sens_dummy.homogeneous;  % fix for ft_electroderealign only partially handling grads
            sens_acpc = ft_transform_geometry(T, sens_origpos);
            if isfield(sens_acpc, 'elecpos'); sens_acpc = rmfield(sens_acpc, 'elecpos'); end
        end

        save (fullfile(SCfolder, 'sens_acpc.mat'), 'sens_acpc' );

    else
        disp('realigned sensors file found. Skipping realignment..');
        % load (fullfile(SCfolder, 'sens_acpc.mat'))
    end

end



% check real
% gcf = figure('Visible', 'on');  % show only when called without saving
% ft_plot_headmodel(headmodel_indiv_acpc, 'facecolor', 'cortex', 'edgecolor', 'none'); alpha 0.2; camlight;
% hold on;
% ft_plot_sens(sens_origpos, 'label', 'on', 'elecshape', 'disc', 'facecolor', 'yellow');
% hold on;
% ft_plot_sens(sens_acpc, 'label', 'on', 'elecshape', 'disc', 'facecolor', 'green');
% hold on;
% ft_plot_sens(sens_acpc1, 'label', 'on', 'elecshape', 'disc', 'facecolor', 'red');
% hold on;
