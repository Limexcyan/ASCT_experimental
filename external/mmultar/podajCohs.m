function wyn=podajCohs(s,h,a,vflag)
% internal procedure
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)
if length(size(s))>3
    wyn=skoherencje(s);
else
    wyn=koherencje(s);
end

