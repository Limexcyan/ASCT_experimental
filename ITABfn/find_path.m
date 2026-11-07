function [path_raw, path_data] = find_path()
% Find path for .raw files and master header

ff = prefdir;
indx=strfind(ff,'/');
filename_browser = strcat(ff(1:indx(3)),'browser.ini');

ifp = fopen(filename_browser,'r');
if ifp<0
    error('browser.ini file not found')
end

ss = [];
while ~isequal(ss,'[paths]')
    ss = fscanf(ifp,'%s',1);
end
fscanf(ifp,'%s',1);

path_raw = fscanf(ifp,'%s',1);
path_raw = path_raw(10:end);

path_data = fscanf(ifp,'%s',1);
path_data = path_data(11:end);