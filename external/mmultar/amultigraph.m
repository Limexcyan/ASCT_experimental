function gmax=amultigraph(ax,dat,globmin,globmax,stitle,pfname,opisy,prfig,sqflag,pautoflag,basev)
% plot for matrix results, no bootstrap
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if ishandle(ax)
    cla(ax);
else
    ax=gca;
    cla;
end

sz=size(dat);
rows=sz(1);
cols=sz(2);
datlen=sz(3);
dstep=1/(datlen-1);
axis(ax,[0 rows 0 cols])


if prfig
    alw=0;
else
    alw=1;
end
if pautoflag~=0
    gmax=find_wyn_maxv(dat)*pautoflag;
else
    gmax=globmax;
end
if sqflag gmax=sqrt(gmax); end
%axes(ax);
line('Xdata',[0 cols],'Ydata',[rows rows],'Color','black','LineWidth',1+alw,'Parent',ax); 
line('Xdata',[0 0],'Ydata',[0 rows],'Color','black','LineWidth',1+alw,'Parent',ax); 
a=1/(gmax-globmin);
for row=1:rows
    line('Xdata',[0 cols],'Ydata',[row row],'Color','black','LineWidth',1+alw,'Parent',ax); 
    line('Xdata',[row row],'Ydata',[0 rows],'Color','black','LineWidth',1+alw,'Parent',ax);
end
for row=1:rows
    b=rows-row-a*globmin;
    %line('Xdata',[0 cols],'Ydata',[row row],'Color','black','LineWidth',1+alw,'Parent',ax); 
    for col=1:cols
        celldat=squeeze(dat(row,col,:));
        if sqflag
            celldat=sqrt(celldat);
        end
        celldat(celldat<globmin)=globmin;
        celldat(celldat>gmax)=gmax;
        x=[col-1 (col-1):dstep:col col col-1];
        y=[rows-row celldat'.*a+b rows-row rows-row];
        patch(x,y,'b','Parent',ax);
        if ~isempty(basev)
            vl=basev(row,col);
            if sqflag
                vl=sqrt(vl);
            end
            if (vl<=gmax) && (vl>=globmin)
                vl=a*vl+b;
                line('Xdata',[col-1 col],'Ydata',[vl vl],'Color','red','LineWidth',0.5,'Parent',ax);
            end
        end
    end
    %line('Xdata',[row row],'Ydata',[0 rows],'Color','black','LineWidth',1+alw,'Parent',ax);
end
set(ax,'TickDir','out');
set(ax,'XTick',0.5:(cols-0.5),'YTick',0.5:(rows-0.5));
if nargin<5
    xtk=cell(1,rows);
    ytk=cell(1,rows);
    for i=1:rows
        xtk{i}=sprintf('%d',i);
        ytk{i}=sprintf('%d',rows-i+1);
    end
else
    xtk=cell(1,rows);
    ytk=cell(1,rows);
    xtk(1:min(rows,length(opisy)))=opisy(1:min(rows,length(opisy)));
    ytk(rows:-1:rows-min(rows,length(opisy))+1)=opisy(1:min(rows,length(opisy)));
end
set(ax,'XTickLabel',xtk,'YTickLabel',ytk);
[f_p,f_n,f_e]=fileparts(pfname{1});
title(ax,untex([stitle ' (' f_n f_e ')']));
