function sc_simsummary(rc, seg, design, loc, mv, simul, scansim, begId, endId)

if ~exist(scansim)  % default values if not run from scansim wrapper
scansim.plots_visible = 0;
scansim.output_scaling = 1;
end

    if scansim.plots_visible == 0
        set(groot,'DefaultFigureVisible','off');
    else
        set(groot,'DefaultFigureVisible','on');
    end


mnesigFolder_unc = fullfile (rc.analysisFolder, '7_SOURCEACT', 'DC1', 'unc' );
mnesig_unc_infile_all = sc_reading(mnesigFolder_unc, '*sigroi_unc.mat');

mnesigFolder_lc = fullfile (rc.analysisFolder, '7_SOURCEACT', 'DC1', 'lc' );
mnesig_lc_infile_all = sc_reading(mnesigFolder_lc, '*sigroi_lc.mat');

srcsigFolder = fullfile (rc.expFolder, '0_SIMSTUFF');
srcsig_infile_all = sc_reading(srcsigFolder, '*_src.mat');

if begId > 0  && endId > 0
    mnesig_unc_infile = mnesig_unc_infile_all(begId : endId);
    mnesig_lc_infile = mnesig_lc_infile_all(begId : endId);
    srcsig_infile = srcsig_infile_all(begId : endId);
else
    mnesig_unc_infile = mnesig_unc_infile_all;
    mnesig_lc_infile = mnesig_lc_infile_all;
    srcsig_infile = srcsig_infile_all;
end

saveFolder_unc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'unc');
conFolder_unc = fullfile (rc.analysisFolder, '8_CONN', mv.conName, 'unc' );
con_unc_infile_all = sc_reading(conFolder_unc, '*mltout.mat');
saveFolder_lc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'lc');
conFolder_lc = fullfile (rc.analysisFolder, '8_CONN', mv.conName, 'lc' );
con_lc_infile_all = sc_reading(conFolder_lc, '*mltout.mat');
for f = length(con_lc_infile_all ):-1:1    % to remove lc stat files, as they are also recognized
   if  contains(con_lc_infile_all{f}, '_stat_')
       con_lc_infile_all(f)=[];
   end
end

conFolder_src = fullfile (rc.analysisFolder, '8_CONN', mv.conName, 'src' );


% saveFolder_src = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'src');
% if ~exist(saveFolder_src, 'dir')
%    mkdir(saveFolder_lc)
% end


if begId > 0  && endId > 0
    con_unc_infile = con_unc_infile_all(begId : endId);
    con_lc_infile = con_lc_infile_all(begId : endId);
else
    con_unc_infile = con_unc_infile_all;
    con_lc_infile = con_lc_infile_all;
end

n_roi = length(loc.ROI);

for  ds = 1 : length(con_unc_infile)
    
    %% conn params
    
    mv.ntrls = [];       % no of trials - auto determinead
    mv.format = 6;       % 6: mat file
    mv.pautoflag = 0;
    mv.incl_instant = 0; % include instantaneous
    
    mv.method = 0;       % AR model order estimation
    mv.trial_mode = 0;   % 0 - multi-trial
    time_st = mv.timeRangeStart;
    time_end = mv.timeRangeEnd;
    mv.norm0 = 1;        % rm temp mean
    if ~isfield(mv, 'norm1'); mv.norm1 = 1; disp('No variance divide declared. Setting default to enable'); end       % var divide
    mv.morm2 = 0;        % ensemble mean
    mv.baseln = 0;       % STAT estimate baseline
    if ~isfield(mv, 'bootst'); mv.bootst = 0; end       % STAT bootstrap
    % mv.siglev = 2;       % signif lev  % 1=0.99 2=0.95 3=0.90 4=0.75
    if rc.sim
        mv.siglev = 1;
        % mv.plev = simul.plev*100;
        % mv.plev = 1-mv.p_thresh{1};  
        mv.plev = 1-mv.pThresh{1};  

    else
        mv.siglev=1;
    end
    % if ~isfield(mv, 'basenum'); mv.basenum = 100; disp('No number of baseline calc declared. Setting default to 100'); end
    % if ~isfield(mv, 'bootnum'); mv.bootnum = 200; disp('No number of bootstrap calc declared. Setting default to 200'); end
    % if ~isfield(mv, 'bootpool'); mv.bootsize =  100; disp('No bootstrap size declared. Setting default to 100'); end
    mv.visible_fig = 'off';
    mv.fstart = 0;      % freq window from
    mv.fend = 50;       % freq window from
    
        % WHAT TO SHOW
    mv.pDTF   = 0;
    mv.pNDTF  = 0;
    mv.pSpect = 0;
    mv.pCohs  = 0;
    mv.pdDTF  = 0;
    mv.pPDC   = 0;
    mv.pffDTF = 0;
    mv.savefigs = 0;
    
    labelfile = fullfile(rc.analysisFolder, '8_CONN', mv.conName, 'labels.txt');
    mv.descfil = labelfile;
    
    fnumbs1=getfunccalcnumbers(mv);
    fnumbs2=getfuncsavenumbers(mv);
    fnumbs=setdiff(fnumbs2,fnumbs1); % 8 jest dla AR i H
    
    [~, fname, ~] = fileparts(mnesig_unc_infile{ds});
    dsname = fname(design.idPosStart:design.idPosEnd);
    
    
    mnecon_unc = load (con_unc_infile{ds});
