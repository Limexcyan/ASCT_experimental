function showfield_general(z,loc,lab); 
% usage showfield_general(z,loc); 
% displays fields/potentials specified z in channels at locations 
% specified in locs as a contour-plot

scal=[-max(max(abs(z))),max(max(abs(z)))];

[n,m]=size(loc);
x=loc(:,1);
y=loc(:,2);

xlin = linspace(1.4*min(x),1.4*max(x),250);
ylin = linspace(1.4*min(y),1.4*max(y),250);
[X,Y] = meshgrid(xlin,ylin);
Z = griddata(x,y,z,X,Y,'invdist');
%Z = griddata(x,y,z,X,Y,'nearest');


  % Take data within head
  rmax=1.02*max(sqrt(x.^2+y.^2));
  mask = (sqrt(X.^2+Y.^2) <= rmax);
  ii = find(mask == 0);
  Z(ii) = NaN;
  
  
surface(X,Y,zeros(size(Z)),Z,'edgecolor','none');shading interp;
%caxis([ - max(abs(z)) max(abs(z))]);
caxis(scal);
hold on;
plot(x,y,'.k','markersize',2);

if nargin > 2
for i=1:length(x)
    text(x(i),y(i),num2str(lab(i)));
end
end

meanx=mean(loc(:,2)*.85+.45);
meany=mean(loc(:,3)*.85+.45);
scalx=1;
drawhead(0,0,rmax,scalx);
%set(gca,'visible','off');
set(gca,'Color',[0.8 0.8 0.8],'XColor',[0.8 0.8 0.8],'YColor',[0.8 0.8 0.8]);

axis([-1.2*rmax 1.2*rmax -1.0*rmax 1.4*rmax]);
h=colorbar;
set(h,'fontweight','bold')
%plot(.985*rmax*sin((0:1000)/1000*2*pi), .985*rmax*cos((0:1000)/1000*2*pi),'linewidth',2,'color','k'); 
return; 
function drawhead(x,y,size,scalx);

cirx=(x+scalx*size*cos((1:1000)*2*pi/1000) )';ciry=(y+size*sin((1:1000)*2*pi/1000))';

plot(cirx,ciry,'k','linewidth',1);
hold on;

ndiff=20;
plot( [x  cirx(250-ndiff) ],[y+1.1*size ciry(250-ndiff)],'k','linewidth',1);
plot( [x  cirx(250+ndiff) ],[y+1.1*size ciry(250+ndiff)],'k','linewidth',1);


return;
