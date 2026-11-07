function sc_validationPlot_test(predictions,Y,prob_values,currentFolder,dsname,indeks)
    %%% This function is making a quick validation plot for Outputs of a
    %%% model. It contains Performance Matrix/ ROC curve and classic
    %%% performance metrics: Accuracy,F1, Precision, Recall:


    class_rep_1 = classification_report(predictions,double(Y));
    [fp,tp,~,auc] = perfcurve(categorical(Y), prob_values,categorical(1));

    set(0,'DefaultFigureVisible','on')
    figure('Position', [100 100 1200 900])
    %     CONFMAT
    subplot(1,2,1)
    confusionchart(predictions,double(Y));
    title("Confusion Chart for All Data")
    %     ROCAUC
    subplot(1,2,2)
    plot(fp,tp,'LineWidth',1.8); grid on
    xlabel('False positive rate'); ylabel('True positive rate');
    title(sprintf('ROC (AUC = %.3f)', auc));
    sgtitle("All Data Model Fit")

    %     Performance Review
    text(0.68,.575,sprintf("Accuracy: %0.2f",class_rep_1.Accuracy))
    text(0.68,.5,sprintf("Precision: %0.2f",class_rep_1.Precision))
    text(0.68,.425,sprintf("Recall: %0.2f",class_rep_1.Recall))
    text(0.68,.35,sprintf("F1 score: %0.2f",class_rep_1.F1_score))

    if ~strcmp(dsname,"")
        print(gcf,'-dpng', strcat(currentFolder, '/',dsname,'/',strcat('validation_map',indeks,'.png')));
    else
        print(gcf,'-dpng', strcat(currentFolder,'/',strcat('validation_map',indeks,'.png')));
    end
    close(gcf);

end