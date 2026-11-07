function [trigger]=load_evt(evt_filename)

if nargin < 1

[f d]  = uigetfile({'*.evt','EVT file (*.evt)'});

evt_filename=[d f];

end

trigger=[];

fid=fopen(evt_filename,'rt');

tline=fgetl(fid);

    while 1
        tline = fgetl(fid);
        if ~ischar(tline) | length(tline)==0, break, end
        vect=str2num(tline);
        trigger=[trigger ; vect([1 3])];
    end
    
fclose(fid);