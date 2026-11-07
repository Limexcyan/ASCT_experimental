%%%%%%%%% ICA WRAPPER %%%%%%
% Consists of:
% ICA1 decomposition
% ICA1 classification
% IC-based artifact rejection
% ICA2 decomposition

clear all_data_ica1 all_data_ica2

folder3ARJ = fullfile (rc.analysisFolder, '3_ARTIFREE' );
folderICA1  = fullfile (rc.analysisFolder, '4_ICA1' );
folderICA1ar = fullfile (rc.analysisFolder, '5_ICA1_AR' );
if ~exist(folderICA1); mkdir(folderICA1); end
if ~exist(folderICA1ar); mkdir(folderICA1ar); end

% default parameter settings
if ~isfield(ica, 'ICA1_classMode'); ica.ICA1_classMode = 'full'; end  %MD - used for choosing classif model: % + 'full'  -  Image and Cateogorical% + 'image' - Image only  % + 'cat'   - categorical only
if ~isfield(ica, 'ICA1_classModel'); ica.ICA1_classModel = 'classification_models_ica1.mat'; end
if ~isfield(ar, 'ica_ic2screen'); ar.ica_ic2screen = 0; end

% manage parpool / check if not expired
if rc.useParallel
    poolobj = gcp('nocreate'); % just check, do not create new one.
    if isempty(poolobj)
        parpool(rc.useParallel);
    end
end

%% loading ARJ data

