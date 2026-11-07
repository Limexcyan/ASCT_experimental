function [wyn,minv,maxv]=liczCohs(s,h,a,vflag)
% internal procedure returns modulus of coherences
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if length(size(s))>3
    wyn=abs(skoherencje(s));
else
    wyn=abs(koherencje(s));
end
minv=0;
maxv=1;