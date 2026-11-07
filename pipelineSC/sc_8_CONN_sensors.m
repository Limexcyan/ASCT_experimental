function sc_8_CONN(rc, seg, design, loc, mv, sim, begId, endId)

%% loadfiles

currentSIGROIfolder = rc.analysisFolder;
if isfield(rc, 'sigroiName')   %in case the data to conn are taken from different dir
    currentSIGROIfolder = fullfile(currentSIGROIfolder, rc.analysisName, rc.sigroiName);
end

mv.ntrls = [];       % no of trials - auto determinead
mv.format = 6;       % 6: mat file
mv.pautoflag = 0;
mv.incl_instant = 0; % include instantaneous
mv.pord = mv.mvarOrd;
mv.method = 0;       % AR model order estimation
mv.trial_mode = 0;   % 0 - multi-trial
mv.chansel = mv.chanSel;
mv.norm1 = mv.varNorm;  % variance divide
mv.norm0 = 0;        % rm temp mean
mv.morm2 = 0;        % ensemble mean
if ~isfield(mv,'baseln'); mv.baseln = 0; end      % STAT estimate baseline
if ~isfield(mv,'bootst'); mv.bootst = 0; end       % STAT bootstrap
if ~isfield(mv,'siglev'); mv.siglev = 1; end

% duplicate values for compatibility with multar 
mv.userange = mv.useRange;
if rc.sim
    mv.plev = 1-mv.pThresh{1};      
end
% mv.basenum = 500;
% mv.bootpool = 73;
% mv.bootnum =  50;
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

% WHAT TO SAVE - defaults
if ~isfield (mv, 'sDTF'); mv.sDTF = 0; end
if ~isfield (mv, 'sNDTF'); mv.sNDTF = 1; end
if ~isfield (mv, 'sSpect'); mv.sSpect = 0; end
if ~isfield (mv, 'sCohs'); mv.sCohs = 0; end
if ~isfield (mv, 'sdDTF'); mv.sdDTF = 0; end
if ~isfield (mv, 'sPDC'); mv.sPDC = 0; end
if ~isfield (mv, 'sffDTF'); mv.sffDTF = 0; end
if ~isfield (mv, 'sAR'); mv.sAR = 0; end
if ~isfield (mv, 'savefigs'); mv.savefigs = 0; end

mv.showsign = 0;

%% crreate labels file

labelfile = fullfile(rc.analysisFolder, '8_CONN', mv.conName, 'labels.txt');
[labelpath, ~, ~] = fileparts(labelfile);
if ~exist(labelpath)
    mkdir(labelpath);
end

fid = fopen(labelfile, 'w');
if fid ~= -1
   
    sensx = load(fullfile(rc.analysisFolder, '1_PREPROCESSED', 'sensors.mat'));
    for i = 1:length(sensx.sens.label)
        if strcmp(sensx.sens.chantype{1}, 'eeg')
            if i>1
                fprintf(fid, '\n');
            end
            fprintf(fid, sensx.sens.label{i});
        end
    end
    

    fclose(fid);
else
    warning('Cannot open label file %s', filename);
end

if ~strcmp(mv.chansel,'1-')
    temp_new_ROI =[];
    splits = split(mv.chansel,',');
    if length(splits) ==1
        splits = split(splits,'-');
        ourROIs = [];
        for splt = 1:length(splits)
            ourROIs =[ourROIs str2num(splits{splt})];

        end
        loc.ROI = loc.ROI(ourROIs(1):ourROIs(2));
    else
        ourROIs = [];
        for splt = 1:length(splits)
            ourROIs =[ourROIs str2num(splits{splt})];

        end
        % loc.ROI = [];
        % loc.ROI = loc.ROI(ourROIs);
    end
    
    labeltrim = [];
    labelfiletrim = fullfile(rc.analysisFolder, '8_CONN', mv.conName, 'labels_trimmed.txt');
    fid = fopen(labelfiletrim, 'w');
    if fid ~= -1
        for i = 1:length(ourROIs)
            if i>1
                fprintf(fid, '\n');
            end
            fprintf(fid, sensx.sens.label{ourROIs(i)});
            labeltrim{i} = sensx.sens.label{ourROIs(i)};
        end
        fclose(fid);
    else
        warning('Cannot open trim label file %s', filename);
    end
end

mv.descfil = labelfile;
save(   fullfile(rc.analysisFolder, '8_CONN', mv.conName, 'labels_trimmed.mat')  , 'labeltrim');

%% Compensating for lacking of saving-only option in multar /MD %%%%

fnumbs1=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(fnumbs2,fnumbs1); % 8 jest dla AR i H

if ~isempty(fnumbs)
    %set(0,'DefaultFigureWindowStyle','docked') %Docking all Figures to one window
    if strcmp(mv.visible_fig, 'on')
        set(0,'DefaultFigureVisible','on') %MD
    else
        set(0,'DefaultFigureVisible','off') %MD
    end

end

%% LOAD RECONSTRUCTED ROI SIGS

for dcs = 1:size(design.COND(1).name,2)

    cnd = design.COND(1).name{dcs};
        saveFolder_unc = fullfile (rc.analysisFolder, '8_CONN' , mv.conName, 'unc', strcat('DC',sprintf('%d',dcs)));

    if exist(saveFolder_unc)
        %Reading  sigs
        infile_unc = sc_reading(saveFolder_unc, '*mltin.mat');
    else
        error( ['No data found. Has been sc_recreatesensors run? '] );
    end
   
    
    
    %% prepare files to be swallowed by multar
    
    for ds = 1:length(infile_unc)
        
        [~,dsname,~] = fileparts(infile_unc(ds));
        dsname=strrep(dsname, '_mltin', '');
        load(strrep(infile_unc{ds}, '_mltin', '_sigconf'));

        % for exp = 1 %:length(sigroi_unc)
            % cnd = fieldnames(sigroi_unc); %There is obviously only one condition in every DC!
            
            %%% Multar NO LC Correction
            dsname2 = strrep(dsname,'_sigroi', '');
            mv.fname = infile_unc{ds}; %mat input file
            
            mv.chans = sigconf.nochan; %no of channels in input file
            mv.recl  = sigconf.triallen;       % trial len
            mv.fsamp = sigconf.fsample;     % sampling freq
           

            txt_to_disp = ['condition: ' cnd ];
            disp(txt_to_disp);
            
            load('multar_startup.mat');   % some initial variables needed for multar
            multar1m(mv);   % multar UNC
          
            
        % end
        
    end
end
%delete(findall(0));
end
