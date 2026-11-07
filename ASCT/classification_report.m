
function report = classification_report(Preds,Y)
    
    %converting both classes, predictions and true values to string arrays
    classes = string(unique(Y));
    classes_temp = string(unique(Preds));
    preds = Preds;
 
    % Initializing values for True negative, True Positive, False Positive,
    % False Negative
    TN = 0; %True negative
    TP = 0; %True Positive
    FP = 0; %False Positive
    FN = 0; %False Negative
    
    binary=true;
    if binary == true
        for i = 1:length(preds)
            if strcmp(preds(i), classes(1))
                %disp('Yay')
            end
            if  strcmp(string(preds(i)), classes(1)) && strcmp(string(preds(i)) , string(Y(i)))
                TN = TN +1;
                %disp('Yay')
            elseif ~strcmp(string(preds(i)), classes(1)) && strcmp(string(preds(i)) , string(Y(i)))
                TP = TP +1;
                %disp('yay')
            elseif strcmp(string(preds(i)), classes(1)) && ~strcmp(string(preds(i)) , Y(i))
                FP = FP +1;
            elseif ~strcmp(string(preds(i)) , classes(1)) && ~strcmp(string(preds(i)) , Y(i))
                FN = FN +1;
            end
        end 
    else
        disp('You might consider a different method in order to asses Model goodness') 
    end
    
    %Computing parameters (those are literal equations) 
    accuracy = (TP + TN)/(TP+TN+FP+FN);
    precision = TP/(TP+FP);
    recall = TP/(TP+FN);
    F1_score = 2*TP/(2*TP +FP +FN);
    
    %report as structure
    report = struct('Accuracy',accuracy,'Precision',precision,'Recall',recall,'F1_score',F1_score);
    
end