%     mnecon_unc = tmpdatam.NDTF;
%     if mv.sDTF;     mnecon_unc_dtf      =    tmpdatam.DTF;      end
%     if mv.sPDC;     mnecon_unc_pdc      =    tmpdatam.PDC;       end
%     if mv.sffDTF;   srccon_unc_ffdtf    =  tmpdatam.ffDTF;	end
%     
    if mv.lc
        mnecon_lc = load (con_lc_infile{ds});
%                 if mv.sDTF;     mnecon_lc_ndtf      = tmpdatam.DTF;      end
%         if mv.sPDC;     mnecon_lc_pdc       = tmpdatam.PDC;       end
%         if mv.sffDTF;   mnecon_lc_ffdtf    = tmpdatam.ffDTF;	end
    end
    
    
    %%% Multar SRC
    
    mv.recl = mnecon_unc.mv.recl;  % trial len
    mv.fsamp = mnecon_unc.mv.fsamp; % sampling freq
    mv.ntrls = mnecon_unc.mv.ntrls;
    if mv.lc
        mnecon_lc = load (con_lc_infile{ds});
    end
    
    tmpdata= load (srcsig_infile{ds});
    srcsighs = tmpdata.srcsig;
    disp('downsampling src signal 1024->128..');
    parfor i = 1:size(srcsighs,1)
        srcsig(i,:) = decimate(srcsighs(i,:),8)';
    end       
    srcsig = srcsig(:,1:(mv.ntrls*mv.recl)); % cut to fit into defined trials
    clear tmpdata    

    if ~isempty(fnumbs)
        %set(0,'DefaultFigureWindowStyle','docked') %Docking all Figures to one window
        if strcmp(mv.visible_fig, 'on')
            set(0,'DefaultFigureVisible','on') %MD
        else
            set(0,'DefaultFigureVisible','off') %MD
        end
    end
       
    if ~exist(conFolder_src); mkdir (conFolder_src); end

    mv.chans =  size(srcsig,1);      %no of channels in input file
    
    mv.userange = mv.useRange;  % duplicating some variables for multar compatibility
    mv.chansel = mv.chanSel;
    mv.pord = mv.mvarOrd;


    mv.timerangestart = round((time_st + seg.prestim)* mv.fsamp);
    if mv.timerangestart ==0; mv.timerangestart=1; end  % avoid zero sample caused by rounding
    mv.timerangeend = round((time_end +seg.prestim)*mv.fsamp);
    
    load('multar_startup.mat');   % some initial variables needed for multar
    
    mltin = srcsig;
    file_src_sigroi = fullfile(conFolder_src, strcat(dsname, '_SRC_mltin.mat'));
    save(file_src_sigroi, 'mltin');
    mv.fname = file_src_sigroi; %mat input file
    multar1m(mv);   % multar SRC

    tmps = load(file_src_sigroi);
    n_sources = size(tmps.mltin,1);  % will be needed if no of simulated sources < no of ROIs
    clear tmps
    
    %% plots
        
    srccon = load (strrep(file_src_sigroi, 'mltin', 'mltout'));
