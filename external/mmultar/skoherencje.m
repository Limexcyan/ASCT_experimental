function c=skoherencje(s)
% calculates three types of coherences in short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(s);
chans=sz(1);
c=zeros(sz);
d=zeros(sz(1:3));
if length(sz)<4
    winnum=1;
else
    winnum=sz(4);
end
for win=1:winnum
    for f=1:sz(3)
        d(:,:,f)=inv(squeeze(s(:,:,f,win)));
    end
    for row=1:chans
        for col=1:chans
            if row>col       % koherencja czastkowa
                c(row,col,:,win)=(-1)^(row+col)*d(col,row,:)./sqrt(d(row,row,:).*d(col,col,:));
            elseif row==col  % koherencja wieloraka
                c(row,row,:,win)=sqrt(1-(-1)^(row+col)/(squeeze(s(row,row,:,win)).*squeeze(d(row,row,:))));
            else         % koherencja zwyczajna
                c(row,col,:,win)=squeeze(s(row,col,:,win))./sqrt(squeeze(s(row,row,:,win)).*squeeze(s(col,col,:,win)));
            end
        end
    end
end
