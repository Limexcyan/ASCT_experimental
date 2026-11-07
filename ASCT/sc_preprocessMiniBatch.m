%%Functions for Own_CLassifier
function [X,Corr] = sc_preprocessMiniBatch(XCell,XCorr)

X = cat(4,XCell{:});
Corr = cat(1,XCorr{:})';
% Y = cat(2,YCell{:});
% Y = onehotencode(Y,1,'ClassNames',[1 0]);
end