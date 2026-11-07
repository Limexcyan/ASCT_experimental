function c=koherencje(s)
% calculates ordinary, multiple and partial coherences
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(s);
chans=sz(1);
c=zeros(sz);
d=zeros(sz);
for f=1:sz(3)
    d(:,:,f)=inv(squeeze(s(:,:,f)));
end
for row=1:chans
    for col=1:chans
        if row>col       % koherencja czastkowa
            c(row,col,:)=(-1)^(row+col)*d(col,row,:)./sqrt(d(row,row,:).*d(col,col,:));
        elseif row==col  % koherencja wieloraka
            c(row,row,:)=sqrt(1-(-1)^(row+col)/(s(row,row,:).*d(row,row,:)));
        else         % koherencja zwyczajna
            c(row,col,:)=s(row,col,:)./sqrt(s(row,row,:).*s(col,col,:));
        end
    end
end

c=abs(c);