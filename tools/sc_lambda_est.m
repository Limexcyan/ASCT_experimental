% script for estimating regularization paramerter lambda
% in order to run it, ExSetup should:
% 1) be set to perform step 8 only and
% 2) contain parameter rc.lambdaScan = 1;
% 3) loc.norm shoulb set to 'cov' to use SNR and data for lambda est.


params = [0.1, 0.4, 1, 1.5, 2, 3, 5, 7, 10, 12, 15];   % snr value to scan by
ic2plot = 12; % how many brain IC to plot


%%% DO NOT EDIT BELOW %%%

icnum = 1:ic2plot; 

col = (ceil(length(icnum)^0.5));
rws = ceil(length(icnum)/col);

% col = 4; rws = 3;

  % IC number to plot

for la=1:length(params)

    clear sourceloc

    for i = 1 : size(mixing,2)
        tlck.avg = mixing(:,i);
        if strcmp(loc.norm, 'lambda')  %unitary lambda for all subjects
            titletxt = ['lambda ' num2str(params(la)), '%.1f'];
                        cfg.mne.lambda  = params(la);

        end
        if strcmp(loc.norm, 'cov')      %indiv cov matrix
            titletxt = ['snr ' num2str(params(la), '%.1f')];
            loc.noiseLev = params(la);
            cfg.mne.snr = sqrt( mean( (mixing(:,i) - mean( mixing(:,i) ) ).^2 ) )/loc.noiseLev;
            noisevec(i) = cfg.mne.snr;
        end
        sourceloc(i) = ft_sourceanalysis(cfg, tlck);
    end

    % add some relevant fields
    for i = 1:size(mixing,2)

        sourceloc(i).val  = val(i);
        sourceloc(i).time = i;
        if strcmp(loc.norm, 'cov')
            sourceloc(i).snr  = noisevec(i);
        end
        if isfield(sourceloc(i),'tri'),            sourceloc(i).tri            = sourceloc(i).tri;            end
        if isfield(sourceloc(i),'brainstructure'), sourceloc(i).brainstructure = sourceloc(i).brainstructure; end
        if isfield(sourceloc(i),'brainstructurelabel'), sourceloc(i).brainstructurelabel = sourceloc(i).brainstructurelabel; end

    end

    % choosing only brain components
    brain_IC = data_ica2.ICA.iter(data_ica2.ICA.best_iter.index).brain_ic;   %FIXME - cut nonbrain before calculations

    data_icloc = sourceloc(brain_IC);
    %tutaj

    data_icloc = rmfield(data_icloc,'cfg');
    disp(['DS: ' dsname ' - saving ICLOC data']);
    
    if ~exist(fullfile(savefolder, 'lambdafigs'))
        mkdir(fullfile(savefolder, 'lambdafigs'))
    end
    if ~exist(fullfile(savefolder, 'lambdamat'))
        mkdir(fullfile(savefolder, 'lambdamat'))
    end
    
    save( fullfile(savefolder, 'lambdamat', strcat(dsname, '_icloc_',  titletxt, '.mat')), 'data_icloc');




    gcf = figure('visible', 'on');
    set(gcf,'units','pixels','position',[500,500,1200,900]);
    for i = 1:length(icnum)     % top view
        subplot(rws,col,i);
        ssource = data_icloc(icnum(i));
        act = ssource.avg.pow(:,1); % component to be plotted
        ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
        view([0 90]); 
        % h = light; set(h, 'position', [-5 10 0.2]); lighting gouraud; material dull
        subTitle(['IC ' num2str(brain_IC(i))]);
    end
    title(titletxt);
    saveas(gcf, fullfile(savefolder, 'lambdafigs', strcat('top_', titletxt, '.jpg')))
    close(gcf)

    gcf = figure('visible', 'on');
    set(gcf,'units','pixels','position',[500,500,1200,900]);
    for i = 1:length(icnum)     % top view
        subplot(rws,col,i);
        ssource = data_icloc(icnum(i));
        act = ssource.avg.pow(:,1); % component to be plotted
        ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
        view([0 -90]); 
        % % h = light; set(h, 'position', [100 -100 0]); lighting gouraud; material dull
        subTitle(['IC ' num2str(brain_IC(i))]);
    end
    title(titletxt);
    saveas(gcf, fullfile(savefolder, 'lambdafigs', strcat('bot_', titletxt, '.jpg')))
    close(gcf)

    gcf = figure('visible', 'on');
    set(gcf,'units','pixels','position',[500,500,1200,900]);
    for i = 1:length(icnum)     % top view
        subplot(rws,col,i);
        ssource = data_icloc(icnum(i));
        act = ssource.avg.pow(:,1); % component to be plotted
        ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
        view([90 0]);
        % h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
        subTitle(['IC ' num2str(brain_IC(i))]);
    end
    title(titletxt);
    saveas(gcf, fullfile(savefolder, 'lambdafigs', strcat('rig_', titletxt, '.jpg')))
    close(gcf)

    gcf = figure('visible', 'on');
    set(gcf,'units','pixels','position',[500,500,1200,900]);
    for i = 1:length(icnum)     % top view
        subplot(rws,col,i);
        ssource = data_icloc(icnum(i));
        act = ssource.avg.pow(:,1); % component to be plotted
        ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
        view([-90 0]);
        % h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
        subTitle(['IC ' num2str(brain_IC(i))]);
    end
    title(titletxt);
    saveas(gcf, fullfile(savefolder, 'lambdafigs', strcat('lef_', titletxt, '.jpg')))
    close(gcf)

    gcf = figure('visible', 'on');
    set(gcf,'units','pixels','position',[500,500,1200,900]);
    for i = 1:length(icnum)     % top view
        subplot(rws,col,i);
        ssource = data_icloc(icnum(i));
        act = ssource.avg.pow(:,1); % component to be plotted
        ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
        view([-180 0]); 
        % h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull
        subTitle(['IC ' num2str(brain_IC(i))]);
    end
    title(titletxt);
    saveas(gcf, fullfile(savefolder, 'lambdafigs', strcat('fro_', titletxt, '.jpg')))
    close(gcf)

    gcf = figure('visible', 'on');
    set(gcf,'units','pixels','position',[500,500,1200,900]);
    for i = 1:length(icnum)     % top view
        subplot(rws,col,i);
        ssource = data_icloc(icnum(i));
        act = ssource.avg.pow(:,1); % component to be plotted
        ft_plot_mesh(ssource, 'vertexcolor', act, 'unit', 'mm');
        view([0 0]); 
        % h = light; set(h, 'position', [ 1 0 0.2]); lighting gouraud; material dull
        subTitle(['IC ' num2str(brain_IC(i))]);
    end
    title(titletxt);
    saveas(gcf, fullfile(savefolder, 'lambdafigs', strcat('bck_', titletxt, '.jpg')))
    close(gcf)


end

disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
disp('Files for alpha estimation saved. Refer to the manual.')
disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
error('Analysis terminated but files were saved.')
