function c=snormDTFs(h,s)
% calculates normalized DTF in short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(h);
chans=sz(1);
frqpmax=sz(3);
c=zeros(size(s));
if length(sz)<4
    winnum=1;
else
    winnum=sz(4);
end


mxs=0;
for win=1:winnum
    for frqp=1:frqpmax
        mxs=max(mxs,max(diag(abs(squeeze(s(:,:,frqp,win))))));
    end
end

for win=1:winnum
    denom=sum(abs(squeeze(h(:,:,:,win))).^2,2);
    for row=1:chans
        for col=1:chans
            if row==col
                c(row,row,:,win)=abs(s(row,row,:,win))/mxs;
            else
                c(row,col,:,win)=abs(squeeze(h(row,col,:,win)).^2./squeeze(denom(row,1,:)));
            end
        end
    end
end
