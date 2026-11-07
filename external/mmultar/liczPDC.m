function [wyn,minv,maxv]=liczPDC(s,h,a,vflag)
% internal procedure returns PDC
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

[wyn,maxv]=liczPDC0(a);

minv=0;
maxv=1;
