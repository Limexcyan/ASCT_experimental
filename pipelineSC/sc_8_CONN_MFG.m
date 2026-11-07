function sc_8_CONN(rc, seg, design, loc, mv, sim, begId, endId)

%% loadfiles

currentSIGROIfolder = rc.analysisFolder;
if isfield(rc, 'sigroiName')   %in case the data to conn are taken from different dir
    currentSIGROIfolder = fullfile(currentSIGROIfolder, rc.analysisName, rc.sigroiName);
end

% mv.ntrls = [];       % no of trials - auto determinead
% mv.format = 6;       % 6: mat file
% mv.pautoflag = 0;
% mv.incl_instant = 0; % include instantaneous
% mv.pord = mv.mvarOrd;
% mv.method = 0;       % AR model order estimation
% mv.trial_mode = 0;   % 0 - multi-trial
% mv.chansel = mv.chanSel;
% mv.norm1 = mv.varNorm;  % variance divide
% mv.norm0 = 0;        % rm temp mean
% mv.morm2 = 0;        % ensemble mean
% if ~isfield(mv,'baseln'); mv.baseln = 0; end      % STAT estimate baseline
% if ~isfield(mv,'bootst'); mv.bootst = 0; end       % STAT bootstrap
% if ~isfield(mv,'siglev'); mv.siglev = 1; end

% duplicate values for compatibility with multar 
% mv.userange = mv.useRange;
% if rc.sim
%     mv.plev = 1-mv.pThresh{1};      
% end
% mv.basenum = 500;
% mv.bootpool = 73;
% mv.bootnum =  50;
% mv.visible_fig = 'off';
% mv.fstart = 0;      % freq window from
% mv.fend = 50;       % freq window from

% WHAT TO SHOW
% mv.pDTF   = 0;
% mv.pNDTF  = 0;
% mv.pSpect = 0;
% mv.pCohs  = 0;
% mv.pdDTF  = 0;
% mv.pPDC   = 0;
% mv.pffDTF = 0;
% mv.savefigs = 0;

% % WHAT TO SAVE - defaults
% if ~isfield (mv, 'sDTF'); mv.sDTF = 0; end
% if ~isfield (mv, 'sNDTF'); mv.sNDTF = 1; end
% if ~isfield (mv, 'sSpect'); mv.sSpect = 0; end
% if ~isfield (mv, 'sCohs'); mv.sCohs = 0; end
% if ~isfield (mv, 'sdDTF'); mv.sdDTF = 0; end
% if ~isfield (mv, 'sPDC'); mv.sPDC = 0; end
% if ~isfield (mv, 'sffDTF'); mv.sffDTF = 0; end
% if ~isfield (mv, 'sAR'); mv.sAR = 0; end
% if ~isfield (mv, 'savefigs'); mv.savefigs = 0; end

% mv.showsign = 0;

%% crreate labels file

labelfile = fullfile(rc.analysisFolder, '8_CONN', mv.conName, 'labels.txt');
[labelpath, ~, ~] = fileparts(labelfile);

if ~exist(labelpath)
    fprintf('labelpath = %s\n', labelpath)
   mkdir(labelpath);
end

fid = fopen(labelfile, 'w');
if fid ~= -1
    for i = 1:length(loc.ROI)
        if i>1
            fprintf(fid, '\n');
        end
        fprintf(fid, loc.ROI(i).name);
    end
    fclose(fid);
else
    warning('Cannot open label file %s', filename);
end
mv.descfil = labelfile;

% if ~strcmp(mv.chansel,'1-')
%     temp_new_ROI =[];
%     splits = split(mv.chansel,',');
%     if length(splits) ==1
%         splits = split(splits,'-');
%         ourROIs = [];
%         for splt = 1:length(splits)
%             ourROIs =[ourROIs str2num(splits{splt})];
% 
%         end
%         loc.ROI = loc.ROI(ourROIs(1):ourROIs(2));
%     else
%         ourROIs = [];
%         for splt = 1:length(splits)
%             ourROIs =[ourROIs str2num(splits{splt})];
% 
%         end
%         loc.ROI = loc.ROI(ourROIs);
%     end
% 
%     labelfiletrim = fullfile(rc.analysisFolder, '8_CONN', mv.conName, 'labels_trimmed.txt');
%     fid = fopen(labelfiletrim, 'w');
%     if fid ~= -1
%         for i = 1:length(loc.ROI)
%             if i>1
%                 fprintf(fid, '\n');
%             end
%             fprintf(fid, loc.ROI(i).name);
%         end
%         fclose(fid);
%     else
%         warning('Cannot open trim label file %s', filename);
%     end
% end

%% Compensating for lacking of saving-only option in multar /MD %%%%

% fnumbs1=getfunccalcnumbers(mv);
% fnumbs2=getfuncsavenumbers(mv);
% fnumbs=setdiff(fnumbs2,fnumbs1); % 8 jest dla AR i H
% 
% if ~isempty(fnumbs)
%     %set(0,'DefaultFigureWindowStyle','docked') %Docking all Figures to one window
%     if strcmp(mv.visible_fig, 'on')
%         set(0,'DefaultFigureVisible','on') %MD
%     else
%         set(0,'DefaultFigureVisible','off') %MD
%     end
% 
% end

%% LOAD RECONSTRUCTED ROI SIGS

testConditions = design.DC; %Get individual DCs

