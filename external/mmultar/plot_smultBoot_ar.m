function plot_smultBoot_ar(sbtfun,mv,basev)
% plotting bootstrapped results for short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
%%% MD
set(0,'DefaultFigureVisible',mv.visible_fig);
%%%
sz=size(sbtfun);
frqpmax=sz(3);

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
        datv=squeeze(sbtfun(:,:,:,funn,:,:));
        if ~isempty(basev)
            ixbn=find(fnumbs==funcode);
            datb=squeeze(basev(ixbn,:,:,1,:));
            for ii1=1:3
                for ii2=1:frqpmax
                    dv1=squeeze(datv(:,:,ii2,ii1,:));
                    dv1(dv1<datb)=NaN;
                    datv(:,:,ii2,ii1,:)=dv1;
                end
            end
        end
        smultipcolor3(datv,0,mxs,FVL{funcode}.tt,{prfigname FVL{funcode}.sx},opis,mv.savefigs,mv.pautoflag);
    end
end
