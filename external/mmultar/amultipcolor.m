function gmax=amultipcolor(ax,dat,globmin,globmax,stitle,fname,opisy,pautoflag,prfig)
%plot for short time matrix results, no bootstrap
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

if ishandle(ax)
    %axes(ax);
end
cla;

sz=size(dat);
rows=sz(1);
cols=sz(2);
yrws=sz(3);
xcls=sz(4);
axis([0 rows 0 cols])
if pautoflag~=0
    gmax=find_wyn_maxv(dat)*pautoflag;
else
    gmax=globmax;
end

datmat=zeros(rows*yrws+1,cols*xcls+1); % for pcolor
for row=1:rows
    for col=1:cols
        datmat(((row-1)*yrws+1):(row*yrws),...
               ((col-1)*xcls+1):(col*xcls))=squeeze(dat(row,col,yrws:-1:1,:));
    end
end
if sum(sum(isnan(datmat)))>0
    line_color='black';
else
    line_color='white';
end
datmat(:,end)=datmat(:,end-1); datmat(end,:)=datmat(end-1,:); aix=0.5;
pcolor(datmat); shading flat; axis ij; caxis([globmin gmax]);
line('Xdata',[0.5 cols*xcls+0.5]+aix,'Ydata',[rows*yrws+0.5 rows*yrws+0.5]+aix,'Color',line_color,'LineWidth',2); 
line('Xdata',[0.5 0.5]+aix,'Ydata',[0.5 rows*yrws+0.5]+aix,'Color',line_color,'LineWidth',2); 
for row=0:rows
    line('Xdata',[0.5 cols*xcls+0.5]+aix,'Ydata',[row*yrws+0.5 row*yrws+0.5]+aix,'Color',line_color,'LineWidth',2); 
    line('Xdata',[row*xcls+0.5 row*xcls+0.5]+aix,'Ydata',[0.5 rows*yrws+0.5]+aix,'Color',line_color,'LineWidth',2); 
end
set(gca,'TickDir','out');
set(gca,'XTick',(0.5*(xcls):(xcls):((cols)*(xcls)))+1,'YTick',(0.5*yrws:yrws:((rows)*yrws))+1);
if nargin<4
    xtk=cell(1,rows);
    ytk=cell(1,rows);
    for i=1:rows
        xtk{i}=sprintf('%d',i);
        %ytk{i}=sprintf('%d',rows-i+1);
    end
else
    xtk=cell(1,rows);
    ytk=cell(1,rows);
    xtk(1:min(rows,length(opisy)))=opisy(1:min(rows,length(opisy)));
    %ytk(1:min(rows,length(opisy)))=opisy(1:min(rows,length(opisy)));
end
set(gca,'XTickLabel',xtk,'YTickLabel',xtk);
[f_p,f_n,f_e]=fileparts(fname{1});
title(untex([stitle ' (' f_n f_e ')']));