for dcs = 1:length(testConditions)

    loadFolder_unc = fullfile (currentSIGROIfolder, '7_SOURCEACT', sprintf('DC%d',dcs), 'unc');
    loadFolder_lc = fullfile (currentSIGROIfolder, '7_SOURCEACT', sprintf('DC%d',dcs), 'lc');
    if ~rc.sim  % cal mode
        saveFolder_unc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'unc', strcat('DC',sprintf('%d',dcs)));
        saveFolder_lc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'lc', strcat('DC',sprintf('%d',dcs)));
    else  % sim mode
        saveFolder_unc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'unc');
        saveFolder_lc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'lc');
    end

    if exist(loadFolder_unc)
        %Reading ROI sigs
        infile_unc = sc_reading(loadFolder_unc, '*sigroi_unc.mat');
        if mv.lc
            infile_lc = sc_reading(loadFolder_lc, '*sigroi_lc.mat');
        end
    else
        error( ['No ROI signals found in /7_SOURCEACT'] );
    end
   
    
    if ~isfolder(fullfile(saveFolder_unc)); mkdir(fullfile(saveFolder_unc)); end
    if ~isfolder(fullfile(saveFolder_lc)); mkdir(fullfile(saveFolder_lc)); end

    for  ds = 1 : length(infile_unc)
        [~, dsname, ~] = fileparts(infile_unc{ds});
        disp([' [' num2str( round(100*ds/length(infile_unc) )) '%] Loading reconstruced ROI signals: ', dsname, ' - ', infile_unc{ds}] );
        
        %Loading ICA data
        load_file_unc = infile_unc{ds};
        tmpdata = load(load_file_unc,'data_sigroi_unc');
        data_all_roi_unc{ds} = tmpdata.data_sigroi_unc;
        if mv.lc
            load_file = infile_lc{ds};
            tmpdata = load(load_file,'data_sigroi');
            data_all_roi_lc{ds} = tmpdata.data_sigroi;
        end
    end
    
    %% prepare files to be swallowed by multar
    
    for ds = 1:length(infile_unc)
        
        [~,dsname,~] = fileparts(infile_unc(ds));
        dsname=strrep(dsname, '_sigroi_unc', '');
        sigroi_unc = data_all_roi_unc{ds};
        if mv.lc
            sigroi_lc = data_all_roi_lc{ds};
        end
        
        for exp = 1:length(sigroi_unc)
            cnd = fieldnames(sigroi_unc); %There is obviously only one condition in every DC!
            
            %%% Multar NO LC Correction
            mfgin.data = sigroi_unc.(cnd{1}).signal;
            dsname2 = strrep(dsname,'_sigroi', '');
            mfgin2 = char(fullfile(saveFolder_unc, strcat(dsname2, '_', cnd{1}, '_mfgin.mat')));
            
            mfgin.chans =  size(sigroi_unc.(cnd{1}).signal,1);      %no of channels in input file
            mfgin.len = sigroi_unc.(cnd{1}).trialen;       % trial len
            mfgin.fsamp = sigroi_unc.(cnd{1}).sampling_rate;     % sampling freq
            mfgin.timerangestart = round((mv.timeRangeStart + seg.prestim)* mfgin.fsamp);   % timeRangeStart is ExSetup paramatere while timerangestart is multar parameter
            if mv.timeRangeStart ==0; mv.timerangestart=1; end  % avoid zero sample caused by rounding
            mfgin.timerangeend = round((mv.timeRangeEnd +seg.prestim)*mfgin.fsamp);
            txt_to_disp = ['condition: ' num2str(cnd{1}) '; no of ROIs: ' mfgin.chans '; trials: ' num2str(size(sigroi_unc.(cnd{1}).signal,2) / sigroi_unc.(cnd{1}).trialen) '; trial len: '  num2str(mfgin.len) ];
            disp(txt_to_disp);

            % TUTAJ KOD MFG
            
            EEG(sigroi_unc, cnd, seg, mv, saveFolder_unc);

            save(mfgin2, 'mfgin');
            mv.fname = mfgin2; %mat input file
            
            
            
            % load('multar_startup.mat');   % some initial variables needed for multar
            % multar1m(mv);   % multar UNC
            
            %%% Multar LC Correction
            if mv.lc
                
                mfgin.data = sigroi_lc.(cnd{1}).signal;  % preparing lc multin file
                dsname3 = strrep(dsname2, '_unc', '_lc');
                multarinfile = char(fullfile(saveFolder_lc, strcat(dsname3, '_', cnd{1}, '_mfgin.mat')));
                
                %  setting multar params and running conn analysis
                % mv.fname = multarinfile; %mat input file
                mfgin.chans =  size(sigroi_lc.(cnd{1}).signal,1);      %no of channels in input file
                mfgin.len = sigroi_lc.(cnd{1}).trialen;       % trial len
                mfgin.fsamp = sigroi_lc.(cnd{1}).sampling_rate;     % sampling freq
                txt_to_disp = ['condition: ' num2str(cnd{1}) '; no of ROIs: ' mfgin.chans '; trials: ' num2str(size(sigroi_lc.(cnd{1}).signal,2) / sigroi_lc.(cnd{1}).trialen) '; trial len: '  num2str(mfgin.len) ];
                disp(txt_to_disp);
                                
                save (multarinfile, 'mfgin');


                % multar1m(mv);   % multar LC

                % if rc.sim  && rc.simStats % preparing simulation statistics 
                %     disp('preparing statistics data');
                % mvprev = mv; % retain original mv
                % multarinstatfile = strrep(multarinfile, '_mfgin.mat', '_stat_mfgin.mat');
                % copyfile (multarinfile, multarinstatfile);
                % mv.fname = multarinstatfile;
                % mv.bootst = 1;
                % mv.baseln = 1;
                % % multar1m(mv);   % multar SIMSTAT
                % mv = mvprev; % revert to the original mv
                % 
                % end
            end

            
        end
        
    end
end
%delete(findall(0));
end
