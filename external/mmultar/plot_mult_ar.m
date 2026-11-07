%function hnd=plot_mult_ar(hnd,s,h,a,mv,trial,maxtr,basev,savname,ARt)
function hnd=plot_mult_ar(hnd,s,h,a,mv,trial,maxtr,basev,savname,ARs)
% plotting and saving selected functions
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

% chans=size(s,1);
% frqpmax=size(s,3);

%%% MD
% set(0,'DefaultFigureVisible',mv.visible_fig);
%%%
opis=mv.opisy;

if any([mv.sDTF mv.sSpect mv.sNDTF mv.sCohs mv.sdDTF mv.sPDC mv.sAR mv.sffDTF])
    if maxtr>1
        nmd=floor(log10(maxtr))+1;
        sf1=sprintf('%s0%dd','%',nmd);
        sf2=sprintf(sf1,trial);
        ending=['_' sf2];
    else
        ending='';
    end
end

prfigname=mv.fname;
if maxtr>1
    nmd=floor(log10(maxtr))+1;
    sf1=sprintf('%s0%dd','%',nmd);
    sf2=sprintf(sf1,trial);
    prfigname=[mv.fname '_' sf2];
end

global FVL FVS
fnumbs1=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs1,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);

if mv.incl_instant
    figure
    imagesc(abs(ARs.inst_sub1_B0+ARs.inst_sub1_B0'));
    gmap=colormap('gray');
    invgray=gmap(64:-1:1,:);
    colormap(invgray);
    caxis([0 1]);
end

for i=1:FUNS
    funcode=fnumbs(i);
    if ismember(funcode,fnumbs1)
        [datv,minv,maxv]=FVL{funcode}.f(s,h,a,1);
        if ~isempty(basev)
            bv=squeeze(basev(i,:,:,1));
        else
            bv=[];
        end
        if (isfield(hnd,FVL{funcode}.hn)) && (ishandle(hnd.(FVL{funcode}.hn)))
            update_smultiplot(hnd.(FVL{funcode}.hn),datv,minv,maxv,{prfigname,FVL{funcode}.sx},bv,0,mv.pautoflag)
        else
            %%% MD
%             set(0,'DefaultFigureVisible',mv.visible_fig);
            %%%
            hnd.(FVL{funcode}.hn)=smultiplot(datv,minv,maxv,FVL{funcode}.tt,{prfigname,FVL{funcode}.sx},opis,mv.savefigs,bv,0,mv.pautoflag);
        end
    end
end

for i=fnumbs2
    if ismember(i,fnumbs) % bylo policzone
        datv=FVS{i}.f(s,h,a,0);
        svvarnam=[FVS{i}.vn ending];
        eval(['[' svvarnam ']=datv;']);
        save(savname,'-append',svvarnam);
        clear(FVS{i}.vn);
    end
end

if mv.sAR
    %eval(['AR' ending '=ARt;']);
    %eval(['H' ending '=h;']);
    %save(savname,'-append',['AR' ending],['H' ending]);
    %eval(['ARs' ending '.coefs=ARs0.coefs;']);
    %eval(['ARs' ending '.H=h;']);
    %eval(['ARs' ending '.V=ARs0.V;']);
    save(savname,'-append',['ARs' ending]);
end
