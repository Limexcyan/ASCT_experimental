loadFolder = fullfile (rc.analysisFolder, '6_ICA2' );
saveFolder = fullfile (rc.analysisFolder, '7_SOURCEACT' );

if isfield(rc, 'ica2Name')
    loadFolder = fullfile (rc.expFolder, rc.ica2Name, '6_ICA2' );
end

if exist(loadFolder)
    infile_all = sc_reading(loadFolder, '*ica2.mat');
    infile = infile_all;
else
    error( 'There are no ICA2 data in the /6_ICA2 folder' );
end

if exist('begId') && exist('endId')
    infile = infile_all(begId : endId);
end

mrisubj = [];
for ds = 1:length(infile)   % to avoid repeating of MRI religm for multiple sessions from a single dubj
    [~,dsname,~] = fileparts(infile{ds});
    dsname = char(strrep(dsname, '_ica2', ''));
    if rc.scan
        mrisubj{ds} = scansim.mri;
    else
        mrisubj{ds} = dsname(design.idPosStart:design.idPosEnd);  % normal mode of analysis - no simulation / scan
        % mrisubj = unique(mrisubj);
    end
end
mrisubj = unique(mrisubj);

%%% MRI / MEG / EEG Relignement %%%

if rc.load <= 7

    if ~isempty(rc.mriRawFolder)

        %%%%% individual realistic models

            sc_mriRealignment_indiv(rc, mrisubj, infile, chan, loc);
    end

    %%%%% template models and template sensors

    if isempty(rc.mriRawFolder)  && isempty(rc.elecRealPos)

    end


    %%%%% template models and measured sensors

    if isempty(rc.mriRawFolder) && ~isempty(rc.elecRealPos)
        if strcmp(rc.dataFormat, 'ctf')
            for ds = 1:length(mrisubj)
                disp (strcat('DS: ', char(mrisubj{ds}), '; Realigning electrode coord system to ACPC...'));
                sc_templateRealignment_fn(rc, char(mrisubj{ds}), infile, chan);
            end
        else
            error('currently, for MEG measured sensors with MRI template, only CTF format is supported ')
        end    
    end


end


%% SOURCE MODEL  + SOURCE LOC %%%
% FIXME - valid if no multiple sessions present; mrisubj = infile

%if stop not requested after realignment. to continue FS data are required for indiv models

%%% CREATING HEAD / SOURCE MODELS

if ~isempty(rc.mriRawFolder)   % calls function only for individual realistic models
        for ds = 1:length(mrisubj)
            mripath = char(fullfile( rc.expFolder, rc.mriRawFolder, mrisubj{ds}));
            scpath = fullfile(mripath, 'SC');
            sc_createSrcModel(rc, char(mrisubj(ds)))
        end
    % end
else
    disp('CAUTION: No T1 scans declared. Template models will be used...')
    if ~isfield(rc, 'headTemplate') || isempty(rc.headTemplate)
        disp('SPM8 template selected');
    else
        disp(['A custom template <strong> ' rc.headTemplate ' </strong> selected']);
    end
end

