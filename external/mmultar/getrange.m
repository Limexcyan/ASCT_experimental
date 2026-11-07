function rng=getrange(rngstr,chans)
% translates string with selected channels into matlab numeric array
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

r=rngstr;
r(findstr(r,' '))=[];
poss=findstr(r,'-');
r(poss)=':';
chs=sprintf('%d',chans);
for p=length(poss):-1:1
    if poss(p)==length(r)
        r=[r chs];
        if poss(p)==1
            r=['1' r];
        elseif ~isnumc(r(poss(p)-1))
            r=[r(1:poss(p)-2) '1' r(poss(p)-1:length(r))];
        end
    elseif poss(p)==1
        r=['1' r];
        if ~isnumc(r(poss(p)+2))
            r=[r(1:poss(p)+1) chs r(poss(p)+2:length(r))];
        end
    elseif ~isnumc(r(poss(p)+1))
        r=[r(1:poss(p)) chs r(poss(p)+1:length(r))];
    elseif ~isnumc(r(poss(p)-1))
        r=[r(1:poss(p)-2) '1' r(poss(p)-1:length(r))];
    end
end
rng=eval(['[' r ']']);

        
        
