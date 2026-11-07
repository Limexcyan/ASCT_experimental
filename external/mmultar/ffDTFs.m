function c=ffDTFs(h,s)
% calculates ffDTF 
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(h);
chans=sz(1);
frqpmax=sz(3);
if length(sz)>3
    winnum=sz(4);
    c=zeros(size(s));
    mxs=0;
    for win=1:winnum
        for frqp=1:frqpmax
            mxs=max(mxs,max(diag(abs(s(:,:,frqp,win)))));
        end
    end
    for win=1:winnum
        denom=sum(abs(h(:,:,:,win)).^2,2);
        denom=squeeze(sum(denom,3));
        for row=1:chans
            for col=1:chans
                if row==col
                    c(row,row,:,win)=abs(s(row,row,:,win))/mxs;
                else
                    c(row,col,:,win)=abs(squeeze(h(row,col,:,win)).^2/denom(row));
                end
            end
        end
    end
else
    denom=sum(abs(h).^2,2);
    denom=squeeze(sum(denom,3));
    mxs=0;
    for frqp=1:frqpmax
        mxs=max(mxs,max(diag(abs(s(:,:,frqp)))));
    end
    c=zeros(size(s));
    for row=1:chans
        for col=1:chans
            if row==col
                c(row,row,:)=abs(s(row,row,:))/mxs;
            else
                c(row,col,:)=abs(squeeze(h(row,col,:)).^2/denom(row));
            end
        end
    end
end
