
icnum = 1:14;   % number of ICs to plot
addsubplot = 0;

col = (ceil(length(icnum+addsubplot)^0.5)+1);
rws = ceil(length(icnum+addsubplot)/col);
% col = 2; rws = 2;
% titletxt

figure('visible', 'on');
for i = 1:length(icnum)     % top view
    subplot(rws,col,i);
    ssource = data_icloc(icnum(i));
    act = ssource.avg.pow(:,1)*1000000; % component to be plotted
    % if i == 1
    %     actav = act;
    % else
    %     actav = actav + act;
    % end
    ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm', 'edgealpha', 0.1, 'facecolor', 'none', 'edgecolor', 'none');
    view([0 90]); h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
    title(['IC ' num2str(icnum(i))]);
end

% actav = actav / length(icnum);
% subplot(rws,col,i+1);
% ft_plot_mesh(ssource, 'vertexcolor', actav, 'unit', 'mm', 'edgealpha', 0.1, 'facecolor', 'none', 'edgecolor', 'none');
% title('IC combined')
% saveas()

aa = bb;

figure('visible', 'on');
for i = 1:length(icnum)     % top view
    subplot(rws,col,i);
    ssource = data_icloc(icnum(i));
    act = ssource.avg.pow(:,1); % component to be plotted
    ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
    view([90 0]); h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
    title(['IC ' num2str(icnum(i))]);
end
title(titletxt)


figure('visible', 'on');
for i = 1:length(icnum)     % top view
    subplot(rws,col,i);
    ssource = data_icloc(icnum(i));
    act = ssource.avg.pow(:,1); % component to be plotted
    ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
    view([180 0]); h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
    title(['IC ' num2str(icnum(i))]);
end
title(titletxt)

%
% %leftonly
% left = sort(find(ssource.pos(:,1)<0),'descend');
% % right = ssource.pos(:,1)>0;
% ssource0 = ssource;
%
% for r=1:length(left)
% ssource0.inside(left(r)) = [];
% ssource0.pos(left(r),:) = [];
% ssource0.avg.mom{left(r)} = [];
% ssource0.avg.pow(left(r)) = [];
% end
%
%
% figure('visible', 'on');
% for i = 1:length(icnum)     % top view
% subplot(rws,col,i);
% % ssource0 = data_icloc(icnum(i));
% act = ssource0.avg.pow(:,1); % component to be plotted
% ft_plot_mesh(ssource0, 'vertexcolor', act, 'unit', 'mm', 'edgealpha', 0.1, 'facecolor', 'none', 'edgecolor', 'none');
% view([0 90]); h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
% title(['IC ' num2str(icnum(i))]);
% end
% title(titletxt)
% % saveas()




% ft_plot_mesh(ssource, 'vertexcolor', act1, 'unit', 'mm');

% ft_plot_mesh(ssource);


%
%
%
%
% figure('visible', 'on');
% for i = 1     % top view
% % subplot(col,rws,i);
% ssource = sourceloc(i);
% act = ssource.avg.pow(:,1); % component to be plotted
% % ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
% ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
% view([0 90]); h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
% title(['IC ' num2str(i)]);
% end

% i=3
% ssource = data_icloc(i);
% act = ssource.avg.pow(:,1); % component to be plotted
% ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
% ft_plot_mesh(ssource, 'vertexcolor', act, 'edgecolor', [0.6 0.6 0.6], 'edgealpha', 0.5)
%
%
