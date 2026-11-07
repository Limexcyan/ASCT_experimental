% function sc_simstats(rc, seg, design, loc, mv, scansim, begId, endId)

% rc.analysisName = 'S3340_4_[[_1_2_50_0.1]_[_3_4_30_0.1]_]';

ds=1;  % fixme
% design.idPosStart = 1;
% design.idPosEnd   = 13;

% if ~exist(scansim)  % default values if not run from scansim wrapper
scansim.plots_visible = 1;
scansim.output_scaling = 1;
scansim.plots_stat_log = 0;
% end

if scansim.plots_visible == 0
    set(groot,'DefaultFigureVisible','off');
else
    set(groot,'DefaultFigureVisible','on');
end

n_roi = length(loc.ROI);

mnesigFolder_unc = fullfile (rc.analysisFolder, '7_SOURCEACT', 'DC1', 'unc' );
mnesig_unc_infile_all = sc_reading(mnesigFolder_unc, '*sigroi_unc.mat');

mnesigFolder_lc = fullfile (rc.analysisFolder, '7_SOURCEACT', 'DC1', 'lc' );
mnesig_lc_infile_all = sc_reading(mnesigFolder_lc, '*sigroi_lc.mat');

% srcsigFolder = fullfile (rc.analysisFolder, '0_SIMSTUFF');
srcsig_infile_all = sc_reading(rc.rawFolder, '*_src.mat');

% if begId > 0  && endId > 0
%     mnesig_unc_infile = mnesig_unc_infile_all(begId : endId);
%     mnesig_lc_infile = mnesig_lc_infile_all(begId : endId);
%     srcsig_infile = srcsig_infile_all(begId : endId);
% else
mnesig_unc_infile = mnesig_unc_infile_all;
mnesig_lc_infile = mnesig_lc_infile_all;
srcsig_infile = srcsig_infile_all;
% end

conFolder_unc = fullfile (rc.analysisFolder, '8_CONN' , con.conName, 'unc');
con_unc_infile_all = sc_reading(conFolder_unc, '*mltout.mat');
conFolder_lc = fullfile (rc.analysisFolder, '8_CONN' , con.conName, 'lc');
con_lc_infile_all = sc_reading(conFolder_lc, '*stat_mltout.mat');

conFolder_src = fullfile (rc.analysisFolder, '8_CONN' , con.conName, 'src');
if ~exist(conFolder_src, 'dir'); mkdir(conFolder_src); end


% if begId > 0  && endId > 0
%     con_unc_infile = con_unc_infile_all(begId : endId);
%     con_lc_infile = con_lc_infile_all(begId : endId);
% else
%     con_unc_infile = con_unc_infile_all;
con_lc_infile = con_lc_infile_all;
% end

roinum = length(loc.ROI);


[~, fname, ~] = fileparts(mnesig_unc_infile{ds});
dsname = fname(design.idPosStart:design.idPosEnd);
mnecon_lc = load (con_lc_infile{ds});


%% plots


% connmeas = [mv.sDTF, mv.sNDTF, mv.sffDTF, mv.sPDC];

