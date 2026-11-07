function dat=wczytaj_dane(fname,formt,chans,dlug,trials)
% reads data file
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

fid=fopen(fname,'rb');
if fid<=0
    fprintf('Cannot open data file: %s\n',fname);
    dat=[];
    return
end
switch formt
    case {'float32','int16','int32','float64'}
        dat=fread(fid,formt);
    case 'ASCII'
        %fclose(fid);
        dat=load(fname);
        dat=reshape(dat,chans,trials,dlug);
        dat=permute(dat,[1 3 2]);
    case 'MAT file'
        %fclose(fid);
        c=whos('-file',fname);
        if length(c)>1
            [sel,vl] = listdlg('PromptString','Select a variable:',...
                'SelectionMode','single',...
                'ListString',{c.name});
            if vl==0
                dat=[];
                return;
            else
                numv=sel;
            end
        else
            numv=1;
        end
        dat=getfield(load(fname,c(numv).name),c(numv).name);
        %dat=reshape(dat,[chans dlug trials]);
end
fclose(fid);
if nargin<5
    trials=1;
end
%sd=size(dat);
dat=reshape(dat,chans,dlug,trials);
disp(size(dat))