%     srccon_ndtf = tmpdata.NDTF;
%     if mv.sDTF;     srccon_dtf = tmpdata.DTF;   end
%     if mv.sPDC;     srccon_pdc = tmpdata.PDC;   end
%     if mv.sffDTF;   srccon_ffdtf = tmpdata.ffDTF;   end  

   
    connmeas = [mv.sDTF, mv.sNDTF, mv.sffDTF, mv.sPDC];
   

    if mv.bootst   % if bootstrap stat is enabled, 4D matrices are produced with 4th dim as lower percent, mean. higher percentile
        srccon.NDTF  = srccon.NDTF_boot(:,:,:,2);
        srccon.DTF   = srccon.DTF_boot(:,:,:,2);
        srccon.PDC   = srccon.PDC_boot(:,:,:,2);
        srccon.ffDTF = srccon.ffDTF_boot(:,:,:,2);
        mnecon_unc.NDTF  = mnecon_unc.NDTF_boot(:,:,:,2);
        mnecon_unc.DTF   = mnecon_unc.DTF_boot(:,:,:,2);
        mnecon_unc.PDC   = mnecon_unc.PDC_boot(:,:,:,2);
        mnecon_unc.ffDTF = mnecon_unc.ffDTF_boot(:,:,:,2);
        if mv.lc
        mnecon_lc.NDTF  = mnecon_lc.NDTF_boot(:,:,:,2);
        mnecon_lc.DTF   = mnecon_lc.DTF_boot(:,:,:,2);
        mnecon_lc.PDC   = mnecon_lc.PDC_boot(:,:,:,2);
        mnecon_lc.ffDTF = mnecon_lc.ffDTF_boot(:,:,:,2);
        end
    end


    for meas = 1:4
        % if connmeas(meas)
            
            if meas==1
                srccon1 = srccon.NDTF;   
                mnecon_unc1 = mnecon_unc.NDTF;    
                meth='NDTF';     
                le = 1000; bo = 1800;  
            end
            if meas==2
                srccon1 = srccon.DTF;    
                mnecon_unc1 = mnecon_unc.DTF;     
                meth='DTF';      
                le = 2100; bo = 1800; 
            end
            if meas==3	
                srccon1 = srccon.PDC;    
                mnecon_unc1 = mnecon_unc.PDC;     
                meth='PDC';      
                le = 1000; bo = 170; 
            end
            if meas==4
                srccon1 = srccon.ffDTF;  
                mnecon_unc1 = mnecon_unc.ffDTF;   
                meth='ffDTF';  
                le = 2100; bo = 170; 
            end
            
            if mv.lc
            if meas==1; 	mnecon_lc1 = mnecon_lc.NDTF;     end
            if meas==2; 	mnecon_lc1 = mnecon_lc.DTF;      end
            if meas==3; 	mnecon_lc1 = mnecon_lc.PDC;      end
            if meas==4; 	mnecon_lc1 = mnecon_lc.ffDTF;    end
            end
            
            if n_roi > n_sources  % assume injected signal sources are the first ROIs
                lessigsthanrois = 1;
            else
                lessigsthanrois = 0;
            end
            
            maxconm = zeros(n_roi); maxcons = zeros(n_roi); maxspem = zeros(n_roi); maxspes = zeros(n_roi);
            for x = 1:n_roi
                for y = 1: n_roi
                    
                    if x~=y
                        maxconmun(x,y) = max(squeeze(mnecon_unc1(x,y,:)));
                        maxconmlc(x,y) = max(squeeze(mnecon_lc1(x,y,:)));
                        if lessigsthanrois && (x > n_sources || y > n_sources)   % zero for src connectivity for higher (non -source_ rois
                            maxcons(x,y) = 0;
                        else
                            maxcons(x,y) = max(squeeze(srccon1(x,y,:)));

                        end
                    else
                        maxspem(x,y) = max(squeeze(mnecon_lc1(x,y,:)));
                        if lessigsthanrois && (x > n_sources || y > n_sources)
                            maxspes(x,y) = 0;
                        else
                            maxspes(x,y) = max(squeeze(srccon1(x,y,:)));

                        end
                    end
                end
            end
            
            if scansim.output_scaling
                scalefac.maxcun{meas} = max(maxconmun, [], 'all');
                scalefac.maxclc{meas} = max(maxconmlc, [], 'all');
                scalefac.maxs{meas} = max(maxcons, [], 'all');
                scalefac.scalingfconun{meas} = scalefac.maxs{meas} / scalefac.maxcun{meas};
                scalefac.scalingfconlc{meas} = scalefac.maxs{meas} / scalefac.maxclc{meas};

                scalefac.maxp{meas} = max(maxspem, [], 'all');
                scalefac.scalingfspe{meas} = max(maxspem, [], 'all') / max(maxspes, [], 'all');
            else
                scalefac.scalingfconun{meas} = 1;
                scalefac.scalingfconlc{meas} = 1;
                scalefac.scalingfspe{meas} = 1;
            end
    end
    for meas = 1:4

        if meas==1; 	srccon1 = srccon.NDTF;   mnecon_unc1 = mnecon_unc.NDTF;    meth='NDTF';     le = 1000; bo = 1800;  end
        if meas==2; 	srccon1 = srccon.DTF;    mnecon_unc1 = mnecon_unc.DTF;     meth='DTF';      le = 2100; bo = 1800; end
        if meas==3; 	srccon1 = srccon.PDC;    mnecon_unc1 = mnecon_unc.PDC;     meth='PDC';      le = 1000; bo = 170; end
        if meas==4; 	srccon1 = srccon.ffDTF;  mnecon_unc1 = mnecon_unc.ffDTF;   meth='ffDTF';    le = 2100; bo = 170; end

        if lessigsthanrois 
            for x = 1:n_roi
                for y = 1:n_roi
                    if x > n_sources || y > n_sources
                        srccon1(x,y,:) = zeros(100,1);
                    end
                end
            end
        end

        if mv.lc
            if meas==1; 	mnecon_lc1 = mnecon_lc.NDTF;     end
            if meas==2; 	mnecon_lc1 = mnecon_lc.DTF;      end
            if meas==3; 	mnecon_lc1 = mnecon_lc.PDC;      end
            if meas==4; 	mnecon_lc1 = mnecon_lc.ffDTF;    end
        end
            
            hfig = figure('Position', [le bo 1100 900]);
            tl = tiledlayout(n_roi,n_roi, 'TileSpacing','Compact','Padding','Compact');
            for x = 1:n_roi
                for y = 1: n_roi
                    ax = nexttile;
                    if x~=y % conn plots
                        % s = area(squeeze(srccon1(x,y,:)*scalefac.scalingfcon{meas}), 'LineStyle','-','LineWidth',1.5,'FaceColor', 'b', 'FaceAlpha', 0.3);
                        s = area(squeeze(srccon1(x,y,:)), 'LineStyle','-','LineWidth',1.5,'FaceColor', 'b', 'FaceAlpha', 0.3);
                        hold on;
                        m = area(squeeze(mnecon_unc1(x,y,:)*scalefac.scalingfconun{meas}), 'LineStyle', '--','LineWidth',1.5,'FaceColor', '#c7c49b', 'FaceAlpha', 0.3);
                        if mv.lc
                            c = area(squeeze(mnecon_lc1(x,y,:)*scalefac.scalingfconlc{meas}), 'LineStyle', ':','LineWidth',1.5,'FaceColor', 'r', 'FaceAlpha', 0.3);
                        end
                        ylim([0 scalefac.maxs{meas}*1.05])
                        
                    else % spectral plots
                        s = area(squeeze(srccon1(x,y,:)*scalefac.scalingfspe{meas}), 'LineStyle','-','LineWidth',2,'FaceColor', '#DDDDDD', 'FaceAlpha', 0.3);
                        hold on;
                        m = area(squeeze(mnecon_unc1(x,y,:)), 'LineStyle', '--','LineWidth',1,'FaceColor', '#DDDDDD', 'FaceAlpha', 0.3);
                        if mv.lc
                            c = area(squeeze(mnecon_lc1(x,y,:)), 'LineStyle', ':','LineWidth',2,'FaceColor', '#DDDDDD', 'FaceAlpha', 0.3);
                        end
                        ylim([0 scalefac.maxp{meas}*1.05])
                    end
                    if x==1 && y==2
                        if isfield(mv, 'conName'); figtitle = mv.conName; end
                        figtitle = [meth, ':' figtitle, ' ', rc.analysisName];
                        figtitle = strrep(figtitle, '_', '-');
                        
                        if mv.lc
                            lg = legend('SRC', 'MNE unc', 'MNE lc', 'Orientation', 'Horizontal', 'FontSize',12,'FontWeight','bold'); lg.Layout.Tile = 'north'; title(tl, figtitle, 'FontSize',13,'FontWeight','bold');
                        else
                            lg = legend('SRC', 'MNE', 'Orientation', 'Horizontal', 'FontSize',12,'FontWeight','bold'); lg.Layout.Tile = 'north'; title(tl, figtitle, 'FontSize',13,'FontWeight','bold');
                        end
                    end
                    xticks([0 20 40 60 80 100])
                    xticklabels({'0' '10' '20' '30' '40' '50'})
                    
                    if y == 1; ylabel(loc.ROI(x).name, 'FontSize',15,'FontWeight','bold'); end
                    if x == n_roi; xlabel(loc.ROI(y).name, 'FontSize',15,'FontWeight','bold'); end
                end
            end
            

            saveFolder_pic = fullfile (rc.analysisFolder, '8_CONN' , mv.conName);
            % saveFolder_comps = strrep(rc.analysisFolder, 'SCANS', 'COMPS');
            % if ~exist(saveFolder_comps)
            % mkdir(saveFolder_comps);
            % end

            set(hfig, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');   % Set CreateFcn callback to make it visible after opening
            figfilename = strcat(figtitle, '_conn_output.fig');
            savefig(hfig, fullfile(saveFolder_pic, figfilename));
            figfilenamejpg = strcat(figtitle, '.jpg');
            saveas(hfig, fullfile(saveFolder_pic, figfilenamejpg));
             % saveas(hfig, fullfile(saveFolder_comps, figfilenamejpg));
            % copyfile (fullfile(saveFolder_pic, figfilenamejpg), fullfile(saveFolder_pic, figfilenamejpg));

        % end
    end

    save(fullfile(saveFolder_pic, 'scalfac.mat'), 'scalefac');

end
end
