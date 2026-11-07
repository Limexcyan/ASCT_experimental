function [wyn,minv,maxv]=liczNDTF(s,h,a,vflag)
% claculates non-normalized DTF
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(s,1);
mxn=0;
if vflag
    if length(size(s))>3
        for row=1:chans
            for col=1:chans
                if row~=col
                    mxn=max(mxn,max(max(abs(s(row,col,:,:).^2))));
                end
            end
        end
    else
        for row=1:chans
            for col=1:chans
                if row~=col
                    mxn=max(mxn,max(abs(h(row,col,:).^2)));
                end
            end
        end
    end
end

wyn=abs(h).^2;

if vflag
    minv=0;
    maxv=mxn;
else
    minv=0;
    maxv=1;
end
