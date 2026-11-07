function saveBaseln(savname,mv,basev,fnumbs,fnumbs2,ending)
% saves baseline results
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

global FVS

FUNS=length(fnumbs);
multi_case=length(size(basev))>5;
for funn=1:FUNS
    funcode=fnumbs(funn);   % kolejny numer ppoliczonej funkcji
    if ismember(funcode,fnumbs2) % jesli jest to funkcja zaznaczona do zapisu to zapisz
        if multi_case
            datv=squeeze(basev(funn,:,:,:,:,:)); 
        else
            datv=squeeze(basev(funn,:,:,:,:));  
        end
        eval(['[' FVS{funcode}.vn '_base' ending ']=datv;']);
        save(savname,'-append',[FVS{funcode}.vn '_base' ending]);
        clear(FVS{funcode}.vn);
    end
end
