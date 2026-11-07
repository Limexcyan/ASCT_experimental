function [classesPredictions,raw_pred] = sc_jointDLPredictions(dlnet,mbq,classes)
    %%% Old Function that fetches the data in Batches - for making
    %%% predicitons based on Joint Model (Depreceated)
    % Requites Net, Mnini-Batch Quese and Classess to one hot encode to
    % functiojn

    classesPredictions = [];
    raw_pred = [];

    while hasdata(mbq)
        [dlX1,dlX2] = next(mbq);

        % Make predictions using the model function.
        dlYPred = predict(dlnet,dlX1,dlX2);
        raw_pred = [ raw_pred dlYPred(1,:)];
        % Determine predicted classes.
        YPredBatch = onehotdecode(dlYPred,classes,1);
        classesPredictions = [classesPredictions YPredBatch];

    end

end