for meas = 1:1 %4

    if meas==1
        meth='NDTF';  le = 1000; bo = 1800;
        mnecon_lc_u  = mnecon_lc.NDTF_boot(:,:,:,3); %upper percentile
        mnecon_lc_m  = mnecon_lc.NDTF_boot(:,:,:,2); %median
        mnecon_lc_l  = mnecon_lc.NDTF_boot(:,:,:,1); %lower percentile
        mnebase = mnecon_lc.NDTF_base(:,:,1);  % only the first stat level is used
    end
    if meas==2
        meth='DTF';   le = 2100; bo = 1800;
        mnecon_lc_u  = mnecon_lc.DTF_boot(:,:,:,3); %upper percentile
        mnecon_lc_l  = mnecon_lc.DTF_boot(:,:,:,1); %lower percentile
        mnebase = mnecon_lc.DTF_base(:,:,1);
    end
    if meas==3
        meth='ffDTF';  le = 2100; bo = 170;
        mnecon_lc_u  = mnecon_lc.ffDTF_boot(:,:,:,3); %upper percentile
        mnecon_lc_l  = mnecon_lc.ffDTF_boot(:,:,:,1); %lower percentile
        mnebase = mnecon_lc.ffDTF_base(:,:,1);
    end
    if meas==4
        meth='PDC';   le = 1000; bo = 170;
        mnecon_lc_u  = mnecon_lc.PDC_boot(:,:,:,3); %upper percentile
        mnecon_lc_l  = mnecon_lc.PDC_boot(:,:,:,1); %lower percentile
        mnebase = mnecon_lc.PDC_base(:,:,1);
    end


    maxconm = zeros(roinum); 
    for x = 1:roinum
        for y = 1:roinum
            if x~=y
                maxconm(x,y) = max(squeeze(mnecon_lc_u(x,y,:)));
                % else
                % maxspem(x,y) = max(squeeze(mnecon_unc1(x,y,:)));
            end
        end
    end

    scalefac.maxc{meas} = max(maxconm, [], 'all');


    %% fig1

    hfig = figure('Position', [le bo 1100 900]);
    tl = tiledlayout(roinum,roinum, 'TileSpacing','Compact','Padding','Compact');

    for x = 1:roinum
        for y = 1: roinum
            if x~=y % conn plots
                % ax = nexttile(x + roinum*(y-1));  % do not fill the diagonal
                ax = nexttile;
                mneval1 = squeeze(mnecon_lc_l(x,y,:));
                mneval2 = squeeze(mnecon_lc_m(x,y,:));
                mneval3 = squeeze(mnecon_lc_u(x,y,:));

                mneval1(1:6)=[0 0 0 0 0 0]; mneval1(95:100)=[0 0 0 0 0 0];  %outside fileter limits
                mneval2(1:6)=[0 0 0 0 0 0]; mneval2(95:100)=[0 0 0 0 0 0]; 
                mneval3(1:6)=[0 0 0 0 0 0]; mneval3(95:100)=[0 0 0 0 0 0]; 

                if scansim.plots_stat_movaver
                mneval1 = movmean(mneval1, scansim.plots_stat_movaver);
                mneval2 = movmean(mneval2, scansim.plots_stat_movaver);
                mneval3 = movmean(mneval3, scansim.plots_stat_movaver);
                end
                % c = area([mneval1, mneval3-mneval1], 'LineStyle', ':','LineWidth',1.5, 'FaceAlpha', 1);
                c = area([mneval1, mneval2-mneval1, mneval3-mneval2], 'LineStyle', ':','LineWidth',1.5, 'FaceAlpha', 1);

                % ylim([0 scalefac.maxc{meas}*1.05])
                ylim([0 0.3])
                c(1).FaceColor = [1 1 1];
                c(2).FaceColor = [0.3 0.3 0.5];
                c(3).FaceColor = [0.4 0.4 0.6];

                yline(mnebase(x,y),':',' ','LineWidth',2, 'Color', "#A2142F")   
            else
                ax = nexttile;
                

            end

            xticks([0 20 40 60 80 100])
            xticklabels({'0' '10' '20' '30' '40' '50'})
            xlim([6 94])


            % if scansim.plots_stat_log
                % set(ax, 'YScale', 'log')
            % end

            if y == 1; ylabel(loc.ROI(x).name, 'FontSize',15,'FontWeight','bold'); end
            if x == n_roi; xlabel(loc.ROI(y).name, 'FontSize',15,'FontWeight','bold'); end

        end
    end

    % if isfield(con, 'conName'); figtitle = con.conName; end
    figtitle = rc.analysisName;

    % figtitle = ['STAT  ', meth, ':' figtitle, ' ', rc.analysisName];
        figtitle = ['STAT  ', mat2str(scansim.scenario_ver), '; ', meth, ':' figtitle];
    figtitle = strrep(figtitle, '_', '-');
    lg = legend('SRC', 'MNE unc', 'MNE lc', 'Orientation', 'Horizontal', 'FontSize',12,'FontWeight','bold'); lg.Layout.Tile = 'north'; title(tl, figtitle, 'FontSize',13,'FontWeight','bold');


    saveFolder_pic = fullfile (rc.analysisFolder, '8_CONN' , con.conName);
    saveFolder_comps = strrep(rc.analysisFolder, 'SCANS', 'COMPS');
    if ~exist(saveFolder_comps)
        mkdir(saveFolder_comps);
    end

    set(hfig, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');   % Set CreateFcn callback to make it visible after opening
    figfilename = strcat(figtitle, '_conn_output.fig');
    savefig(hfig, fullfile(saveFolder_pic, figfilename));
    figfilenamejpg = strcat(figtitle, '.jpg');
    saveas(hfig, fullfile(saveFolder_pic, figfilenamejpg));
    copyfile (fullfile(saveFolder_pic, figfilenamejpg), fullfile(saveFolder_comps, figfilenamejpg));

    close(hfig)

    %% fig2
    

    hfig = figure('Position', [le+222 bo+222 1100 900]);
    tl = tiledlayout(roinum,roinum, 'TileSpacing','Compact','Padding','Compact');

    for x = 1:roinum
        for y = 1: roinum
            if x~=y % conn plots
                % ax = nexttile(x + roinum*(y-1));  % do not fill the diagonal
                ax = nexttile;
                mneval1 = squeeze(mnecon_lc_l(x,y,:));
                mneval2 = squeeze(mnecon_lc_m(x,y,:));
                mneval3 = squeeze(mnecon_lc_u(x,y,:));

                mneval1(1:6)=[0 0 0 0 0 0]; mneval1(95:100)=[0 0 0 0 0 0];  %outside fileter limits
                mneval2(1:6)=[0 0 0 0 0 0]; mneval2(95:100)=[0 0 0 0 0 0]; 
                mneval3(1:6)=[0 0 0 0 0 0]; mneval3(95:100)=[0 0 0 0 0 0]; 

                if scansim.plots_stat_movaver
                mneval1 = movmean(mneval1, scansim.plots_stat_movaver);
                mneval2 = movmean(mneval2, scansim.plots_stat_movaver);
                mneval3 = movmean(mneval3, scansim.plots_stat_movaver);
                end
                % c = area([mneval1, mneval3-mneval1], 'LineStyle', ':','LineWidth',1.5, 'FaceAlpha', 1);
                c = area([mneval1, mneval2-mneval1, mneval3-mneval2], 'LineStyle', ':','LineWidth',1.5, 'FaceAlpha', 1);

                % ylim([0 scalefac.maxc{meas}*1.05])
                set(ax, 'YScale', 'log')
                ylim([0 1])
                c(1).FaceColor = [1 1 1];
                c(2).FaceColor = [0.3 0.3 0.5];
                c(3).FaceColor = [0.4 0.4 0.6];

                yline(mnebase(x,y),':',' ','LineWidth',2, 'Color', "#A2142F")   
                % yline(mnebase(x,y)*2,':',' ','LineWidth',2, 'Color', "#A2142F")   

            else
                ax = nexttile;

            end

            xticks([0 20 40 60 80 100])
            xticklabels({'0' '10' '20' '30' '40' '50'})
                            xlim([6 94])


            if y == 1; ylabel(loc.ROI(x).name, 'FontSize',15,'FontWeight','bold'); end
            if x == 4; xlabel(loc.ROI(y).name, 'FontSize',15,'FontWeight','bold'); end

        end
    end


    % if isfield(con, 'conName'); figtitle = con.conName; end
    figtitle = rc.analysisName;

    % figtitle = ['STAT  ', meth, ':' figtitle, ' ', rc.analysisName];
        figtitle = ['STAT  ', mat2str(scansim.scenario_ver), '; ', meth, ':' figtitle];
    figtitle = strrep(figtitle, '_', '-');
    lg = legend('SRC', 'MNE unc', 'MNE lc', 'Orientation', 'Horizontal', 'FontSize',12,'FontWeight','bold'); lg.Layout.Tile = 'north'; title(tl, figtitle, 'FontSize',13,'FontWeight','bold');

    % 
    % saveFolder_pic = fullfile (rc.analysisFolder, '8_CONN' , con.conName);
    % saveFolder_comps = strrep(rc.analysisFolder, 'SCANS', 'COMPS');
    % if ~exist(saveFolder_comps)
    %     mkdir(saveFolder_comps);
    % end

    set(hfig, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');   % Set CreateFcn callback to make it visible after opening
    figfilename = strcat(figtitle, '_lg_conn_output.fig');
    savefig(hfig, fullfile(saveFolder_pic, figfilename));
    figfilenamejpg = strcat(figtitle, '_lg.jpg');
    saveas(hfig, fullfile(saveFolder_pic, figfilenamejpg));
    copyfile (fullfile(saveFolder_pic, figfilenamejpg), fullfile(saveFolder_comps, figfilenamejpg));
end

save(fullfile(saveFolder_pic, 'scalfac.mat'), 'scalefac');

% end
% end
