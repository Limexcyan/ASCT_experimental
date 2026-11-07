function c=normDTFs(h,s)
% calculates normalized DTF
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(h);
chans=sz(1);
frqpmax=sz(3);
denom=sum(abs(h).^2,2);
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
            c(row,col,:)=abs(squeeze(h(row,col,:)).^2./squeeze(denom(row,1,:)));
        end
    end
end
