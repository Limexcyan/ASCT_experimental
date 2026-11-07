function [wyn,minv,maxv]=liczdDTF(s,h,a,vflag)
% calculates direct DTF
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

frqpmax=size(s,3);
if length(size(s))>3
    co=abs(skoherencje(s));
    winnum=size(s,4);
    for win=1:winnum
        for frq=1:frqpmax
            co(:,:,frq,win)=tril(co(:,:,frq,win),-1)+tril(co(:,:,frq,win),-1)';
        end
    end
else
    co=abs(koherencje(s));
    for frq=1:frqpmax
        co(:,:,frq)=tril(co(:,:,frq),-1)+tril(co(:,:,frq),-1)';
    end
end

ffd=ffDTFs(h,s);

wyn=co.*ffd;

minv=0;
maxv=1;
