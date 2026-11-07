function plot_multBoot_ar(sbtfun,mv,bslv)
% plotting bootstrapped results
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)


sz=size(sbtfun);

opis=mv.opisy;

prfigname=mv.fname;

fnumbs1=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs1,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);
global FVL

for funn=1:FUNS
    funcode=fnumbs(funn);
    if ismember(funcode,fnumbs1)
        if ismember(funcode,[1 4])
            mxs=max(max(max(max(squeeze(sbtfun(:,:,:,funn,3,:))))));
        else
            mxs=1;
        end
        dat=squeeze(sbtfun(:,:,:,funn,[1 3]));
        if ~isempty(bslv)
            bslvv=squeeze(bslv(funn,:,:,1));
        else
            bslvv=[];
        end
        smultiplot(dat,0,mxs,FVL{funcode}.tt,{prfigname FVL{funcode}.sx},opis,mv.savefigs,bslvv,1,mv.pautoflag);
    end
end
