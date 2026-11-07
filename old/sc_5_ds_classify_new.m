function [classif_table_iters,ica2stat] = sc_5_ds_classify_new(infile, ds, rc, chan, ica, seg, currentFolder, progressfile,Data_volume, Mode)

    % New Function for classyfing ICA components for brain and not brain
    % components and saves in corresponding data_ica2 structure 

    %Input:
    % infile        - file lists in cell array
    % ds            - current Data Subject
    % rc            - structure containing parameters
    % chan          - structure containing channel info
    % ica           - structure containing ICA data 
    % seg           - structure containing study info and trial segmentations
    % currentFolder - folder in which we have our data
    % progressfile  - file with data 
    % DataVolume    - flag controlling amount of ICA iterations being preprocessed
    % Mode          - Whether we classify, label or validate our dataset


    %%% Load Model info and ica stat
    classif_table_iters = {};
    if isfield(ica, 'ICA2_classModel')
        if ~strcmp(ica.ICA2_classModel(end-3:end), '.mat')
            ica.ICA2_classModel = strcat(ica.ICA2_classModel,'.mat');
        end
          Mods  =load (ica.ICA2_classModel);
          convModel = Mods.convModel;    % Convolutional Model
          featModel = Mods.featModel;    % Feature model
          normStruct = Mods.normStruct;  %Structure having the mean and std values for each critical Features - for consistent scaling 
          weightsInfo = Mods.mWeights;
    else
        warning('Model for classification of components not specifiied. Trying to fit the existing one, check the classification results !!')
    end
    
    
    %%% load file 
    [~, dsname, ~] = fileparts(infile{ds}); % File parts return path, name and extension, we want only name
    disp(strcat(' [', num2str( round(100*ds/length(infile) )), '%] Loading artifree ICA2 decomposed DS: ', dsname, ' - ', infile{ds}));
    load_file = infile{ds};
    load(load_file);     % It reads biosemi EEG system : 70 channels 64 eeg, 4 electric, 2 ref

    

    %Extracting data from all_ica for specific subject: ICA, events, frequency, ica_parameters
    ICA = data_ica2.ICA;
    trial = data_ica2.trial;
    event = data_ica2.event;
    Fsnew = data_ica2.fsample;
    ncond = size(event,2);
    dsname = data_ica2.hdr.dsname;
    ica_par = data_ica2.ica_par;

    if isfield(rc,'test')
        if rc.test
            saveFolderds = fullfile(rc.analysisFolder, '6_ICA2_classified'); %% !!! FOR TESTING PURPOSES
        else
            saveFolderds = fullfile(rc.analysisFolder, '6_ICA2'); %% !!! FOR TESTING PURPOSES
        end
    else
        saveFolderds = fullfile(rc.analysisFolder, '6_ICA2'); %% !!! FOR TESTING PURPOSES
    end

    disp(sprintf(strcat('\nClassifying ICA components; DS: ', dsname)));


    %Getting electric channels info and trimmed Channels .elc file
    n_elec = length(chan.elec); %number of electric channels
    chan2icanr = [find(strcmp(data_ica2.hdr.actualchantype, 'eeg'))' find(strcmp(data_ica2.hdr.actualchantype, 'mag'))' find(strcmp(data_ica2.hdr.actualchantype, 'meg'))' find(strcmp(data_ica2.hdr.actualchantype, 'meggrad'))' find(strcmp(data_ica2.hdr.actualchantype, 'megmag'))'];
    chan2ica = data_ica2.label(chan2icanr);
    if rc.eeg
        elecloc_ica = sc_trim_sens(chan2ica, data_ica2.hdr.elec);
    else
        elecloc_ica = sc_trim_sens(chan2ica, data_ica2.hdr.grad);  %provides labels of chans that survived AR and were used for ICA
    end
    if exist(fullfile(saveFolderds,dsname))==0; mkdir (fullfile(saveFolderds,dsname)); end
    sc_locfile( elecloc_ica, fullfile(saveFolderds,dsname)); %trims elc file according to actual no of channels

    trim_folder = fullfile (saveFolderds, dsname); % Whete the trim folder is located 


    %%% Get Iterations that interests you the most (Either All or Best) 
    if strcmp(Data_volume, 'all')     % All Iterations
        num_iters = size(ICA.iter,2);
        I = (1:size(ICA.iter,2));
    elseif strcmp(Data_volume,'best') % Only Best N iterations (Hardcoded 5) 
        [~,I] = sort([ICA.iter.total_ic_number],'descend'); %based on IC number
        I = I(1:5);
        num_iters = 5;
    else                              % First iter only (For testing Purposes) 
        num_iters =1;
    end



    %%% Going Through ICA's iterations
    for indeks = 1:num_iters

        %%% Clear previous variables:
        clear featureData maxPeak maxProm maxWidth peaksNum meanPLoc

        fprintf('ICA iteration no. %d',indeks);
        disp('')
        disp('    IC identification ...');

        %%% If Simulation is active  create a Sham data_ica2

            if isfield(rc.sim, 'setallICasbrain')
                if rc.sim.setallICasbrain % When this parameter is ON, omit classification by model

                    if rc.sim.setallICasbrain   %settinga all brain as IC - for sim purposes only!!
                        for it =  length(data_ica2.ICA.iter)
                            nofic(it)= data_ica2.ICA.iter.total_ic_number;
                        end
                        [icnobestiter,bestindex] = max(nofic);
                        data_ica2.ICA.best_iter.index = bestindex;
                        data_ica2.ICA.iter(bestindex).brain_ic = 1:icnobestiter;
                        data_ica2.ICA.iter(bestindex).brain_ic_number = data_ica2.ICA.iter(bestindex).total_ic_number;
                    end

                    continue
                end
            end


        disp([' [' num2str( round(100*((ds-1)/length(infile) + indeks/num_iters/length(infile)))) '%] Classification progress: DS: ', dsname] );

        if strcmp(Data_volume, 'bestiter') % if only analysing Best Iter 
            indeks = ICA.best_iter.index;
        elseif strcmp(Data_volume,'best') % 5 best ICAs
            indeks = I(indeks); 
        end
        


        %%% Current Iter Parameters
        [nIC, sigSizeIC] = size(ICA.iter(indeks).IC_sig); % Getting Size of ICA signal for a current iteration and number of comps
        trialLength  = size(data_ica2.trial{1},2); % Length of a trial 

        if isempty(ICA.iter(indeks).unmixing) % If No iC is here - continue
            continue
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Supplement Features %%% -- ADDITION!!!

        % here we compute additional features that had not been computed in SC_4


        % Finds the number of Peaks in data 
        peaks_per_min = zeros(1,size(ICA.iter(indeks).IC_sig,1));
        %%% Iterate thrtough current components
        parfor comps = 1:size(ICA.iter(indeks).IC_sig,1)
            sig_temp =ICA.iter(indeks).IC_sig(comps,:);

            % 1. Number of Eye peaks 
            num_peaks_in_window = sc_eyePeaks(sig_temp,data_ica2.hdr.Fs);
            peaks_per_min(comps) = sum(num_peaks_in_window)/(length(data_ica2.ica_par.time_ica)/(60*data_ica2.hdr.Fs));

            % 2. Fooof Features
            [pk, loc, wid, prom] = sc_foofEstim(sig_temp,trialLength,data_ica2.hdr.Fs); % WARNING - trialLength should possibly be changed for something different - like stable 2s window to get both high and lower freq
            peaksNum(comps) = length(pk);
            meanPLoc(comps) = mean(loc);
            if ~isempty(pk)
                maxPeak(comps)   =  max(pk);
                maxProm(comps)   =  max(prom);
                maxWidth(comps)  =  max(wid);
            else
                maxPeak(comps)   =  nan;
                maxProm(comps)   =  nan;
                maxWidth(comps)  =  nan;
            end
        end
        %%%%%%%%%%%%%%%%
        if ~strcmp(Mode,'label') % For Review and Classification Modes

                        %%%%% FEATURE LOADING %%%%%%%%
            disp('    Extracting signal features for brain/nonbrain differentiation...');
    
            featureData.elc_pow_corr = ICA.iter(indeks).elc_power_correlation;    % Correlation of Power between IC and ELC channels 
            featureData.elc_sig_corr = ICA.iter(indeks).elc_signal_correlation;   % Correlation of Signal between IC and ELC channels 
            featureData.elc_spr_corr = ICA.iter(indeks).elc_spectrum_correlation; % Correlation of Spectrum between IC and ELC channels 
            featureData.eye_peaks    = peaks_per_min;                             % Peaks per minute for a given component on a IC signal 
            featureData.kurt         = ICA.iter(indeks).time_kurtosis;            % Kurtosis of a IC signal 
            featureData.spc_flat     = ICA.iter(indeks).spectrum_flat;            % Flatness of Spectrum 
            featureData.spc_onef     = ICA.iter(indeks).spectrum_one_over_f;      % 1/x fit to power spectrum ( faulty proxy for Fooof)
            featureData.spc_phgt     = maxPeak;                                   % maximum Peak after Fooof aperiodic subtraction
            featureData.spc_ploc     = meanPLoc;                                  % mean location of aperiodic peak
            featureData.spc_pnum     = peaksNum;                                  % peaks number getting over threshold 
            featureData.spc_pprm     = maxProm;                                   % maximum promkinence of peak (gow high it is from the neighbouring signal)
            featureData.spc_pwdt     = maxWidth;                                  % maximum peak width 
    
            %%% Getting target vector - if there was no previous classification it will be all zeros! 
            temp_Y_vec = 1:ICA.iter(indeks).total_ic_number;
            Y = ismember(temp_Y_vec,ICA.iter(indeks).brain_ic);                   % our target vector
    
    
            %%% Normalization of feature Data: 
            featureMatrix = cell2mat(struct2cell(featureData))';
            normalisedFeatureMatrix = (featureMatrix - normStruct.mean') ./ normStruct.std'; %%% standarized X inputs! 
            Masks = ~isnan(normalisedFeatureMatrix);        % 1 = present, 0 = missing
            normalisedFeatureMatrix(~Masks) = 0;    % zero-impute AFTER scaling
    
            %%% adding masking features (pointing whether the variable is present or not - doubling feature count
            featureMatrix_Complete = array2table([normalisedFeatureMatrix, double(Masks)],'VariableNames',[fieldnames(featureData),fieldnames(featureData)+"_mask"]); 

            %%% Adding flags for datasets whether it is data with no EOGSor if it is resting states
            featureMatrix_Complete.isNOEOG = repmat(double(isfield(chan,"addMockEOG")),size(featureMatrix_Complete,1),1); % Flag for having no EOG
            featureMatrix_Complete.isRS = repmat(double(strcmp(seg.studyType , 'RS')),size(featureMatrix_Complete,1),1); % Flag for being RS
    
            %%%%% IMAGE LOADING %%%%%%%%
            disp('    Extracting image variables...');
            
            ims = zeros(convModel.Params.imageDim(1), convModel.Params.imageDim(2),convModel.Params.imageDim(3),size(featureMatrix_Complete,1)); %3,nIC); %Dummy images list
            parfor k = 1:size(ICA.iter(indeks).mixing,2)  
                
                fig2 = figure();
                set(fig2,'visible','off', 'Color',[1 1 1]);
                set(gcf, 'InvertHardCopy', 'off');  % do NOT auto-adjust background
                axes('Color',[1 1 1]);              % axis background MUST ALSO be white
                topoplot(ICA.iter(indeks).mixing(:,k), fullfile(char(trim_folder),'ch_trimmed.elc'), 'nosedir', chan.ori,'verbose','off','style' , 'map','headrad' ,0, 'electrodes', 'off','whitebk','on');
                img = getframe(fig2).cdata;
                img = sc_cropTopography(img);
                if convModel.Params.imageDim(3) == 1 % Change to gray if the model has only on dimension
                    img = rgb2gray(img);
                end
                F =imresize(img,[convModel.Params.imageDim(1), convModel.Params.imageDim(2)]); % Resize to 128 x128
                ims(:,:,:,k) = uint8(F);
                close(fig2)
                            
            end
        else % For Label and Review Components
            featureData.elc_sig_corr = ICA.iter(indeks).elc_signal_correlation;   % Correlation of Signal between IC and ELC channels 
            featureData.eye_peaks    = peaks_per_min;                             % Peaks per minute for a given component on a IC signal 

        end
        disp('    Data Extracion Complete!\n')

                    %%%%% PREDICTING  %%%%%%%%
        if ~strcmp(Mode,'label') % For Review and Classification Modes

            fprintf('Predicting using weighted network classifier with the %s model...\n',ica.ICA2_classModel)
            % Warning! Previously,we could choose flavour of our model not
            % anymore. Now we use only WEIGHTED classifier with adjustable threshold
    
    
            %%% Try to initialize or switch to a most efficient way to infer:
            if rc.resetGPU && ~isempty(gpuDeviceTable)
                 parallel.gpu.enableCUDAForwardCompatibility(true)
                 reset(gpuDevice(1));
            end
    
            % if we want a custom model scaling 
            if ~isfield(ica.class, 'modelScaling')  %(meaning the proportion of Topography or Sgnal feature based model)
                convScaling = weightsInfo.imagW;
                featScaling = weightsInfo.featW;
            else
                convScaling = ica.class.modelScaling(1);
                featScaling = ica.class.modelScaling(2);
            end
    
            if isfield(ica.class, 'classifThreshold')  %probability threshold of brain comp (Default 50%);
                classification_threshold = ica.class.classifThreshold;
            else
                classification_threshold = 0.5;
            end
    
            %%% Predicting:
            predictions_images = predict(convModel.Model_Net,ims,'MiniBatchSize',16);
            predictions_features = predict(featModel.Model_Net,featureMatrix_Complete);
            prob_values = (predictions_images*convScaling+ predictions_features*featScaling)/(convScaling+featScaling); 
            predictions = double(prob_values > classification_threshold); % Label of our Data!     
            predictions = predictions(:,2);
    
            %%% Create Classification Table to overview the decision of our model
            classif_table = table(predictions_images(:,2), ...    % Image Brain Prob x
                                  predictions_features(:,2),...   % Feature Brain Prob  
                        'VariableNames', {'Images','Features'});   
            classif_table.prob_values = prob_values(:,2);              % Joint Model Probability Values
            classif_table.Proposed_Classification = predictions;  % Label Proposed by Model           
            classif_table.Y = Y';                                 % True Label based on previous data 
                                                                  % (Warning! Meaningless unless processed before)  
            % Whethet the Images and Feature models are incongruent (30% difference)                                                       
            classif_table.Is_Problematic = categorical(classif_table.Images - classif_table.Features > 0.3); 
            classif_table.Elc_corr = featureData.elc_sig_corr';  % Correlation with ELC channels
    
            classif_table_iters{end+1} = classif_table; % Add to all tables - iteration-wise
            disp('    Prediction extraction complete!\n')
        else
            prob_values = zeros(nIC,2); % for labeling models 
        end

        %%%%%%%%%%%% COMPONENT VISUALISATION - GET PLOT DATA %%%%%%%

        % here we gather all the data that are needed for Plots: such as
        % Spectral density estimation, ERF/ERP dimensions and whatno:
        % It happens both for Label, Classification and Review - since it
        % is needed for detaile icaPlots()

        if ~strcmp(Mode,'class') || ica.class.verbosity==1

            Moving_Average_2 = zeros(round(event(1).t_post*data_ica2.hdr.Fs/1000) - round(event(1).t_pre*data_ica2.hdr.Fs/1000)+1,...
                size(featureData.elc_sig_corr,2)); % Empty Moving average structure
            win = 1024*ceil(4/(ica_par.dec_fact+1)); % Window for PSD estimation 
            spectral_estimator = spectrum.welch('Hamming',win,0); % Spectral Estimator
    
            for comp=1:nIC % iterating over components
    
    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                Power_Spectrum = psd(spectral_estimator,ICA.iter(indeks).IC_sig(comp,:),'NFFT',win,'Fs',data_ica2.hdr.Fs);
                mspettro(comp,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
                F = Power_Spectrum.Frequencies;
    
    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                if ~strcmp(seg.studyType , 'RS') % Only for non 
                    for ins = 1:ncond

                        ave = average([ICA.iter(indeks).IC_sig(comp,:)],event(ins).peaks_pos,...
                        round(event(ins).t_pre*data_ica2.hdr.Fs/1000),...
                        round(event(ins).t_post*data_ica2.hdr.Fs/1000),...
                        round(event(ins).t_baseline_on*data_ica2.hdr.Fs/1000),...
                        round(event(ins).t_baseline_off*data_ica2.hdr.Fs/1000));     % Signal Average in Moving window manner (see ITAB functions) 
                        for avs = 1:length(Moving_Average_2)
                            Moving_Average_2(avs,comp) = Moving_Average_2(avs,comp)+ ave(avs);
                        end
                    end

                end
    
            end
            clear spectroal_estimator Power_Spectrum ix
        end

        %%%%%%%%%% VISUALIZATION %%%%%%%%%%%%%%
        % This code specificaly is used to Label or Review the ata
        % We get both Topoplots as well as Timecourse, PSD and ERPs and
        % some numerical features such as number of peaks and eye correlation
        % By keys a,

        if ~strcmp(Mode,'class')

            %%% Labeling Scheme: 
            goodICAs   = zeros(1,nIC); % Empty Arrayt in which 1 will mean that current IC is good
            if strcmp(Mode,'review') 
                goodICAs(ICA.iter(indeks).brain_ic)=1; % Empty Arrayt in which 1 will mean that current IC is good
            end
            unsureICAs = zeros(1,nIC); % Same for Unsure ICs
            processed  = zeros(1,nIC); % Every time the A,B,U buttons have been pressed (used to 
    
    
            ica_Comps = (1:size(ICA.iter(indeks).mixing,2)); 
            idx = 1;
    
            fig = figure('Units','normalized','Position',[0 0 1 1]);
            fig.Name =  sprintf("%d/%d Name: %s - It: %d / %d",ds ,length(infile) ,dsname,indeks,num_iters);
    %%
            %%% First label all accoding to your abilities 
            while isvalid(fig)
                i = ica_Comps(idx);    
        
                %%% Plotting our data in a coherent manner 
                sc_icaPlot(Moving_Average_2(:,i),[ICA.iter(indeks).IC_sig(i,:)],F,mspettro(i,:),...
                    featureData.elc_sig_corr(i),prob_values(i,2),featureData.eye_peaks(i),ICA.iter(indeks).mixing(:,i),...
                    ncond,seg,chan,event,ica_par,12,i,nIC,trim_folder)
    
                % Save-figs To PS structure if verbosity allows (TO DO) 
    
                w = waitforbuttonpress;
                if w == 0          % mouse click → ignore
                    continue;
                end
            
                key = get(fig,'CurrentKey');
                switch key
                    
                    case 'a' % Artifact            %Only for Label mode      changing to 0    adding 1 to processed
                         if strcmp(Mode,'label'), goodICAs(idx) = 0;   processed(idx) = 1;  if idx < numel(ica_Comps), idx = idx + 1;end,end
                    case 'b' % Brain                %Only for Label mode     changing to 0    adding 1 to processed
                         if strcmp(Mode,'label'), goodICAs(idx) = 1; processed(idx) = 1;    if idx < numel(ica_Comps),idx = idx + 1;end, end
                    case 'u' % Uncertain            Onluy for label mode     changing to 0    adding 1 to processed
                         if strcmp(Mode,'label'), unsureICAs(idx) = 1; processed(idx) = 1;  if idx < numel(ica_Comps), idx = idx + 1; end, end
                    case 'rightarrow'  %             When review            adding 1 to processed
                         if strcmp(Mode,'review'), processed(idx) = 1;end,  if idx < numel(ica_Comps),  idx = idx + 1; end
                    case 'leftarrow'   %             When review            adding 1 to processed
                          if strcmp(Mode,'review'), processed(idx) = 1;end, if idx > 1, idx = idx - 1;end
                    case 'escape' % For emergencies only: 
                        close(fig);
                end
    
                if sum(processed) == length(processed) % Exit when we watched and labeled all components (either A, B or U)
                   close(fig);
                end
    
    
            end
    %%
            %%% Second pass to get done with all of the unsure ICA (Only for Label Mode)
            if strcmp(Mode,'label') && sum(unsureICAs)
                ica_UnsureComps = ica_Comps(logical(unsureICAs)); 
                idx = 1;
                processed  = zeros(1,length(ica_UnsureComps)); % Every time the A,B,U buttons have been pressed (used to 
              
                fig = figure('Units','normalized','Position',[0 0 1 1]);
                while isvalid(fig)
    
                    i = ica_UnsureComps(idx);    
            
                    %%% Plotting our data in a coherent manner 
                    sc_icaPlot(Moving_Average_2(:,i),[ICA.iter(indeks).IC_sig(i,:)],F,mspettro(i,:),...
                        featureData.elc_sig_corr(i),prob_values(i,2),featureData.eye_peaks(i),ICA.iter(indeks).mixing(:,i),...
                        ncond,seg,chan,event,ica_par,12,i,nIC,trim_folder)
    
    
                          w = waitforbuttonpress;
                    if w == 0          % mouse click → ignore
                        continue;
                    end
                
                    key = get(fig,'CurrentKey');
                    switch key
                        
                        case 'a' % Artifact            %Only for Label mode      changing to 0    adding 1 to processed
                             if strcmp(Mode,'label'), goodICAs(idx) = 0;   processed(idx) = 1;  if idx < numel(ica_Comps), idx = idx + 1;end,end
                        case 'b' % Brain                %Only for Label mode     changing to 0    adding 1 to processed
                             if strcmp(Mode,'label'), goodICAs(idx) = 1; processed(idx) = 1;    if idx < numel(ica_Comps),idx = idx + 1;end, end
                        case 'rightarrow'  %             When review            adding 1 to processed
                             if strcmp(Mode,'review'), processed(idx) = 1;end,  if idx < numel(ica_Comps),  idx = idx + 1; end
                        case 'leftarrow'   %             When review            adding 1 to processed
                              if strcmp(Mode,'review'), processed(idx) = 1;end, if idx > 1, idx = idx - 1;end
                        case 'escape' % For emergencies only: 
                            close(fig);
                    end
    
                    if sum(processed) == length(processed) % Exit when we watched and labeled all components (either A, B or U)
                       close(fig);
                    end
                end

                
    
            end
            g_ic = ica_Comps(logical(goodICAs));
            b_ic = ica_Comps(~logical(goodICAs)); 
        else % For Classification scheme
            ica_Comps = (1:size(ICA.iter(indeks).mixing,2)); 
            g_ic = ica_Comps(logical(predictions));
            b_ic = ica_Comps(~logical(predictions)); 

            unsureICAs = zeros(1,size(ICA.iter(indeks).mixing,2));
        end

        disp("All ICs classified!")

        

        ICA_after_threshold = [];
        %%% Saving the data unto Main Matrix
        data_ica2.ICA.iter(indeks).Unsure = ica_Comps(logical(unsureICAs));
        data_ica2.ICA.iter(indeks).brain_ic_number = length(g_ic);
        data_ica2.ICA.iter(indeks).brain_ic = g_ic;
        data_ica2.ICA.iter(indeks).ICA_after_threshold = ICA_after_threshold;
        if n_elec > 3      %%% Calculating Artifact Contamination:
            art_con = mean(data_ica2.ICA.iter(indeks).elc_power_correlation(g_ic));
        else
            art_con = 0;
        end
        data_ica2.ICA.iter(indeks).artifact_contamination = art_con;



        %%% Optional Validation
        if ica.class.validation == true && ~strcmp(Mode,'label') 
            try 
            sc_validationPlot(predictions,Y,prob_values,saveFolderds,dsname,num2str(indeks))
            catch
                disp("Mistake!")
            end
        end

      
    end



     

    %%%%%%% ALL ITER CALCULATIONS %%%%%%
    % Here we try to calculate stuff that are agreagated throught Iters of ICA
    
    %%% Calculate Artif Contamination:
    for it = 1: num_iters

        corresp_g_ic = data_ica2.ICA.iter(I(it)).brain_ic;

        if n_elec > 2
            art_con = mean(data_ica2.ICA.iter(I(it)).elc_power_correlation(corresp_g_ic));
        else
            art_con = 0;
        end

        goodness_ic(I(it),1) = length(corresp_g_ic);   % no of brain components
        goodness_ic(I(it),2) = 1-art_con;              % artifact contamination

    end
    [~,bestiter_new] = max( goodness_ic(:,1).*goodness_ic(:,2) );

    data_ica2.ICA.best_iter.index = bestiter_new;
    data_ica2.ICA.best_iter.IC_sig =  data_ica2.ICA.iter(bestiter_new).IC_sig;
    data_ica2.ICA.best_iter.nonlinearity = ica.ICA2_nonlinearity;

    %%% Simulation Setting for settin all as Brain
    if (strcmp(rc.dataFormat, 'itab-sim') || strcmp(rc.dataFormat, 'syn-sim')) && strcmp(Mode,'class')
        if isfield(rc.sim, 'setallICasbrain')
            if rc.sim.setallICasbrain   %settinga all brain as IC - for sim purposes only!!
                for it =  1:length(data_ica2.ICA.iter)
                    nofic(it)= data_ica2.ICA.iter(it).total_ic_number;
                end
                [icnobestiter,bestindex] = max(nofic);
                data_ica2.ICA.best_iter.index = bestindex;
                data_ica2.ICA.iter(bestindex).brain_ic = 1:icnobestiter;
                data_ica2.ICA.iter(bestindex).brain_ic_number = data_ica2.ICA.iter(bestindex).total_ic_number;
            end
        end
    end

    %%% IC Statistics - for later double checking:
    

    ica2stat{1} = dsname;
    ica2stat{2} = bestiter_new;
    ica2stat{3} = data_ica2.ICA.iter(bestiter_new).total_ic_number;
    ica2stat{4} = data_ica2.ICA.iter(bestiter_new).brain_ic_number;

    %%% Failsafe for when there is no previous data present so that ica2stat
    %%% will be done without informations from previous iters:
    if isfile( strrep(strrep(infile{ds}, '6_ICA2', '5_ICA1_AR'), '_ica2.mat', '_ICA1_arj.mat'))
        datastat = sc_icavarstat(dsname, infile{ds}, data_ica2);
    
        ica2stat(5) = {datastat.var_ave(1)};
        ica2stat(6) = {datastat.var_ave(2)};
        ica2stat(7) = {datastat.var_ave(3)};
        ica2stat(8) = {datastat.var_ave(2) - datastat.var_ave(3)};
        ica2stat(9) = {round(datastat.ratio_brain)};
        ica2stat(10) = {round(datastat.ratio_resid)}; 
    end
    %%%%%% SAVING DATA %%%%%%%
    file_name = infile{ds};
    fprintf('final_saving at %s \n',file_name)
    save(file_name,'data_ica2','-v7.3');  % '-v6' v6 added for speedup

    % Write down the completed DS to a LOG file:
    fid = fopen(progressfile, 'w');
    fprintf(fid, 'recently completed ds: ');
    fprintf(fid, dsname);
    fprintf(fid, '\n');
    fprintf(fid, mat2str(ds));
    fclose(fid);

     %%%%%%% AFTER VIZ %%%%%%%
        % Here we are trying to first visualize the Good and bad brain
        % components and then making for them a sc_icaPlots if the
        % verbosity allows 

   
    %%%% Making best_iter TOPOPLOT %%%%%

    it = data_ica2.ICA.best_iter.index;

    % Fix for situations in which ICA are empty and this ICA and classif_table are mismatched:
    valid = ~arrayfun(@(x) isempty(x.mixing), data_ica2.ICA.iter);    
    if valid(it) it_adj = sum(valid(1:it)); else it_adj = NaN; end

    % iter = data_ica2.ICA.iter(it);
    best_g_ic = data_ica2.ICA.iter(it).brain_ic;
    fprintf('\n Best iter: %d \n',it)
    all_ic = [1:size(data_ica2.ICA.iter(it).IC_sig,1)];
    best_b_ic = all_ic(~ismember(all_ic,best_g_ic));

    %%% Ploting Brain ICs

   % figure ('visible','off','Position',get(0,'Screensize'));
   figure ('visible','off',   'position',[0,0,4000,3000]); % as large as possible figure
                
    % Adding Failsafe if no ICA Is Good 
    if ~isempty(best_g_ic)
        lat_good =  ceil( sqrt(length(best_g_ic)) );
    else
        lat_good = 1;
        fileEXIT = fopen(fullfile(saveFolderds,dsname,"NO_GOOD_ICA_WHATSOEVER.txt"),"w");
        fprintf(fileEXIT,"In All Iterations No single Good ICA Had Been Found! Remove Channel IMMEDIATELY")
    end


    tiledlayout(lat_good,lat_good,'TileSpacing','tight','Padding','tight');   %original subplot layout
    for ix=1:length(best_g_ic)
        temp_ix = best_g_ic(ix);
        nexttile
        topoplot(data_ica2.ICA.iter(it).mixing(:,temp_ix), char(fullfile(trim_folder,'ch_trimmed.elc')), 'nosedir', chan.ori, 'electrodes', 'labels');
        title(strcat({'IC'},num2str(temp_ix),' /',num2str(length(g_ic)),''));
    end
    try
        delete(strtrim(ls(fullfile(saveFolderds, dsname, '_BRAIN_BEST_ITER*.jpg'))));    % remove old files
    catch
        warning("No previous Best iter topolot!")
    end
    fig_handle = gcf();
    print(fig_handle,  strcat(saveFolderds, '/',dsname,'/', strcat('_BRAIN_BEST_ITER_',num2str(it), '_MAPS.jpg')),'-djpeg','-r180');
    close(fig_handle)


    %%% Ploting nonBrain ICs
    
   figure ('visible','off',   'position',[0,0,4000,3000]);

    if ~isempty(best_b_ic)
        lat_bad =  ceil( sqrt(length(best_b_ic)) );
    else
        lat_bad = 1;
    end
        
    tiledlayout(lat_bad,lat_bad,'TileSpacing','tight','Padding','tight');   %original subplot layout
    for ix=1:length(best_b_ic)
        % ix=length(b_ic)-ixrev+1; %par draws ICs in reversed order
        temp_ix = best_b_ic(ix);
        nexttile
        topoplot(data_ica2.ICA.iter(it).mixing(:,temp_ix), fullfile(trim_folder, 'ch_trimmed.elc'), 'nosedir', chan.ori, 'electrodes', 'labels');
        title(strcat({'IC'},num2str(temp_ix),' /',num2str(length(g_ic)),''));
    end

    try
        delete(strtrim(ls(fullfile(saveFolderds, dsname, '_NONBRAIN_BEST_ITER*.jpg'))));  % remove old files
    catch
    end

    fig_handle = gcf();
    print(fig_handle, strcat(saveFolderds, '/',dsname,'/',strcat('_NONBRAIN_BEST_ITER_',num2str(it), '_MAPS.jpg')),'-djpeg','-r180');
    close(fig_handle)

%%%%%%%%%%%% ICAPLOT
%%%% ADD icaPLot() if verbosity allow
% this allows for a greater insight into Classified and Labeled Data:

    if ica.class.verbosity


            Moving_Average_2 = zeros(round(event(1).t_post*data_ica2.hdr.Fs/1000) - round(event(1).t_pre*data_ica2.hdr.Fs/1000)+1,...
                size(ICA.iter(it).elc_signal_correlation,2)); % Empty Moving average structure
            win = 1024*ceil(4/(ica_par.dec_fact+1)); % Window for PSD estimation 
            spectral_estimator = spectrum.welch('Hamming',win,0); % Spectral Estimator
            bestIter_eyePeaks = zeros(1,length(all_ic));
            for comp=1:length(all_ic) % iterating over components

                % 1. Number of Eye peaks 
                sig_temp =ICA.iter(it).IC_sig(comp,:);
                num_peaks_in_window = sc_eyePeaks(sig_temp,data_ica2.hdr.Fs);
                bestIter_eyePeaks(comp) =  sum(num_peaks_in_window)/(length(data_ica2.ica_par.time_ica)/(60*data_ica2.hdr.Fs));

    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                Power_Spectrum = psd(spectral_estimator,ICA.iter(it).IC_sig(comp,:),'NFFT',win,'Fs',data_ica2.hdr.Fs);
                mspettro(comp,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
                F = Power_Spectrum.Frequencies;
    
    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                if ~strcmp(seg.studyType , 'RS') % Only for non 
                    for ins = 1:ncond

                        ave = average([ICA.iter(it).IC_sig(comp,:)],event(ins).peaks_pos,...
                        round(event(ins).t_pre*data_ica2.hdr.Fs/1000),...
                        round(event(ins).t_post*data_ica2.hdr.Fs/1000),...
                        round(event(ins).t_baseline_on*data_ica2.hdr.Fs/1000),...
                        round(event(ins).t_baseline_off*data_ica2.hdr.Fs/1000));     % Signal Average in Moving window manner (see ITAB functions) 
                        for avs = 1:length(Moving_Average_2)
                            Moving_Average_2(avs,comp) = Moving_Average_2(avs,comp)+ ave(avs);
                        end
                    end

                end
    
            end

        % Bad ICs 
        set(0,'DefaultFigureVisible','off')
        %%

        if isfile(fullfile(saveFolderds,dsname,strcat("NONBRAIN_BEST_ITER_",num2str(it),"_PLOT.ps"))); delete(fullfile(saveFolderds,dsname,strcat("NONBRAIN_BEST_ITER_",num2str(it),"_PLOT.ps"))) ;end

        for ix=1:length(best_b_ic)
        
            %%% Plot
            fig = figure('Units','normalized','Position',[0 0 1 1]);

          sc_icaPlot(Moving_Average_2(:,best_b_ic(ix)),[ICA.iter(it).IC_sig(best_b_ic(ix),:)],F,mspettro(best_b_ic(ix),:),...
                        ICA.iter(it).elc_signal_correlation(best_b_ic(ix)),classif_table_iters{it_adj}.prob_values(best_b_ic(ix)),bestIter_eyePeaks(best_b_ic(ix)),ICA.iter(it).mixing(:,best_b_ic(ix)),...
                        ncond,seg,chan,event,ica_par,12,best_b_ic(ix),length(all_ic),trim_folder)
            %%% add a figure to .ps file: 
            
            print(fig, '-dpsc', '-append','-fillpage' ,  fullfile(saveFolderds,dsname,strcat("NONBRAIN_BEST_ITER_",num2str(it),"_PLOT.ps")));


        end
%%
        % Good ICs 

        if isfile(fullfile(saveFolderds,dsname,strcat("BRAIN_BEST_ITER_",num2str(it),"_PLOT.ps"))); delete(fullfile(saveFolderds,dsname,strcat("NONBRAIN_BEST_ITER_",num2str(it),"_PLOT.ps"))) ;end

        for ix=1:length(best_g_ic)

            %%% Plot
            fig = figure('Units','normalized','Position',[0 0 1 1]);

            sc_icaPlot(Moving_Average_2(:,best_g_ic(ix)),[ICA.iter(it).IC_sig(ix,:)],F,mspettro(best_g_ic(ix),:),...
                    ICA.iter(it).elc_signal_correlation(best_g_ic(ix)),classif_table_iters{it_adj}.prob_values(best_g_ic(ix)),bestIter_eyePeaks(best_g_ic(ix)),ICA.iter(it).mixing(:,best_g_ic(ix)),...
                    ncond,seg,chan,event,ica_par,12,best_g_ic(ix),length(all_ic),trim_folder)
            %%% add a figure to .ps file: 
            print(fig, '-dpsc', '-append','-fillpage' ,  fullfile(saveFolderds,dsname,strcat("BRAIN_BEST_ITER_",num2str(it),"_PLOT.ps")));

        end
    end


end