if ~(rc.stop == 7)

    parfor ds = 1:length(infile)  %parfor

        [~,dsname,~] = fileparts(infile(ds));
        dsname = char(strrep(dsname, '_ica2', ''));

        disp(['Processing DS: ' dsname]);

        if rc.scan    % simulation scan mode
            mriname = scansim.mri;
        else        % normal exp mode
            mriname = dsname(design.idPosStart :design.idPosEnd);
        end

        if ~isempty(rc.mriRawFolder)   % only INDIVIDUAL REALSTIC models out of T1

            scpath = fullfile(rc.expFolder, rc.mriRawFolder, mriname, 'SC');
            if strcmp(rc.dataFormat, 'itab-sim') %fixme
                scpath = '/home/devv/Exp/SIM/ITAB-sim-scan/0_mri/mrtlne88_0101/SC';
            end
            disp (strcat('DS: ', mriname, '; loading head/source models...'));
            tmpload = load (fullfile(scpath, 'sourcemodel_indiv_acpc.mat'));
            sourcemodel_indiv_acpc = tmpload.sourcemodel_indiv_acpc;
            tmpload = load (fullfile(scpath, 'headmodel_indiv_acpc.mat'));
            headmodel_indiv_acpc = tmpload.headmodel_indiv_acpc;
            
            
            % disp (strcat('DS: ', mriname, '; localizing independent components...'));
            cprintf('*blue', strcat('DS: ', mriname, '; localizing independent components...\n'));


            tmpload = load(fullfile(scpath, 'sens_acpc'));
            sens_acpc = tmpload.sens_acpc;

            data_icloc = sc_sourceLocalize(rc, char(infile(ds)), chan, scpath, headmodel_indiv_acpc, sourcemodel_indiv_acpc, sens_acpc, loc);
            % if rc.eeg
            %     % load(fullfile(scpath, 'elec_acpc'))                
            %     data_icloc = sc_sourceLocalize(rc, char(infile(ds)), chan, scpath, headmodel_indiv_acpc, sourcemodel_indiv_acpc, elec_acpc, loc);
            % end
            % if rc.meg
            %     % load(fullfile(scpath, 'grad_acpc'))
            %     data_icloc = sc_sourceLocalize(rc, char(infile(ds)), chan, scpath, headmodel_indiv_acpc, sourcemodel_indiv_acpc, grad_acpc, loc);
            % end
        end



        if isempty(rc.mriRawFolder)   % TEMPLATE models (no individual T1 scans)
            if rc.eeg
                if isempty(rc.headTemplate)
                    tmpload = load('standard_bem');
                    headmodel = tmpload.vol;
                    sourcemodel = ft_read_headshape(fullfile(rc.asctdir, 'MNE_functions', 'standard_mesh_atlases', 'cortex_20484.surf.gii'));
                    disp('CAUTION: standard_bem template used as a headmodel')
                    disp('CAUTION: cortex_20484.surf template used as a sourcemodel')
                else
                    tmpload = load(rc.headTemplate);
                    headmodel = tmpload.vol;
                    tmpdata = load(rc.sourceTemplate);
                    sourcemodel = tmpdata.sourcemodel_indiv_acpc;
                end
            end
            if rc.meg
                if isempty(rc.headTemplate)
                    tmpload = load('standard_headmodel_singleshell');
                    headmodel = tmpload.vol;
                    disp('CAUTION: standard singleshell template used as a headmodel')
                    sourcemodel = ft_read_headshape(fullfile(rc.asctdir, 'MNE_functions', 'standard_mesh_atlases', 'cortex_20484.surf.gii'));
                    disp('CAUTION: cortex_20484.surf template used as a sourcemodel')
                else
                    tmpload = load(rc.headTemplate);
                    headmodel = tmpload.headmodel_indiv_acpc;
                    tmpload = load(rc.sourceTemplate);
                    sourcemodel = tmpload.sourcemodel_indiv_acpc;
                end
            end

            % fit template to elecpos if requested

            % if ~isfield(chan, 'elecmat_fit2templ') || chan.elecmat_fit2templ == 0
            %     % no adjustment
            % else
            %     % fine adjustment of the
            % end

            % save realign figs (for individual templates this saving is done during relaignment)
            % sc_plot_realign(headmodel, sourcemodel, tlck.elec, fullfile(saveFolder, 'sensors', sttcat('realignment_', dsname, '.fig')))

            tmpload = [];
            data_icloc = sc_sourceLocalize(rc, char(infile(ds)), chan, [], headmodel, sourcemodel, [], loc);

        end
    end

    clear tmpload

else
    if isempty(rc.mriRawFolder)
        disp ('STOP requested after realignment.')
    else
        disp ('STOP requested after realignment. Check FreeSurfer stuff before continuing')
    end

end
