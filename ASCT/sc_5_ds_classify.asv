function [classif_table_iters,ica2stat] = sc_5_ds_classify(infile, ds, rc, chan, ica, seg, currentFolder, progressfile,Data_volume, Mode,Mods)

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

    if (isfield(rc,'timing') && rc.timing)   
        tDS = tic;
        Timing = struct('load',0,'features',0,'images',0,'predict',0,'plotdata',0, ...
                   'save',0,'bestMaps',0,'verbosity',0,'total',0,'nIters',0,'nDone',0); 
    end

    if (isfield(rc,'timing') && rc.timing); t_l = tic; end
    %%% Load Model info and ica stat
    classif_table_iters = {};
    classif_tbl_by_iter = {};     % same tables, stored under the REAL iteration number
    convModel  = Mods.convModel;   featModel   = Mods.featModel;
    normStruct = Mods.normStruct;  weightsInfo = Mods.mWeights;
    
   
    
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
    imDim       = convModel.Params.imageDim;


    fprintf(strcat('\nClassifying ICA components; DS: ', dsname));


    %Getting electric channels info and trimmed Channels .elc file
    if isfield(chan,"elec")
        n_elec = length(chan.elec); %number of electric channels
    else
        n_elec=0;
    end
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

        
    %%% Get main data:
    Fs          = data_ica2.hdr.Fs;
  nTica       = length(data_ica2.ica_par.time_ica);
  trialLength = size(data_ica2.trial{1}, 2);
  elcFile     = fullfile(char(trim_folder),'ch_trimmed.elc');
  ori         = chan.ori;


    %%% Get Iterations that interests you the most (Either All or Best) 
    best_iter_index = ICA.best_iter.index;
    if strcmp(Data_volume, 'all')     % All Iterations
        num_iters = size(ICA.iter,2);
        I = (1:size(ICA.iter,2));
    elseif strcmp(Data_volume,'best') % Only Best N iterations (Hardcoded 5) 
        [~,I] = sort([ICA.iter.total_ic_number],'descend'); %based on IC number %%% FIX ASAP! !! TEMP MD! 
        I = I(1);
        num_iters = 1;
    else                              % First iter only (For testing Purposes) 
        num_iters =1;
        if strcmp(Data_volume,'bestiter'), I = ICA.best_iter.index; else, I = 1; end
    end

  
    if (isfield(rc,'timing') && rc.timing); Timing.load = toc(t_l); end % End of Load Timing



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
            indeks = best_iter_index;
        elseif strcmp(Data_volume,'best') % 5 best ICAs
            indeks = I(indeks); 
        end
        


        %%% Current Iter Parameters
        sig = ICA.iter(indeks).IC_sig;     % nIC x T
        mix = ICA.iter(indeks).mixing;     % nCh x nIC
        [nIC, sigSizeIC] = size(sig); % Getting Size of ICA signal for a current iteration and number of comps

        if isempty(ICA.iter(indeks).unmixing) % If No iC is here - continue
            continue
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%% Supplement Features %%% -- ADDITION!!!

        % here we compute additional features that had not been computed in SC_4

        if (isfield(rc,'timing') && rc.timing); t_f = tic; end % Beg of Feature timing 

        % Finds the number of Peaks in data 
        peaks_per_min = zeros(1,nIC); peaksNum = zeros(1,nIC); meanPLoc = nan(1,nIC);
        maxPeak = nan(1,nIC); maxProm = nan(1,nIC); maxWidth = nan(1,nIC);
        
        %%% Iterate thrtough current components
        parfor comps = 1:nIC
            sig_temp =sig(comps,:);

            % 1. Number of Eye peaks 
            num_peaks_in_window = sc_eyePeaks(sig_temp,Fs);
            peaks_per_min(comps) = sum(num_peaks_in_window)/(nTica/(60*Fs));

            % 2. Fooof Features
            [pk, loc, wid, prom] = sc_foofEstim(sig_temp,trialLength,Fs); % WARNING - trialLength should possibly be changed for something different - like stable 2s window to get both high and lower freq
            peaksNum(comps) = length(pk);
            meanPLoc(comps) = mean(loc);
            if ~isempty(pk)
                maxPeak(comps)   =  max(pk);
                maxProm(comps)   =  max(prom);
                maxWidth(comps)  =  max(wid);
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
    
            if (isfield(rc,'timing') && rc.timing); Timing.features = Timing.features + toc(t_f);    end % End of Feature timing 


            %%%%% IMAGE LOADING %%%%%%%%
            disp('    Extracting image variables...');
            
            if (isfield(rc,'timing') && rc.timing); t_i = tic; end % Beg of Feature timing 

            ims = zeros(imDim(1), imDim(2),imDim(3),size(featureMatrix_Complete,1)); %3,nIC); %Dummy images list
            parfor k = 1:size(mix,2)  
                
                fig2 = figure();
                set(fig2,'visible','off', 'Color',[1 1 1]);
                set(gcf, 'InvertHardCopy', 'off');  % do NOT auto-adjust background
                axes('Color',[1 1 1]);              % axis background MUST ALSO be white
                % evalc("topoplot(mix(:,k), elcFile, 'nosedir', ori,'verbose','off','style' , 'map','headrad' ,0, 'electrodes', 'off','whitebk','on');");
                topoplot(mix(:,k), elcFile, 'nosedir', ori,'verbose','off','style' , 'map','headrad' ,0, 'electrodes', 'off','whitebk','on');
                
                colormap(gca, jet(256));      % axes-level colormap is copied along with the axes    
                img = fig2frame(fig2).cdata;

                %img = getframe(fig2).cdata;

                img = sc_cropTopography(img);
                if imDim(3) == 1 % Change to gray if the model has only on dimension
                    img = rgb2gray(img);
                end
                F =imresize(img,[imDim(1), imDim(2)]); % Resize to 128 x128
                ims(:,:,:,k) = uint8(F);
                close(fig2)
                            
            end

            if (isfield(rc,'timing') && rc.timing);   Timing.images = Timing.images + toc(t_i);   end % Beg of Feature timing 

        else % For Label and Review Components
            featureData.elc_sig_corr = ICA.iter(indeks).elc_signal_correlation;   % Correlation of Signal between IC and ELC channels 
            featureData.eye_peaks    = peaks_per_min;                             % Peaks per minute for a given component on a IC signal 

        end
        disp('    Data Extracion Complete!\n')

                    %%%%% PREDICTING  %%%%%%%%

        if (isfield(rc,'timing') && rc.timing); t_p = tic; end % Beg of Feature timing 

        if ~strcmp(Mode,'label') % For Review and Classification Modes

            fprintf('Predicting using weighted network classifier with the %s model...\n',ica.ICA2_classModel)
            % Warning! Previously,we could choose flavour of our model not
            % anymore. Now we use only WEIGHTED classifier with adjustable threshold
    
       
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
            if isfield(rc,'classExecEnv'), execEnv = rc.classExecEnv; else, execEnv = 'cpu'; end

            predictions_images = predict(convModel.Model_Net,ims,'MiniBatchSize',64,'ExecutionEnvironment',execEnv);
            predictions_features = predict(featModel.Model_Net,featureMatrix_Complete, 'ExecutionEnvironment',execEnv);
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
            classif_table.Is_Problematic = categorical(abs(classif_table.Images - classif_table.Features) > 0.3); 
            classif_table.Elc_corr = featureData.elc_sig_corr';  % Correlation with ELC channels
    
            classif_table_iters{end+1} = classif_table; % Add to all tables - iteration-wise
            classif_tbl_by_iter{indeks} = classif_table; % stored by real iteration number
            disp('    Prediction extraction complete!\n')
        else
            prob_values = zeros(nIC,2); % for labeling models 
        end
        if (isfield(rc,'timing') && rc.timing); Timing.predict = Timing.predict + toc(t_p); Timing.nDone   = Timing.nDone + 1;  end % End of Predict timing 

        %%%%%%%%%%%% COMPONENT VISUALISATION - GET PLOT DATA %%%%%%%

        % here we gather all the data that are needed for Plots: such as
        % Spectral density estimation, ERF/ERP dimensions and whatno:
        % It happens both for Label, Classification and Review - since it
        % is needed for detaile icaPlots()

        if (isfield(rc,'timing') && rc.timing); t_v1 = tic; end % Beg of Image timing 


        if ~strcmp(Mode,'class') 

            Moving_Average_2 = zeros(round(event(1).t_post*Fs/1000) - round(event(1).t_pre*Fs/1000)+1,...
                size(featureData.elc_sig_corr,2)); % Empty Moving average structure
            win = 1024*ceil(4/(ica_par.dec_fact+1)); % Window for PSD estimation 
            spectral_estimator = spectrum.welch('Hamming',win,0); % Spectral Estimator
    
            for comp=1:nIC % iterating over components
    
    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                Power_Spectrum = psd(spectral_estimator,sig(comp,:),'NFFT',win,'Fs',Fs);
                mspettro(comp,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
                F = Power_Spectrum.Frequencies;
    
    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                if ~strcmp(seg.studyType , 'RS') % Only for non 
                    for ins = 1:ncond

                        ave = average([sig(comp,:)],event(ins).peaks_pos,...
                        round(event(ins).t_pre*Fs/1000),...
                        round(event(ins).t_post*Fs/1000),...
                        round(event(ins).t_baseline_on*Fs/1000),...
                        round(event(ins).t_baseline_off*Fs/1000));     % Signal Average in Moving window manner (see ITAB functions) 

                      Moving_Average_2(:,comp) = Moving_Average_2(:,comp) + ave(:);
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
    
    
            ica_Comps = (1:size(mix,2)); 
            idx = 1;
    
            fig = figure('Units','normalized','Position',[0 0 1 1]);
            fig.Name =  sprintf("%d/%d Name: %s - It: %d / %d",ds ,length(infile) ,dsname,indeks,num_iters);
    %%
            %%% First label all accoding to your abilities 
            while isvalid(fig)
                i = ica_Comps(idx);    
        
                %%% Plotting our data in a coherent manner 
                sc_icaPlot(Moving_Average_2(:,i),[sig(i,:)],F,mspettro(i,:),...
                    featureData.elc_sig_corr(i),prob_values(i,2),featureData.eye_peaks(i),mix(:,i),...
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
                    sc_icaPlot(Moving_Average_2(:,i),[sig(i,:)],F,mspettro(i,:),...
                        featureData.elc_sig_corr(i),prob_values(i,2),featureData.eye_peaks(i),mix(:,i),...
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
            ica_Comps = (1:size(mix,2)); 
            g_ic = ica_Comps(logical(predictions));
            b_ic = ica_Comps(~logical(predictions)); 

            unsureICAs = zeros(1,size(mix,2));
        end

        disp("All ICs classified!")

        %%% Optional Validation
        if isfield(ica.class,'validation')
            if ica.class.validation == true && ~strcmp(Mode,'label') 
                try 
                    sc_validationPlot(predictions,Y,prob_values,saveFolderds,dsname,num2str(indeks))
                catch
                    disp("Mistake!")
                end
            end
        end

        if (isfield(rc,'timing') && rc.timing); Timing.plotdata = Timing.plotdata + toc(t_v1); end % Beg of Image timing 


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



      

    end



     if (isfield(rc,'timing') && rc.timing); t_s = tic; end % Beg of Image timing 


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

    % % Write down the completed DS to a LOG file:
    % fid = fopen(progressfile, 'w');
    % fprintf(fid, 'recently completed ds: ');
    % fprintf(fid, dsname);
    % fprintf(fid, '\n');
    % fprintf(fid, mat2str(ds));
    % fclose(fid);

     if (isfield(rc,'timing') && rc.timing); Timing.save = toc(t_s); end % Beg of Image timing 


     %%%%%%% AFTER VIZ %%%%%%%
        % Here we are trying to first visualize the Good and bad brain
        % components and then making for them a sc_icaPlots if the
        % verbosity allows 

   
    %%%% Making best_iter TOPOPLOT %%%%%
    if (isfield(rc,'timing') && rc.timing); t_t = tic; end % Beg of Image timing 

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
        evalc("topoplot(data_ica2.ICA.iter(it).mixing(:,temp_ix), char(fullfile(trim_folder,'ch_trimmed.elc')), 'nosedir', ori, 'electrodes', 'labels');");
        title(strcat({'IC'},num2str(temp_ix),' /',num2str(length(best_g_ic)),''));
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
        evalc("topoplot(data_ica2.ICA.iter(it).mixing(:,temp_ix), fullfile(trim_folder, 'ch_trimmed.elc'), 'nosedir', ori, 'electrodes', 'labels');");
        title(strcat({'IC'},num2str(temp_ix),' /',num2str(length(best_b_ic)),''));
    end

    try
        delete(strtrim(ls(fullfile(saveFolderds, dsname, '_NONBRAIN_BEST_ITER*.jpg'))));  % remove old files
    catch
    end

    fig_handle = gcf();
    print(fig_handle, strcat(saveFolderds, '/',dsname,'/',strcat('_NONBRAIN_BEST_ITER_',num2str(it), '_MAPS.jpg')),'-djpeg','-r180');
    close(fig_handle)

    if (isfield(rc,'timing') && rc.timing); Timing.bestMaps  = toc(t_t); end % Beg of Image timing 


%%%%%%%%%%%% ICAPLOT
%%%% ADD icaPLot() if verbosity allow
% this allows for a greater insight into Classified and Labeled Data:
    if (isfield(rc,'timing') && rc.timing); t_v  = tic; end % Beg of Image timing 

    if ica.class.verbosity

           if numel(classif_tbl_by_iter) >= it && ~isempty(classif_tbl_by_iter{it})
                probBest = classif_tbl_by_iter{it}.prob_values;
            else
                probBest = nan(numel(all_ic),1);
            end


            Moving_Average_2 = zeros(round(event(1).t_post*Fs/1000) - round(event(1).t_pre*Fs/1000)+1,...
                size(ICA.iter(it).elc_signal_correlation,2)); % Empty Moving average structure
            win = 1024*ceil(4/(ica_par.dec_fact+1)); % Window for PSD estimation 
            spectral_estimator = spectrum.welch('Hamming',win,0); % Spectral Estimator
            bestIter_eyePeaks = zeros(1,length(all_ic));
            for comp=1:length(all_ic) % iterating over components

                % 1. Number of Eye peaks 
                sig_temp =ICA.iter(it).IC_sig(comp,:);
                num_peaks_in_window = sc_eyePeaks(sig_temp,Fs);
                bestIter_eyePeaks(comp) =  sum(num_peaks_in_window)/(nTica/(60*Fs));

    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                Power_Spectrum = psd(spectral_estimator,ICA.iter(it).IC_sig(comp,:),'NFFT',win,'Fs',Fs);
                mspettro(comp,:) = sqrt((Fsnew/win)*Power_Spectrum.Data)';
                F = Power_Spectrum.Frequencies;
    
    
                %------ POWER SPECTRAL DENSITY ESTIMATION  -----
                if ~strcmp(seg.studyType , 'RS') % Only for non 
                    for ins = 1:ncond

                        ave = average([ICA.iter(it).IC_sig(comp,:)],event(ins).peaks_pos,...
                        round(event(ins).t_pre*Fs/1000),...
                        round(event(ins).t_post*Fs/1000),...
                        round(event(ins).t_baseline_on*Fs/1000),...
                        round(event(ins).t_baseline_off*Fs/1000));     % Signal Average in Moving window manner (see ITAB functions) 
                        Moving_Average_2(:,comp) = Moving_Average_2(:,comp) + ave(:);
                    end

                end
    
            end

      %%%%  Plotting
      pdfBad  = fullfile(saveFolderds, dsname, sprintf('NONBRAIN_BEST_ITER_%d_PLOT.pdf', it));
      pdfGood = fullfile(saveFolderds, dsname, sprintf('BRAIN_BEST_ITER_%d_PLOT.pdf',    it));
      if isfile(pdfBad),  delete(pdfBad);  end
      if isfile(pdfGood), delete(pdfGood); end
    
      sets = {best_b_ic, pdfBad; best_g_ic, pdfGood};
      for s = 1:2
          for c = sets{s,1}(:)'
              fig = figure('Visible','off', 'Units','pixels', 'Position',[0 0 1600 1000]);
              sc_icaPlot(Moving_Average_2(:,c), ICA.iter(it).IC_sig(c,:), F, mspettro(c,:), ...
                  ICA.iter(it).elc_signal_correlation(c), probBest(c), bestIter_eyePeaks(c), ...
                  ICA.iter(it).mixing(:,c), ncond, seg, chan, event, ica_par, 12, c, ...
                  numel(all_ic), trim_folder);
              exportgraphics(fig, sets{s,2}, 'ContentType','image', 'Resolution',120, 'Append',true);
              close(fig);
          end
      end
    end

    if (isfield(rc,'timing') && rc.timing)
        Timing.verbosity  = toc(t_v); 

        % Compute and save - Per DS Timing sample 
        Timing.total  = toc(tDS);                                        % <-- NEW
        Timing.nIters = num_iters;                                       % <-- NEW
        for v = {'features','images','predict','plotdata'}          % <-- NEW
            Timing.([v{1} '_avg']) = Timing.(v{1}) / max(Timing.nDone, 1);         % <-- NEW
        end                                                         % <-- NEW
        Timing.dsname = string(dsname);                                  % <-- NEW
        timingRow  = movevars(struct2table(Timing), 'dsname', 'Before', 1);            % <-- NEW
        timingFile = fullfile(saveFolderds, dsname, 'class_timing.csv');   % one file per DS, 1 row
        writetable(timingRow, timingFile);                                  % overwrite, no stale rows
    end
end
