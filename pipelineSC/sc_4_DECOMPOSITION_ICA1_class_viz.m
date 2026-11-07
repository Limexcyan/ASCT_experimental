
function decomp_ica1 = sc_4_DECOMPOSITION_ICA1_class_viz(decomp_ica1, chan, rc, ica)

    load (ica.ICA1_classModel); %Load Model
    dsname = decomp_ica1.dsname;
    saveFolderds = fullfile(rc.analysisFolder, '4_ICA1', dsname);

    for it = 1 : length(decomp_ica1.ICA.iter)
        n_IC = decomp_ica1.ICA.iter(it).total_ic_number;
        IC_mix = decomp_ica1.ICA.iter(it).mixing;
    
        noIC2clss1 = n_IC;  %MD
        if noIC2clss1 > 20;  noIC2clss1 = 20;  end  % limit the number of ICs for class1
        
        
        if ~strcmp(ica.ICA1_classMode,'cat')  % cat - modle with numeric features only, w/out figs
            ims = zeros(263, 350,3,size(IC_mix,2)); %3,ICA_Threshold); %Dummy images list
            for k = 1:noIC2clss1
                fig2 = figure();
                set(fig2,'visible','off');
                topoplot(IC_mix(:,k), fullfile(saveFolderds, 'ch_trimmed.elc'), 'nosedir', chan.ori,'verbose','off','electrodes', 'off','style' , 'map','headrad' ,0);
                FFF =imresize(getframe(fig2).cdata,[263, 350]);
                ims(:,:,:,k) = double(FFF);
                close(fig2) %mw
            end
        
            augmentedSet = augmentedImageDatastore([263 350 3], ims);
        else
            augmentedSet = [];
        end

        % Create Classif Data and PREDICT 
        if ~isempty(decomp_ica1.ICA.iter(it).mixing)       

            % Predict with Features model
            if ~strcmp(ica.ICA1_classMode,'image')
                XTest2 = array2table(normalize(decomp_ica1.ICA.iter(it).elc_signal_correlation'),'VariableNames',{'elc_signal_corr'});
                XTest2.Elc_spectrum_corr = normalize(decomp_ica1.ICA.iter(it).elc_spectrum_correlation');
                XTest2.Spect_one_over_f = normalize(decomp_ica1.ICA.iter(it).spectrum_one_over_f');
                XTest2.Spect_flat = normalize(decomp_ica1.ICA.iter(it).spectrum_flat');
                XTest2.Kurtosis = normalize(decomp_ica1.ICA.iter(it).time_kurtosis');
                XTest2.elc_power_corr = normalize(decomp_ica1.ICA.iter(it).elc_power_correlation');
                setenv('gpuShouldBeUsed','false')
                predictions_features = predict(IF_mlp_model,XTest2,'ExecutionEnvironment','cpu');

                if strcmp(ica.ICA1_classMode,'cat')
                    predictions = predictions_features(:,2);
                end
            end

            %%% Classifying with image Model - MD
            if ~strcmp(ica.ICA1_classMode,'cat')

                predictions_images = predict(IF_conv_model,augmentedSet,'MiniBatchSize',2);
                if strcmp(ica.ICA1_classMode,'image')
                    predictions = predictions_images;
                end
            end

            %%% Classifying with Joint Model - MD
            if strcmp(ica.ICA1_classMode,'full')
                predictions = (predictions_features(:,2) + predictions_images(:,1))/2;
            end
            clear predictions_images predictions_features
                       
            %%% GPU resetting (for better computations) 
            if rc.resetGPU
                if ~isempty(gpuDeviceTable)
                    try
                        reset(gpuDevice(1));
                    catch
                        parallel.gpu.enableCUDAForwardCompatibility(true)   % for too new cards
                        reset(gpuDevice(1));
                    end
                end
            end

            %%% Joining Together predictions
                        
            Classif = predictions > 0.5; % Classif Deciions
            good_ic = find( Classif==1 );

            % Artifact contamination computations
            if isfield(chan,"elec") 
                art_con = mean(decomp_ica1.ICA.iter(it).elc_power_correlation(good_ic) );
            else
                art_con = NaN;
            end

            decomp_ica1.ICA.iter(it).artifact_contamination=art_con;
            decomp_ica1.ICA.iter(it).predictions_proba = predictions;
            decomp_ica1.ICA.iter(it).brain_ic_number=length(good_ic);
            decomp_ica1.ICA.iter(it).brain_ic=good_ic;
            clear predictions

            goodness_ic(it,1) = length( good_ic );
            goodness_ic(it,2) = 1-art_con;

        else
            goodness_ic(it,1) = 0;
            goodness_ic(it,2) = NaN;

        end

    end                

    %%% Compute Best Iter
    if (max( goodness_ic(:,1).*goodness_ic(:,2) )>0)
        [~,pos_best_iter] = max( goodness_ic(:,1).*goodness_ic(:,2) );
    else
        max_poor_ic = decomp_ica1.ICA.iter(1).total_ic_number;  %if no brain_ic found, set best_iter using the highest no_ic
        if isempty(max_poor_ic); max_poor_ic=0; end
        pos_best_iter = 1;
        for ii = 2:size(decomp_ica1.ICA.iter,2)
            if decomp_ica1.ICA.iter(ii).total_ic_number > max_poor_ic
                max_poor_ic = decomp_ica1.ICA.iter(ii).total_ic_number;
                pos_best_iter = ii;
            end
        end
    end

    good_ic = decomp_ica1.ICA.iter(pos_best_iter).brain_ic;
    disp( strcat('non-linearity used: ', ica.ICA1_nonlinearity, ' - run number:', num2str(mod(pos_best_iter-1,ica.ICA1_numIter)+1)));
    decomp_ica1.ICA.best_iter.index = pos_best_iter;
    ic_stat{2} = pos_best_iter;
    decomp_ica1.ICA.best_iter.IC_sig =  decomp_ica1.ICA.iter(pos_best_iter).IC_sig;
    decomp_ica1.ICA.iter(pos_best_iter).brain_ic_number = length(good_ic);
    ic_stat{4} = length(good_ic);
    ic_stat{3} = decomp_ica1.ICA.iter(pos_best_iter).total_ic_number;
    decomp_ica1.ICA.iter(pos_best_iter).brain_ic = good_ic;
    decomp_ica1.ic_stat = ic_stat;

    clear goodness_ic

   
end

