function tab = descriptive_stats(oldX,dimension)

    %Fun ction that show Descriptive statistics in table for table of
    %Variables
   X = reshape(table2array(oldX),dimension);
   Names = oldX.Properties.VariableNames;
   disp(mean(X))
   tab = table(mean(X)', std(X)', kurtosis(X)',...
   skewness(X)', max(X)', min(X)',...
   'RowNames',Names,'VariableNames',{'mean','std','kurt','skew','max','min'});

end
