%function plot_smult_ar(s,h,a,mv,basev,savname,AR)
function plot_smult_ar(s,h,a,mv,basev,savname,ARs)
% plotting and saving selected functions
% in short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(s,1);
frqpmax=size(s,3);
winnum=size(s,4);

opis=mv.opisy;

prfigname=mv.fname;
    
global FVL FVS
fnumbs1=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs1,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);

fnumbs=getfunccalcnumbers(mv);

for i=fnumbs1
    [datv,minv,maxv]=FVL{i}.f(s,h,a,1);
    if ~isempty(basev)
        ixbn=find(fnumbs==i);
        datb=squeeze(basev(ixbn,:,:,1,:));
        for ii2=1:frqpmax
            dv1=squeeze(datv(:,:,ii2,:));
            dv1(dv1<datb)=NaN;
            datv(:,:,ii2,:)=dv1;
        end
    end
    smultipcolor(datv,minv,maxv,FVL{i}.tt,{prfigname FVL{i}.sx},opis,mv.savefigs,mv.pautoflag);
end

fnumbs2=getfuncsavenumbers(mv);

for i=fnumbs2
    if ismember(i,fnumbs)
        datv=FVS{i}.f(s,h,a,0);
        eval(['[' FVS{i}.vn ']=datv;']);
        save(savname,'-append',FVS{i}.vn);
        clear(FVS{i}.vn);
    end
end

if mv.sAR
    %H=h;
    %save(savname,'-append','AR','H');
    ARs.H=h;
    save(savname,'-append','ARs');
end
