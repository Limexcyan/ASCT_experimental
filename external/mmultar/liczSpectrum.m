function [wyn,minv,maxv]=liczSpectrum(s,h,a,vflag)
% internal procedure returns modulus of power spectrum
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

wyn=abs(s);
if vflag
    minv=0;
    maxv=max(max(max(max(abs(s)))));
else
    minv=0;
    maxv=1;
end