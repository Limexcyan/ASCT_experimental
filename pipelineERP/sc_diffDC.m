%%% This funcion makes a differential condition by subtracting data from two DC
%%% Please mind that the DataConfiguration are specified in EX_SETUP
%%% The calculated difference is saved as a new DC set in DATA container
%%% Name of this DATA is stored in NAME container. It is either specifed by user in newDClabel or is added automatically
%%% accordingly to the DC number in newDC array
%%% USAGE: [DATA, NAME] = sc_diffDC(DATA, NAME, DCindex1, DCindex2, newDClabel)

function [DATA, NAME] = sc_diffDC(DATA, NAME, DCindex1, DCindex2, newDClabel)

l = length(DATA);

DATA{1 , l + 1} = DATA{1 , l};
DATA{1 , l + 1}.avg = DATA{1 , DCindex1}.avg - DATA{1 , DCindex2}.avg;
%DATA{1 , l + 1}.avg = DATA{1 , newDC(2)}.avg - DATA{1 , newDC(1)}.avg;


% if exist('newDClabel')
    NAME{1, l + 1} = newDClabel;
% else
%     NAME{1, l + 1} = ['DC' num2str( newDC(2) ) ' - DC' num2str( newDC(1) )];
% end


end