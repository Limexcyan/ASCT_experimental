function fnb=getfunccalcnumbers(mv)
% internal procedure
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

fnb=[];
if mv.pSpect fnb=union(fnb,1); end
if mv.pCohs fnb=union(fnb,2); end
if mv.pDTF fnb=union(fnb,3); end
if mv.pNDTF fnb=union(fnb,4); end
if mv.pdDTF fnb=union(fnb,5); end
if mv.pPDC fnb=union(fnb,6); end
if mv.pffDTF fnb=union(fnb,7); end
