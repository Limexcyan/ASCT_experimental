function sc_7_SIG_RECON(rc, design, loc, con, begId, endId)


% This script intends to reconstruct signal from source model and Time courses

%--- LOADING ICA AND SOURCE DATA ----%

sourceFolder = fullfile (rc.analysisFolder, '7_SOURCEACT' );
if isfield(rc,'iclocName')
    iclocloadFolder = fullfile (rc.expFolder, rc.iclocName,  '7_SOURCEACT', 'icloc');
else
    iclocloadFolder = fullfile (sourceFolder, 'icloc' );
end

if isfield(rc,'iclocName')
    icaloadFolder = fullfile (rc.expFolder, rc.iclocName,  '6_ICA2');
else
    icaloadFolder = fullfile (rc.analysisFolder, '6_ICA2' );
end

trigger_log = fopen(fullfile(sourceFolder,'Trigger_log.txt'),'wt');
flag = 0;

if exist(icaloadFolder)
    %Reading ICA data
    infile_all = sc_reading(icaloadFolder, '*_ica2.mat');
elseif ~exist(icaloadFolder)
    error( ['There are no ICA2 data in the /6_ICA2 folder'] );
elseif ~exist(iclocloadFolder)
    error( ['There are no ICLOC data in the ', iclocloadFolder, ' folder'] );
end

if begId > 0  && endId > 0
    infile = infile_all(begId : endId);
else
    infile = infile_all;
end

if ~exist(fullfile(sourceFolder,'trigger_complete.mat'),'file')
    for i = 1:length(infile_all)
        [~, trigger_complete_list{i,1},~] = fileparts(infile_all{i});
        trigger_complete_list{i,1} = strrep(trigger_complete_list{i,1}, '_ica2', '');
    end
else
    trigger_complete_list = load(fullfile(sourceFolder,'trigger_complete.mat'),'trigger_complete_list');
    trigger_complete_list = trigger_complete_list.trigger_complete_list;
end

infile_icloc_all =  sc_reading(iclocloadFolder, '*icloc.mat');
if begId > 0  && endId > 0
    infile_icloc = infile_icloc_all(begId : endId);
else
    infile_icloc = infile_icloc_all;
end

if rc.useParallel>0
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        parpool(rc.useParallel);
    else
        if poolobj.NumWorkers ~= rc.useParallel
            delete(poolobj);
            parpool(rc.useParallel);
        end
    end
end

%Loading ICA and ICLOC data

parfor  ds = 1 : length(infile)
    load_file_ica2 = infile{ds};
    load_file_icloc = infile_icloc{ds};

    %consistency check
    [~, fica, ~] = fileparts(load_file_ica2);
    [~, floc, ~] = fileparts(load_file_icloc);
    if ~strcmp(fica(design.idPosStart:design.idPosEnd), floc(design.idPosStart:design.idPosEnd))
        cprintf('*red',   '!!!! FILE MISMATCH. CHECK ICA2 and ICLOC DIRECTORIES FOR MISMATCHED CONTENT !!!!\n');
        error('execution terminated due to file mismatch');
    end

    dsname = strrep(fica, '_ica2', '');
    disp([' [' num2str( round(100*ds/length(infile) )) '%] Loading ICA2 and source DS: ', dsname] );
    data_ica2 = load(load_file_ica2,'data_ica2');
    data_all_ica2{ds} = data_ica2;
    data_icloc = load(load_file_icloc,'data_icloc');
    data_all_sourceloc{ds} = data_icloc;

end

%--- CONSTRUCTING NEW IC_SIG ---%

% trial_count = table;
logFile = fopen(fullfile(sourceFolder, 'removed_log.txt'), 'a');

