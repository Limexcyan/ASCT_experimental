function [wyn,minv,maxv]=liczffDTF(s,h,a,vflag)
% internal procedure returns full frequency DTF
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

wyn=ffDTFs(h,s);

minv=0;
maxv=1;
