function [firstRow,groupId,rowIndex] = asct_m9_group_rows(T,groupColumns)
%ASCT_M9_GROUP_ROWS Group table rows without ambiguous string keys.
% Numeric NaN grouping factors are treated as one level in all supported
% MATLAB releases. A separate mask distinguishes missing values from zero.
assert(istable(T) && iscellstr(groupColumns) && ...
    all(ismember(groupColumns,T.Properties.VariableNames)), ...
    'ASCT:M9:Groups','Invalid grouping columns');

keyTable=T(:,groupColumns);
for j=1:numel(groupColumns)
    name=groupColumns{j};
    column=keyTable.(name);
    if isnumeric(column) && isvector(column) && any(isnan(column))
        missing=isnan(column);
        column(missing)=0;
        keyTable.(name)=column;
        flag=sprintf('asctMissingFlag%d',j);
        while ismember(flag,keyTable.Properties.VariableNames)
            flag=[flag 'X'];
        end
        keyTable.(flag)=missing;
    end
end
[~,firstRow,groupId]=unique(keyTable,'rows','stable');
if nargout>=3
    rowIndex=accumarray(groupId,(1:height(T))', ...
        [numel(firstRow) 1],@(x){x});
end
end