for DC = 1:length(design.DC)
    disp('-----------------------------')
    disp(fprintf('Processing data for DC: %d',DC))

    if ~isfolder(fullfile(sourceFolder,sprintf('DC%d',DC)))
        mkdir(sourceFolder,sprintf('DC%d',DC));
    end


    %%

    for ds = 1:length(infile)

        % Getting New Signal Time Course: %%%

        progressdc = 100*(DC-1)/length(design.DC);
        progressds = 100*ds/length(infile) / length(design.DC);

        [~, dsname, ~] = fileparts(infile{ds});
        dsname = strrep(dsname, '_ica2', '');
        mriname = dsname(design.idPosStart :design.idPosEnd);

        trial_cnt(ds,1) = {ds};  % table with counf of trials for each DC
        trial_cnt(ds,2) = {dsname};


        abortFlag = 0; %Flag for not saving in a given DC folder


        %Pre-load ICA: %MDS
        data_ica2 = data_all_ica2{ds}.data_ica2;
        ICA = data_ica2.ICA.iter(data_ica2.ICA.best_iter.index);
        trial_index = [];

        if ~isfield(design.DC(DC), 'GRP'); design.DC(DC).GRP = []; end
        if ~isfield(design.DC(DC), 'SES'); design.DC(DC).SES = []; end


        %Whether group checks out
        if isfield(design,'grpPosStart') && isfield(design,'grpPosEnd')
            dsGroup = dsname(design.grpPosStart:design.grpPosEnd);

            if ~isempty(design.DC(DC).GRP)
                if isempty(find(strcmp(design.DC(DC).GRP,dsGroup)))
                    abortFlag = 1; %if we cannot find dsGroup in DC groups it means that this DS is not valid for given DC

                    disp(['       (DC',char(string(DC)),') Removing: DS', num2str(ds), ' - ', dsname, ' - ', ' Cannot find ds Groups in DC groups: '] );                        fprintf(logFile, 'DS%d NOT RECONSTRUCTED!- %s - Cannot find ds Groups in DC groups \n', ds, dsname);
                end
            end
        end

        %Whether session checks out
        if isfield(design,'sesPosStart') && isfield(design,'sesPosEnd')
            dsSession = dsname(design.sesPosStart:design.sesPosEnd);

            if ~isempty(design.DC(DC).SES)
                if isempty(find(strcmp(design.DC(DC).SES,dsSession)))
                    abortFlag = 1; %if we cannot find dsGroup in DC groups it means that this DS is not valid for given DC

                    disp(['       (DC',char(string(DC)),') Removing: DS', num2str(ds), ' - ', dsname, ' - ', ' Cannot find ds Sessions in DC groups '] );
                    fprintf(logFile, 'DS%d NOT RECONSTRUCTED!- %s - Cannot find ds Sessions in DC groups \n', ds, dsname);
                end
            end
        end

        % Whether ICA NUM checs out - MD
        if ICA.brain_ic_number < length(loc.ROI)

            abortFlag = 1;

            disp(['       (DC',char(string(DC)),') Removing: DS', num2str(ds), ' - ', dsname, ' - ', 'Due to too little brain components: ',char(string(ICA.brain_ic_number))] );
            fprintf(logFile, 'DS%d NOT RECONSTRUCTED!- %s - Too few brain components: %d\n', ds, dsname, ICA.brain_ic_number);
        end

        if ~abortFlag

            disp([' [' num2str(round(progressdc+progressds)) '%] Getting signals for: DS', num2str(ds), ' - ', dsname, ' - ', infile{ds}] );

            %Getting ICA data and different subjects data
            % data_ica2 = data_all_ica2{ds}.data_ica2;
            % ICA = data_ica2.ICA.iter(data_ica2.ICA.best_iter.index);

            % ORIG topographies normalisation from sc_sourceLocalize_fmn
            % for i = 1:size(mixing, 2)
            %     val(i) = 0.01*max(abs(mixing(:, i)));
            %     mixing(:, i) = mixing(:, i)/val(i);
            % end

            for j = ICA.brain_ic
                ICA.icscaling(j) = 0.01*max(abs(ICA.mixing(:, j)));
            end

            data_ica2.full_source_time_course = zeros(length(loc.ROI),size(ICA.IC_sig,2),3); %initial full time course size

            %%% Loading HEADMODEL %%%%
            clear temp_src_pos

            if isempty(rc.mriRawFolder) %Template
                temp_src_pos =  data_all_sourceloc{ds}.data_icloc(1).pos;
                % temp_src_pos(~[data_all_sourceloc{ds}.data_icloc(1).inside],:) = temp_src_pos(~[data_all_sourceloc{ds}.data_icloc(1).inside]).*[1000, 1000, 1000];

            else %Individual headmodel

                if ~strcmp(rc.dataFormat, 'itab-sim') %fixme
                    load ( fullfile(rc.expFolder, rc.mriRawFolder, mriname, 'SC', 'sourcemodel_indiv_acpc.mat'));
                else
                    load ('/mnt/devv/Exp/SIM/ITAB-sim-scan/0_mri/mrtlne88_0101/SC/sourcemodel_indiv_acpc.mat');
                end

                if ~isfield(loc, 'indiv_coords')    % use indiv coordinates - no warping to MNI required

                    tmpdata = load('template_grid_MNI_5mm.mat');
                    template_grid_MNI = tmpdata.template_grid_MNI;
                    clear tmpdata

                    %%%Loading mri acpc models
                    template_grid_MNI = ft_convert_units(template_grid_MNI, 'mm');
                    temp_mni_pos = template_grid_MNI.pos;


                    scpath = fullfile(rc.expFolder, rc.mriRawFolder, mriname, 'SC');
                    if strcmp(rc.dataFormat, 'itab-sim') %fixme
                        scpath = '/mnt/devv/Exp/SIM/ITAB-sim-scan/0_mri/mrtlne88_0101/SC/';
                    end


                    if exist(fullfile(scpath, 'mri_acpc_seg.mat'))
                        mri_acpc_seg = ft_read_mri(fullfile(scpath, 'mri_acpc_seg.mat'));
                    else
                        mri_acpc = ft_read_mri(fullfile(scpath, 'mri_acpc.mat'));
                        cfg        = [];
                        cfg.output = 'brain';
                        mri_acpc_seg        = ft_volumesegment(cfg, mri_acpc);
                        mri_acpc_seg.anatomy = mri_acpc.anatomy;
                        save (fullfile(scpath, 'mri_acpc_seg.mat'), 'mri_acpc_seg');
                    end


                    %%% warping template MNI grid to indiv scan
                    cfg           = [];
                    cfg.warpmni   = 'yes';
                    cfg.template  = template_grid_MNI;
                    cfg.nonlinear = 'yes';
                    cfg.mri       = mri_acpc_seg;
                    cfg.unit      ='mm';
                    cfg.inwardshift = -20;
                    template_grid_2ind = ft_prepare_sourcemodel(cfg);

                    % check warping
                    % figure; hold on;
                    % ft_plot_mesh(template_grid_MNI.pos(template_grid_MNI.inside,:), 'vertexcolor', 'green');
                    % ft_plot_mesh(template_grid_2ind.pos(template_grid_2ind.inside,:));
                    % ft_plot_headmodel(headmodel_indiv_acpc, 'facecolor', 'skin', 'edgecolor', 'brain', 'facealpha', 0.4);

                    %%% Loading individual ACPC
                    %Loading and adjusting individual model, so it has high activations on NoN-Brain Points - such method allows us to quickly discard non-brain dipoles  %FIXME - should be inside=0 preserved?

                end
                temp_src_pos = sourcemodel_indiv_acpc.pos;
                temp_src_pos(~[sourcemodel_indiv_acpc.inside],:) =temp_src_pos(~[sourcemodel_indiv_acpc.inside]).*[1000, 1000, 1000];
            end

            data_sigroi = struct();

            sig_uncut = zeros(length(loc.ROI), size(ICA.IC_sig,2));  %mw

            for i = 1:length(loc.ROI) % For each ROI
                sig = zeros(size(ICA.IC_sig,2),3); %initial signal matrix size

                %%% Rounding to closest Dipole

                if isempty(rc.mriRawFolder) % template sourcemodel
                    ROI_pos(i,:) = loc.ROI(i).pos;

                else  %individual sourcemodel

                    if ~isfield(loc, 'indiv_coords')   % ROIs defined in MNOI space are warped to indiv acpc space

                        %%%%%finding new ROI index %%%%%
                        %%% finding distances of standard MNI grid
                        temp_norm_mat = sqrt((temp_mni_pos(:,1)-loc.ROI(i).pos(1)).^2+ (temp_mni_pos(:,2)-loc.ROI(i).pos(2)).^2+(temp_mni_pos(:,3)-loc.ROI(i).pos(3)).^2);
                        [mins,min_ind]= min(temp_norm_mat);

                        %%% OUR NEW ROI:
                        ROI_pos(i,:) = template_grid_2ind.pos(min_ind,:);

                    else  % ROIs defined in indiv space. warping to MNI disabled
                        ROI_pos(i,:) = loc.ROI(i).pos;

                    end
                end

                %computing distance between temp_src_pos and our ROIs
                temp_norm_mat = sqrt((temp_src_pos(:,1)-ROI_pos(i,1)).^2+ (temp_src_pos(:,2)-ROI_pos(i,2)).^2+(temp_src_pos(:,3)-ROI_pos(i,3)).^2);

                %sortedNorm = sort(temp_norm_mat)
                [mins,min_ind]= min(temp_norm_mat);

                disp(['ROI', mat2str(i), ': ', loc.ROI(i).name, '; index: ' mat2str(min_ind)])

                clear temp_neigh_array

                X_matrix_temp = [];
                Y_matrix_temp = [];
                Z_matrix_temp = [];

                xyz = temp_src_pos(min_ind,:);

                %%% Selecting the closest dipole that is inside the skull
                %getting current source model and finidng index of loc.ROI
                curr_data =   data_all_sourceloc{ds}.data_icloc(1);     %all data_icloc corresponding to the current Brain_IC
                index_num(i) = find((curr_data(1).pos(:,1) == xyz(1)) & (curr_data(1).pos(:,2) == xyz(2)) & (curr_data(1).pos(:,3) == xyz(3)));
                curr_data = curr_data(1).avg.mom(index_num(i))'; %only these, where the closest value exists

                if  isempty(curr_data{1})
                    error('ROI outside brain boundaries')
                end
                for j = ICA.brain_ic
                    curr_data =   data_all_sourceloc{ds}.data_icloc([data_all_sourceloc{ds}.data_icloc.time] == j);     %wszystkie data_icloc odpowiadające obecnemu Brain_IC
                    curr_data = curr_data(1).avg.mom(index_num(i))'; %tylko te, gdzie mamy naszą najbliższą wartość

                    %Getting coordinates of loc.ROI
                    new_mom_x = curr_data{1}(1);
                    new_mom_y = curr_data{1}(2);
                    new_mom_z = curr_data{1}(3);

                    %calculating new Signal matrix in respecrive coordinates
                    Primary_signal = ICA.icscaling(j)*ICA.IC_sig(j,:);
                    X_matrix_temp(j,:) = new_mom_x*Primary_signal;
                    Y_matrix_temp(j,:) = new_mom_y*Primary_signal;
                    Z_matrix_temp(j,:) = new_mom_z*Primary_signal;
                end

                %sumarising over different IC and saving in sig matrix
                sig(:,1) = sum(X_matrix_temp,1)';
                sig(:,2) = sum(Y_matrix_temp,1)';
                sig(:,3) = sum(Z_matrix_temp,1)';


                [~,PCA_components ]= pca(sig);   % retaining the first PCA
                signal_norm = PCA_components(:,1)';

                sig_uncut(i,:)=signal_norm;  % check LC

            end

     %% Getting Trials UNC

            for i = 1:length(loc.ROI) 


                fprintf('...Splitting into trials for: %s  [uncorrected]\n',loc.ROI(i).name);

                % Getting trial matrix Size: 

                if exist('event')
                    continue
                    Events = event;
                else
                    Events = data_ica2.event;
                    events_len = length(design.COND.trig);
                end

                trial_length = size(data_ica2.trial{1},2); %trial length is inferred from the data_ica2 structure
                matrix_signal_norm = reshape(sig_uncut(i,:), [trial_length,size(sig_uncut(i,:),2)/trial_length]); %transforming vector of normed signal, trial by trial
                matrix_signal_norm = matrix_signal_norm'; %flipping, so rows are trials and columns are timestamps

                % trial data into separate matrices %%%

                % Decimating if specified - perform decimation, else transform nothing
                if con.decimate ==0
                    matrix_signal_norm_dec = matrix_signal_norm;
                else
                    matrix_signal_norm_dec = zeros(size(matrix_signal_norm,1),int32(size(matrix_signal_norm,2)/con.decimate));
                    for j = 1:size(matrix_signal_norm,1)
                        matrix_signal_norm_dec(j,:) = decimate(matrix_signal_norm(j,:),con.decimate);
                    end
                end

                %%%-- Jointly get all accepted conditions in given DC
                cond = [];
                cond.name = '';
                iterCondition = 1;
                acceptedConditions = design.DC(DC).COND; %design.DC has every condition that should be included jointly in analysis
                if isempty(acceptedConditions)  % When Conditons are empty, it means all conditions!
                    acceptedConditions = design.COND.name;
                end

                %Iterating through accepted Conditions
                for dcs = 1:length(acceptedConditions)
                    indfind = find(strcmp(design.COND.name,string(acceptedConditions(dcs)))); % find numerical location of given condition
                    if length(acceptedConditions)>1
                        %Combine the name of all conditions - to emphasize the joint aspect
                        cond.name = strcat(cond.name,'__' ,design.COND.name{indfind});
                    else
                        cond.name = design.COND.name{indfind}; %if there is only one condition - use its name instead
                    end
                    for alt = 1:length(design.COND.trig{indfind})
                        cond.trig{iterCondition} = design.COND.trig{indfind}{alt}; %for every valid conditon, get the first Trigger
                        % it seems it does not affect computation but be wary
                        iterCondition = iterCondition+1;
                    end
                end
                if length(acceptedConditions)>1
                    cond.name = cond.name(3:end); %comsetics: remove first __ from name of conditions if there are more than one
                end
                trial_index = [];
                signal_slice =[];

                %%%-- Get trial Indexes
                for k = 1:length(cond.trig) %For every condition in given DC
                    trial_index =  [trial_index; find(data_ica2.trialinfo(:,1)==cond.trig{k})]; % add trial indexes from all accepted contitions
                end

                try % Create trigger log if in DS data there are no specific trigger

                    signal_slice_minor = matrix_signal_norm_dec(trial_index,:); %Take only trials where sepcified conditions are present
                    signal_slice = [signal_slice; signal_slice_minor]; %remnant -

                    clear signal_slice_new
                catch
                    warning('Warning! Trigger %s not present in %s. Moving on',num2str(temp_name),dsname);
                    if flag == 0
                        fprintf(trigger_log, 'Trigger %s not present in %s \n',num2str(temp_name),dsname);
                        flag = 1;
                    end
                end

                trial_signal = reshape(signal_slice',[1,size(signal_slice,1)*size(signal_slice,2)]); % FIXME!!! MD (????)
                %It is necessery as we are dealing with single dimension of a series

                %%%-- Creating current data_sigroi structure
                cond_name = cond.name;
                cond_name = strrep(cond_name,'-','_');
                data_sigroi.(cond_name).signal(i,:) = trial_signal; %this structure is a remnant - in order to easily modify later should the need arise
                %There will always be only one condition, of course for every ROI in single matrix


                data_sigroi.(cond_name).trialen = size(signal_slice,2);%size of a matrix
                if con.decimate == 0 %sampling freq whether ther was are was not a decimation procedure
                    data_sigroi.(cond_name).sampling_rate = data_ica2.fsample;
                else
                    data_sigroi.(cond_name).sampling_rate = data_ica2.fsample/con.decimate;
                end

            end

            data_sigroi_unc = data_sigroi;

            clear data_sigroi

 %% Getting Trials LEAKAGE CORR

            if con.lc ==1

            %%%-- Leakage Correction
            % if con.lc ==1 && ~isempty(data_sigroi.(cond_name).signal)
                % temp_cond = fieldnames(data_sigroi);
                % for j = 1:length(temp_cond)
                    % temp_sig = data_sigroi.(temp_cond{j}).signal;
            sig_uncut_lc = ROInets.closest_orthogonal_matrix(sig_uncut');
            sig_uncut_lc = sig_uncut_lc'; 
                    % data_sigroi.(temp_cond{j}).signal =temp_ort';
                % end
            % end


            for i = 1:length(loc.ROI) 

                fprintf('...Splitting into trials for: %s [leakage correction]\n',loc.ROI(i).name);

                %%%----------------------------%%%
                %%% Getting trial matrix Size: %%%

                if exist('event')
                    continue
                    Events = event;
                else
                    Events = data_ica2.event;
                    events_len = length(design.COND.trig);
                end

                trial_length = size(data_ica2.trial{1},2); %trial length is inferred from the data_ica2 structure
                matrix_signal_norm = reshape(sig_uncut_lc(i,:), [trial_length,size(sig_uncut_lc(i,:),2)/trial_length]); %transforming vector of normed signal, trial by trial
                matrix_signal_norm = matrix_signal_norm'; %flipping, so rows are trials and columns are timestamps

                % trial data into separate matrices %%%

                % Decimating if specified - perform decimation, else transform nothing
                if con.decimate ==0
                    matrix_signal_norm_dec = matrix_signal_norm;
                else
                    matrix_signal_norm_dec = zeros(size(matrix_signal_norm,1),int32(size(matrix_signal_norm,2)/con.decimate));
                    for j = 1:size(matrix_signal_norm,1)
                        matrix_signal_norm_dec(j,:) = decimate(matrix_signal_norm(j,:),con.decimate);
                    end
                end

                %%%-- Jointly get all accepted conditions in given DC
                cond = [];
                cond.name = '';
                iterCondition = 1;
                acceptedConditions = design.DC(DC).COND; %design.DC has every condition that should be included jointly in analysis
                if isempty(acceptedConditions)  % When Conditons are empty, it means all conditions!
                    acceptedConditions = design.COND.name;
                end

                %Iterating through accepted Conditions
                for dcs = 1:length(acceptedConditions)
                    indfind = find(strcmp(design.COND.name,string(acceptedConditions(dcs)))); % find numerical location of given condition
                    if length(acceptedConditions)>1
                        %Combine the name of all conditions - to emphasize the joint aspect
                        cond.name = strcat(cond.name,'__' ,design.COND.name{indfind});
                    else
                        cond.name = design.COND.name{indfind}; %if there is only one condition - use its name instead
                    end
                    for alt = 1:length(design.COND.trig{indfind})
                        cond.trig{iterCondition} = design.COND.trig{indfind}{alt}; %for every valid conditon, get the first Trigger
                        % it seems it does not affect computation but be wary
                        iterCondition = iterCondition+1;
                    end
                end
                if length(acceptedConditions)>1
                    cond.name = cond.name(3:end); %comsetics: remove first __ from name of conditions if there are more than one
                end
                trial_index = [];
                signal_slice =[];

                %%%-- Get trial Indexes
                for k = 1:length(cond.trig) %For every condition in given DC
                    trial_index =  [trial_index; find(data_ica2.trialinfo(:,1)==cond.trig{k})]; % add trial indexes from all accepted contitions
                end

                try % Create trigger log if in DS data there are no specific trigger

                    signal_slice_minor = matrix_signal_norm_dec(trial_index,:); %Take only trials where sepcified conditions are present
                    signal_slice = [signal_slice; signal_slice_minor]; %remnant -

                    clear signal_slice_new
                catch
                    warning('Warning! Trigger %s not present in %s. Moving on',num2str(temp_name),dsname);
                    if flag == 0
                        fprintf(trigger_log, 'Trigger %s not present in %s \n',num2str(temp_name),dsname);
                        flag = 1;
                    end
                end

                trial_signal = reshape(signal_slice',[1,size(signal_slice,1)*size(signal_slice,2)]); % FIXME!!! MD (????)
                %It is necessery as we are dealing with single dimension of a series

                %%%-- Creating current data_sigroi structure
                cond_name = cond.name;
                cond_name = strrep(cond_name,'-','_');
                data_sigroi.(cond_name).signal(i,:) = trial_signal; %this structure is a remnant - in order to easily modify later should the need arise
                %There will always be only one condition, of course for every ROI in single matrix


                data_sigroi.(cond_name).trialen = size(signal_slice,2);%size of a matrix
                if con.decimate == 0 %sampling freq whether ther was are was not a decimation procedure
                    data_sigroi.(cond_name).sampling_rate = data_ica2.fsample;
                else
                    data_sigroi.(cond_name).sampling_rate = data_ica2.fsample/con.decimate;
                end

            end

            % data_sigroi_lc = data_sigroi;

            end

            if isempty(data_sigroi_unc.(cond_name).signal)
                abortFlag =1;
            end
        end

        %% Saving %%%




        %  trial no log
        if abortFlag
            num_trial = 0;
        else
            num_trial = length(trial_index);
        end


        trial_cnt(ds, DC+2) = {num_trial};
        if isempty(trial_index)
            disp('!!! no appropriate triggers found for the defined DC');
        end
        %Create triggerlist
        ind = find(strcmp({trigger_complete_list{:,1}},dsname));
        trigger_complete_list{ind,DC+1} = num_trial;


        if ~abortFlag
            %save simulated ROIs if we are using simulation
            if isfield(loc, 'simROI')
                temp_loc_ROI = loc.ROI;
                save(fullfile(fullfile(sourceFolder,sprintf('DC%d',DC)),strcat(dsname, '_temp_loc_ROI.mat')),'temp_loc_ROI', '-v6');
            end
            disp('...Saving');

            %Save sigroi without leakage correction
            savelc = 1; % FIXME
            if savelc
                file_name2 = fullfile(fullfile(sourceFolder,sprintf('DC%d',DC)),'unc');
                if ~exist(fullfile(fullfile(sourceFolder,sprintf('DC%d',DC)),'unc'))
                    mkdir(fullfile(sourceFolder,sprintf('DC%d',DC)),'unc');
                end
                save(fullfile(file_name2,strcat(dsname, '_sigroi_unc.mat')),'data_sigroi_unc', '-v6');
            end

            %Save sigroi with leakage correction
            if con.lc ==1
                file_name =fullfile(sourceFolder,sprintf('DC%d',DC),'lc');
                if ~exist(fullfile(fullfile(sourceFolder,sprintf('DC%d',DC)),'lc'))
                    mkdir(fullfile(sourceFolder,sprintf('DC%d',DC)),'lc');
                end
                save(fullfile(file_name,strcat(dsname, '_sigroi_lc.mat')),'data_sigroi', '-v6');

            end

            clear data_sigroi data_sigroi_unc

        end


    end
end
fclose(logFile);

tvarnames = {'ds', 'id'};
for i = 1:length(design.DC)
    tvarnames = [tvarnames strcat('DC', num2str(i))];
end

trial_count = array2table(trial_cnt, 'VariableNames', tvarnames);
writetable(trial_count, fullfile(sourceFolder, 'trial_count.xls'),'WriteRowNames',true, 'WriteMode', 'overwrite');

%Saving triggerlog
%save(fullfile(sourceFolder,'trigger_complete.mat'),'trigger_complete_list', '-v6')
% try
%     fclose(trigger_log);
% catch
%     disp("All triggers are present in the analysis! No need to list removed triggers!");
% end
end
