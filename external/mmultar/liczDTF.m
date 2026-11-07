function [wyn,minv,maxv]=liczDTF(s,h,a,vflag)
% claculates nomalized DTF
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if length(size(s))>3
    wyn=snormDTFs(h,s);
else
    wyn=normDTFs(h,s);
end
minv=0;
maxv=1;
%maxv=0.5;