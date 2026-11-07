function a=zerujdiag(a)
% internal procedure for removing diagonal matrix elements
% in short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

sz=size(a);
for i=1:sz(3)
    for j=1:sz(2)
        a(j,j,i)=0.;
    end
end
