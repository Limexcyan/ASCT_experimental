%This script classifies data based on previously trained models
%
% ICA spatial plotting works by using showfield() function. In script there
% is another function that works similarily --> topoplot(). 

%% ----> Settings <----

%Loading colormap data
load('colors.mat');
predictions_all = [];
prob_values_all = [];
Y_all =[];
set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[40 120 3000 1800]);
% set(0,'DefaultLineLineWidth',1,'defaultFigurePosition',[80 120 1000 680]);   per schermi con risoluzione 1024x768

if ~isfield(rc, 'class')
    Mode = 'class';
else
    Mode = rc.class; % Sets script to classification or labeling mode:
    % + 'label'  --> labeling mode
    % + 'class'  --> classificiation mode
    % + 'review' --> review mode
end

model_type = 'if';% Model type: DEPRECIATED! 
% + 'own'        --> custom neural net
% + 'pretrained' --> pretrained neural net
% + 'if'         --> simple classifier based on two models

Validation =0; %Validates output with already prepared true vector:
% + false --> Does not validate
% + true  --> Validates output from classificaion vs
%current classification

Verbosity = 0;     %WORK IN PROGRESS --> controls amount of informaton that is shown
% + 0 --> Fully Automatic. Also with labeling
% + 1 --> always showing plots and always asking user for
%         opinion

if ~isfield(rc, 'Data_volume')

    Data_volume = 'all'; %Controlls whether one will analyse all data or only best iterations
else
    Data_volume = rc.Data_volume;
end
%+ 'best' --> processing only best iteration
%+ 'all'  --> procesing all iterations

Unsure_only = 0;        %analyse only labels that were left unsure
classification_threshold = 0.5;
classif_table_all = struct();

% gpuDevice([])

%% %----> load data <----

currentFolder = fullfile(rc.analysisFolder, '6_ICA2');

if exist(currentFolder) % reading 'infile' file
    infile_all = sc_reading(currentFolder, '*ica2.mat');  % screading : lsit of  files with specific extrnsions
    infile = infile_all;
else
    error( "There are no input files '/6_ICA2' folder.Most likely ICA decomposition data haven't been saved");
end

if exist('begId') && exist('endId')
    infile = infile_all(begId : endId);
end

clear data_all_arj data_all_ica1 data_all_ica2

if ~exist('begId'); begId=1; end


clear channels code_dir Cx_image seg.demean detect_flank e event_type rc.expFolder i j k chan.layout_type limit_ch load_file m_art_padding m_flt_padding m_hp m_lp m_ord m_th m_trl_padding m_type artifactFolder rc.analysisName filter import_ref_chan infile_all plot_chan_var recodeFn rc.save_artf rc.save_ica1 th_ch topo_z_value_th trig_list useParallel bdfFolder  tr_z_value_th

%%

ica2stat = { 'dsname' 'best_iter' 'IC_all' 'IC_brain' 'var orig' 'var ica' 'var brainIC' 'var resid' '%var_brainIC' '%var_ICAresid'};  % save log with number of components found at ica1
progressfile = fullfile (rc.analysisFolder, '6_ICA2', 'class_progress.txt');

for ds = 1 : length(infile)

    [~, dsname, ~] = fileparts(infile{ds}); % we want only name
    [classif_table,ica2stat1] = sc_5_ds_classify_meg(infile, ds, rc, chan, ica, seg, currentFolder,progressfile, Data_volume, classification_threshold, Mode, Unsure_only, Validation, Verbosity, model_type);
    for l = 1:length(ica2stat1)
        ica2stat{ds+1,l} = ica2stat1{l};
    end

    for iter = 1:length(classif_table)
        classif_table_all.("ds_"+dsname).(char(sprintf("Iter_%s",string(iter)))) = classif_table{iter};
        Y_all = [Y_all ;classif_table{iter}.Y];
        predictions_all = [predictions_all; classif_table{iter}.Proposed_Classification];
        prob_values_all = [prob_values_all; classif_table{iter}.prob_values];
    end
end


%% save 
save(fullfile(currentFolder,"classif_table.mat"),'classif_table_all','-v7.3');  % '-v6' v6 added for speedup
save(fullfile(currentFolder,"ica2stat.mat"),'ica2stat','-v7.3');  % '-v6' v6 added for speedup


fid = fopen(progressfile, 'a+');
fprintf(fid, '\n');
fprintf(fid, 'all requested ds classified');
fclose(fid);


if Validation == true && strcmp(Mode,'class')
    %Checking model accuracy
    class_rep_1 = classification_report(predictions_all,double(Y_all));

    confMat_1 = confusionmat(double(Y_all),predictions_all);
    set(0,'DefaultFigureVisible','off');

    figure('Name','Confusions')
    subplot(2,2,1)
    heatmap(confMat_1)

    subplot(2,2,2)
    [Xs,Ys] = perfcurve(double(Y_all),prob_values_all/5,1);
    plot(Xs,Ys)

    text(.75,.275,sprintf("Accuracy: %0.2f",class_rep_1.Accuracy))
    text(.75,.2,sprintf("Precision: %0.2f",class_rep_1.Accuracy))
    text(.75,.125,sprintf("Recall: %0.2f",class_rep_1.Accuracy))
    text(.75,.05,sprintf("F1 score: %0.2f",class_rep_1.Accuracy))

    fig_handle = gcf;
    print(gcf,'-dpng', strcat(currentFolder,'/',strcat('validation_map.png')));
    close(fig_handle)
    disp(class_rep_1)


end

%% Functions

% %%Functions for Own_CLassifier
% function [X,Corr] = preprocessMiniBatch(XCell,XCorr)
% 
% X = cat(4,XCell{:});
% Corr = cat(1,XCorr{:})';
% % Y = cat(2,YCell{:});
% % Y = onehotencode(Y,1,'ClassNames',[1 0]);
% end

% function [classesPredictions,raw_pred] = ownPredictions(dlnet,mbq,classes)
%     %%% Old Function that fetches the data in Batches - for making
%     %%% predicitons based on Joint Model (Depreceated)
%     classesPredictions = [];
%     raw_pred = [];
% 
%     while hasdata(mbq)
%         [dlX1,dlX2] = next(mbq);
% 
%         % Make predictions using the model function.
%         dlYPred = predict(dlnet,dlX1,dlX2);
%         raw_pred = [ raw_pred dlYPred(1,:)];
%         % Determine predicted classes.
%         YPredBatch = onehotdecode(dlYPred,classes,1);
%         classesPredictions = [classesPredictions YPredBatch];
% 
%     end
% 
% end
