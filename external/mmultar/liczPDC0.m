function [c,mxs]=liczPDC0(a)
% calculates partial directed coherence (PDC)
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(a);
chans=sz(1);
frqpmax=sz(3);
if length(sz)>3
    winnum=sz(4);
    c=zeros(size(a));
    mxs=0;
    for win=1:winnum
        for frqp=1:frqpmax
            mxs=max(mxs,max(diag(abs(a(:,:,frqp,win)))));
        end
    end
    for win=1:winnum
        denom=squeeze(sum(abs(a(:,:,:,win)).^2,1));
        for row=1:chans
            for col=1:chans
                c(row,col,:,win)=abs(squeeze(a(row,col,:,win)).^2./squeeze(denom(col,:)'));
            end
        end
    end
else
    denom=squeeze(sum(abs(a).^2,1));
    mxs=0;
    for frqp=1:frqpmax
        mxs=max(mxs,max(diag(abs(a(:,:,frqp)))));
    end
    c=zeros(size(a));
    for row=1:chans
        for col=1:chans
            c(row,col,:)=abs(squeeze(a(row,col,:)).^2./squeeze(denom(col,:)'));
        end
    end
end