if rc.load <= 3 % do ICA1 and ICA-AR unless asked for loading already performed ICA1-AR

    clear data_all_arj
    loadFolderarj = fullfile(rc.analysisFolder, '/3_ARTIFREE' );

    % reading 'infile' file
    if exist(loadFolderarj)
        infile_all = sc_reading(loadFolderarj, '*ARJ.mat');
        infile = infile_all;
    else
        error( ['There are no ARTIFACT-FREE data in the /3_ARTIFREE folder.'] );
    end

    if exist('begId') && exist('endId')
        infile = infile_all(begId : endId);
    end

    parfor  ds = 1 : length(infile)
        if isempty(infile{ds})
            error(['No data in infile(',num2str(ds),').' newline, 'It might happen that due to begId and length(infile) speficifaction this ds has not been segmented earlier'] );
        else
            [~, dsname, ~] = fileparts(infile{ds});
            disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ARTIF-free data: ', dsname, ' (DS ', num2str(ds), ')'));
            tmparj = load( infile{ds}, 'data_artf' );
            data_all_arj(ds) = tmparj.data_artf;
        end
    end

    clear data_artf tmparj

    for ds = 1:length(infile)
        infile{ds} = replace(infile{ds}, '_ARJ', '');
        infile{ds} = replace(infile{ds}, '_PREP', '');
    end


    %% ICA1 DECOMPOSITION

    if ~(strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim'))


        if rc.useParallel > 1
            parfor ds = 1 : size(data_all_arj,2)
                [~, dsname, ~] = fileparts( infile{ds} ); % extract file path, sigsa set name, and extension
                data_decomp_ica1 = [];
                [data_decomp_ica1] = sc_4_DECOMPOSITION_ICA1_fn(data_all_arj(ds), dsname, chan, rc, seg, ica, ar, filter);
                if ~isempty(data_decomp_ica1.ICA)
                    data_all_decomp_ica1(ds)=data_decomp_ica1;
                else  %ICA1 failed

                end
            end
        else
            for ds = 1 : size(data_all_arj,2)
                [~, dsname, ~] = fileparts( infile{ds} ); % extract file path, sigsa set name, and extension
                data_decomp_ica1 = [];
                [data_decomp_ica1] = sc_4_DECOMPOSITION_ICA1_fn(data_all_arj(ds), dsname, chan, rc, seg, ica, ar, filter);
                if ~isempty(data_decomp_ica1.ICA)
                    data_all_decomp_ica1(ds)=data_decomp_ica1;
                else  %ICA1 failed

                end
            end
        end

        nc_all = [{'dsname' 'best_iter' 'nc' 'nc_brain'}];  % save log with number of components found at ica1
        for  ds = 1 : length(infile)
            nc_all(ds+1,1) = {data_all_decomp_ica1(ds).dsname};  % save log with number of components found at ica1
            try
                nc_all(ds+1,2) = data_all_decomp_ica1(ds).ic_stat(2);
                nc_all(ds+1,3) = data_all_decomp_ica1(ds).ic_stat(3);
                nc_all(ds+1,4) = data_all_decomp_ica1(ds).ic_stat(4);
            catch
                nc_all(ds+1,2) = {0};  % save log with number of components found at ica1
                nc_all(ds+1,3) = {0};  % save log with number of components found at ica1
                nc_all(ds+1,4) = {0};
            end
        end

        
        file_name = fullfile(folderICA1, 'ICA1_nc.mat');
        save(file_name, 'nc_all');
    else
        disp('ICA1 not needed for synthetic data');
    end


end   %rc.load <=3

clear all_data_ica1 all_data_ica2 data_decomp_ica1 artifact_smp_oryg data_all_arj data_all_decomp_ica1 infile infile_all Classif classif_rep_IF_conv classif_rept_MLP IF_conv_model IF_mlp_model

if rc.stop == 3; return; end    %exit if stop requested after ICA1


%% ICA1 ARTIFACT REJECTION %%%

if ~ (strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim'))

    if rc.load <= 4 && ~(rc.stop==3)  % if not 'only load ICA1-AR data'

        clear data_all_arj data_all_decomp_ica1

        disp('Loading ARTIFREE and valid DECOMPOSITIONs from files...')

        infile_all = sc_reading(folderICA1, '*ICA1_decomp.mat');
        infile = infile_all;

        if exist('begId') && exist('endId'); infile = infile_all(begId : endId); end

        parfor  ds = 1 : length(infile)
            [~, dsname, ~] = fileparts(infile{ds});
            disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ICA1 decomposition: ', dsname, ' (DS ', num2str(ds), ')'));
            datatmp = load( infile{ds}, 'decomp_ica1' );
            data_all_decomp_ica1(ds) = datatmp.decomp_ica1;
        end

        clear data_artf

        infile=strrep(infile, '_ICA1_decomp', '_ARJ' );
        infile=strrep(infile, '4_ICA1', '3_ARTIFREE');

        parfor  ds = 1 : length(infile)
            [~, dsname, ~] = fileparts(infile{ds});
            disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ARTIFREE data: ', dsname, ' (DS ', num2str(ds), ')'));
            datatmp = load( infile{ds}, 'data_artf' );
            data_all_arj(ds) = datatmp.data_artf;
        end
        clear decomp_ica1

    end

    clear datatmp

    %%% CONSISTENCY CHECK %%%
    if (rc.load <= 4 && ~(rc.stop==3))

        if length(data_all_arj) ~= length(data_all_decomp_ica1)
            error('CONSISTENCY CHECK FAILED: size of ARTIFREE not equal to ICA1 data. ABORTING....');
        end
        for i = 1:length(data_all_decomp_ica1)
            if ~strcmp(data_all_arj(i).hdr.dsname, data_all_decomp_ica1(i).dsname)
                error('CONSISTENCY CHECK FAILED: DS names do not match between ARJ and ICA1dc data. ABORTING.')
            end
        end
    end
    %%%% END CONSIST CHECK %%%%%


    if rc.load <= 4    % include  ICA1 AR

        if ~exist('begId'); begId=1; end

        if ar.ica_ic2screen == 0
            REPORT_ICA1 = strcat('ICA1', newline, "trials removed after timecourse screening of all ICs: (z threshold = ", num2str(ar.ica_singleicZthe), ')');
        else
            REPORT_ICA1 = strcat('ICA1', newline, "trials removed after timecourse screening of the first ', num2str(ica.ICA1_IC2screen), ' ICs: (z threshold = ", num2str(ar.ica_singleicZthe), ')');
        end

        reporttxtall = [];


        for ds = 1:size(data_all_decomp_ica1,2)

            ICADATA = data_all_decomp_ica1(ds);

            disp(['DATASET: ' string(ds)]);
            dsname = ICADATA.dsname;
            if isfield(ICADATA, 'fid'); fid = ICADATA.fid; end

            currchantype = ICADATA.actualchantype;

            nc_stat(ds).dsname = dsname;
            nc_stat(ds).best_iter = ICADATA.ICA.best_iter.index;
            nc_stat(ds).total_ic = ICADATA.ICA.iter(ICADATA.ICA.best_iter.index).total_ic_number;
            nc_stat(ds).brain_ic = numel(ICADATA.ICA.iter(ICADATA.ICA.best_iter.index).brain_ic);

            %%%%%% TRIALS BASED ON VARIANCE DEVIATION
            sc_ica1_trial_rejection;

            if ~isempty(artifact_trial) % if artifacts found

                for i = 1: size(artifact_trial,2)  %converts to original sample number
                    artifact_smp_oryg(i,:) = data_all_arj(ds).sampleinfo(artifact_trial(i),:);
                end

                cfg = [];
                cfg.artfctdef.reject = 'complete';
                cfg.artfctdef.zvalue.artifact = artifact_smp_oryg;
                cfg.artfctdef.type = 'zvalue';
                data_all_ica1(ds) = ft_rejectartifact(cfg, data_all_arj(ds));
            else
                if isfield(data_all_arj, 'removed')
                    data_all_arj = rmfield(data_all_arj, 'removed');   %removed field is added the 1st AR, not needed anymore
                end
                data_all_ica1(ds) = data_all_arj(ds);
            end

            data_all_ica1(ds).hdr.actualchantype = data_all_arj(ds).hdr.actualchantype;

            % REMOVE SENSORS BASED ON TOPO DEVIATIONS

            sensors2ret=[];

            [n_IC , IC_sig_len] = size(ICADATA.ICA.best_iter.IC_sig);
            IC_mix = ICADATA.ICA.iter(ICADATA.ICA.best_iter.index).mixing;


            if ar.ica_ic2screen >0      % how many ICs to screen
                if n_IC > ar.ica_ic2screen 
                    noICscr = ar.ica_ic2screen ;
                else
                    noICscr = n_IC;
                end
            else
                noICscr = n_IC;
            end

            % chan2ica_indexes = [find(strcmp(data_all_ica1(ds).hdr.actualchantype, 'eeg'))' find(strcmp(data_all_ica1(ds).hdr.actualchantype, 'meg'))' find(strcmp(data_all_ica1(ds).hdr.actualchantype, 'mag'))' find(strcmp(data_all_ica1(ds).hdr.actualchantype, 'meggrad'))' find(strcmp(data_all_ica1(ds).hdr.actualchantype, 'megmag'))'];
            chan2ica_indexes = find(any(contains(data_all_ica1(ds).hdr.actualchantype(:), ["eeg", "meg", "mag", "grad"]), 2));            
            chan2ica_labels = data_all_ica1(ds).label(chan2ica_indexes);

            elec2retain_indexes = ( setxor(1:length(data_all_ica1(ds).hdr.actualchantype), chan2ica_indexes) )';
            elec2retain_labels =  data_all_ica1(ds).label(elec2retain_indexes);

            noMEEGch = numel(chan2ica_indexes);   %only on MEEG chans  for dev screening
            saveFolderds = fullfile(rc.analysisFolder, '4_ICA1', dsname);


            outFolder = fullfile (folderICA1, dsname, 'IC_mixing_hist');
            if ~exist(outFolder); mkdir (outFolder); end

            if rc.eeg
                elecloc_ica = sc_trim_sens(data_all_ica1(ds).label(chan2ica_indexes), data_all_ica1(ds).hdr.elec);  %provides labels of chans that survived AR and were used for ICA
            else
                elecloc_ica = sc_trim_sens(data_all_ica1(ds).label(chan2ica_indexes), data_all_ica1(ds).hdr.grad);  %provides labels of chans that survived AR and were used for ICA
            end

            sc_locfile( elecloc_ica, saveFolderds)

            for ic=1:n_IC  %parfor here!

                figure('visible','off');
                tiledlayout(1,2);

                nexttile
                histogram(zscore(IC_mix(:,ic)),100)
                set(gca,'FontSize',12)
                title(['IC ' num2str(ic)])

                nexttile
                if rc.eeg
                evalc("topoplotsc(IC_mix(:,ic), fullfile (folderICA1, dsname, 'ch_trimmed.elc'), 'nosedir', chan.ori, 'electrodes', 'labels');");
                else
                    evalc("topoplotsc(IC_mix(:,ic), fullfile (folderICA1, dsname, 'ch_trimmed.elc'), 'nosedir', chan.ori, 'electrodes', 'on');");
                end
                title(['IC ' num2str(ic)], 'color', 'k')

                if ic<10
                    print( strcat(outFolder, '/', dsname, '_bestiter', '_IC0', num2str(ic), '_hist.jpg'),'-djpeg','-r180');
                else
                    print( strcat(outFolder, '/', dsname, '_bestiter', '_IC', num2str(ic), '_hist.jpg'),'-djpeg','-r180');
                end

                close;
            end

            sens2rm = zeros(noMEEGch,1);
            for ic=1:noICscr
                rmindexes = find(abs(zscore(IC_mix(:,ic)))>ar.ica_topoZThr);   %find sensors deviating from others
                sens2rm(rmindexes)=1;
            end

            sensors2ret=find(sens2rm==0);
            sensors2rem=find(sens2rm==1);

            labelsforlog = ' (';
            for y = 1:length(sensors2rem)
                labelsforlog = [ labelsforlog, ' ', char(chan2ica_labels(sensors2rem(y))) ];
            end
            labelsforlog = [labelsforlog, ') '];

            cfg=[];
            cfg.channel=[chan2ica_labels(sensors2ret); elec2retain_labels];
            data_all_ica1(ds) = ft_selectdata(cfg, data_all_ica1(ds));
            data_all_ica1(ds).hdr.dsname = dsname;
            data_all_ica1(ds).hdr = rmfield(data_all_ica1(ds).hdr, 'actualchantype');
           

            % recreate chantype field after sens removal
            data_all_ica1(ds) = sc_fix_chantype(data_all_ica1(ds));

            for i = sort(sensors2rem, 'descend')
                currchantype(i) = [];
            end
            data_all_ica1(ds).hdr.actualchantype = currchantype;

            if isfield(ICADATA, 'fid'); data_all_ica1(ds).fid = ICADATA.fid; end

            reporttxtall = [reporttxtall newline num2str(size(sensors2rem,1)) ' removed sensors (thr=' num2str(ar.ica_topoZThr)  ')' newline labelsforlog newline newline];

            clear remfilename sens2rm sensors2rem sensors2retvec sensors2ret ICADATA noMEEGch

        end

        save(fullfile(folderICA1ar, 'ic_stat.mat'), 'nc_stat');  % save IC stat
        
        fid = fopen(fullfile(folderICA1ar, 'ICA1_AR_report.txt'),'wt');
        fprintf(fid, reporttxtall);
        fclose(fid);

        %% SAVE PRUNED DS

        for ds = 1 : size(data_all_ica1,2)
            dsname = data_all_ica1(ds).hdr.dsname;
            disp(strcat( '[', num2str( round(ds/length(infile)*100)), '%] Saving post-ICA1 ARTIFREE data: ', dsname, ' (DS ', num2str(ds), ')'));
            file_name = fullfile(folderICA1ar, [dsname '_ICA1_arj.mat']);
            data_ica1 = data_all_ica1(ds);
            save(file_name, 'data_ica1' );
        end

        clear data_ica1

        if rc.stop == 4
            disp ('STOP requested after ICA1 AR');
            return;
        end    % stops after ICA1 + ar

        clear data_all_arj data_all_decomp_ica1 artifact_smp_oryg artifact_smp_s artifact_trial artifact_trial_multiic

    end  % ICA1 AR ends here
end

%% ICA2 STAGE

clear data_all_ica1
% if ~exist('data_all_ica1')

if exist(folderICA1ar)          % reading 'infile' file
    if ~ (strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim'))
        infile_all = sc_reading(folderICA1ar, '*ICA1_arj.mat');
    else
        folderICA1ar = strrep(folderICA1ar, '5_ICA1_AR', '3_ARTIFREE');  %ICA1+AR skipped
        infile_all = sc_reading(folderICA1ar, '*_ARJ.mat');
    end
    infile = infile_all;
else
    error('There are no ICA1 data in the /5_ICA1_AR folder.');
end

if exist('begId') && exist('endId')
    infile = infile_all(begId : endId);
else
    infile = infile_all;
end

 
% ICA2 decomposition

if rc.load <= 5 && ( ~(rc.stop==3) || ~(rc.stop==4) )  % if not 'only load ICA1-AR data'
nc_all = [];

    saveFolder = fullfile (rc.analysisFolder, '6_ICA2' );

    if rc.useParallel
        poolobj = gcp('nocreate'); % just check, do not create new one.
        if isempty(poolobj)
            parpool(rc.useParallel);
        end

        parfor ds = 1:length(infile)

            %load data
            if ~(strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim'))
                [~, dsname, ~] = fileparts(infile{ds});
                % disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ICA1 data: ', dsname, ' (DS ', num2str(ds), ')'));
                disp(strcat(' [Loading ICA1 data: ', dsname, ' (DS ', num2str(ds), ')'));
                tmpdata = load( infile{ds}, 'data_ica1' );
                data_ica1 = tmpdata.data_ica1;
            else
                [~, dsname, ~] = fileparts(infile{ds});
                disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ARJ data: ', dsname, ' (DS ', num2str(ds), ')'));
                tmpdata = load( infile{ds}, 'data_artf' );
                data_ica1 = tmpdata.data_artf;
            end


            dsname = data_ica1.hdr.dsname;
            data_ica2 = sc_4_DECOMPOSITION_ICA2_fn(data_ica1, dsname, chan, rc, seg, ica, filter);
            disp( [ 'Saving ICA2 decomposed data; DS: ', num2str(ds), ' - ', dsname] );

            file_name = fullfile(saveFolder, strcat(dsname, '_ica2.mat'));
            sc_parsave_data_ica2(file_name, data_ica2);
        end

    else
        for ds = 1:length(infile)

            %load data
            if ~(strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim'))
                [~, dsname, ~] = fileparts(infile{ds});
                disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ICA1 data: ', dsname, ' (DS ', num2str(ds), ')'));
                tmpdata = load( infile{ds}, 'data_ica1' );
                data_ica1 = tmpdata.data_ica1;
            else
                [~, dsname, ~] = fileparts(infile{ds});
                disp(strcat(' [', num2str( round(ds/length(infile)*100)), '%] Loading ARJ data: ', dsname, ' (DS ', num2str(ds), ')'));
                tmpdata = load( infile{ds}, 'data_artf' );
                data_ica1 = tmpdata.data_artf;
            end

            dsname = data_ica1.hdr.dsname;
            data_ica2 = sc_4_DECOMPOSITION_ICA2_fn(data_ica1, dsname, chan, rc, seg, ica, filter);
            disp( [ 'Saving ICA2 decomposed data; DS: ', num2str(ds), ' - ', dsname] );
            file_name = fullfile(saveFolder, strcat(dsname, '_ica2.mat'));
            save(file_name, 'data_ica2', '-v7.3');
        end

    end

 
end
