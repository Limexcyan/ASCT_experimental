function fnb=getfuncsavenumbers(mv)
% internal procedure
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

fnb=[];
if mv.sSpect fnb=union(fnb,1); end
if mv.sCohs fnb=union(fnb,2); end
if mv.sDTF fnb=union(fnb,3); end
if mv.sNDTF fnb=union(fnb,4); end
if mv.sdDTF fnb=union(fnb,5); end
if mv.sPDC fnb=union(fnb,6); end
if mv.sffDTF fnb=union(fnb,7); end
if mv.sAR fnb=union(fnb,8); end
