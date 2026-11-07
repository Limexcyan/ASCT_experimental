%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% ERP ANALYSIS %%%%%%%%%%


% This scirpt provides an oportunity to calculate Event Related Potentials from data which has been previously
% preprocessed, segmented and cleaned up from artifacts.
%
% 1. DESIGN
% Design of experiment cosists of: Trigger, Sesion and Group specification.
%
% 2. Trriggers: triggers are listed in {} structures, each list corresponds to given name: e.g.
% design.COND(1).name{1,1} = {'pos'}
% design.COND(1).name{1,2} = {'neg'}
% design.COND(1).trig{1,1} = { 68251, 68252 }
% design.COND(1).trig{1,2} = { 68252, 68253 }
%
% Triggers correspond to given experimental Conditions marked by 'COND' field.
% It creates n_i x m_i condition matrix elements where n correspond to given CONDition,
% and m_i to different triggers which reffer to this kind of CONDition.
%
% 3. Session. Session is read from the names of the original '*bdf' files.
% The script provides a formula which reads sessions specification directly from the file name.
% It is specified by start and end index of the session codding.
%
% 4. Group. Group is read from the names of the original '*bdf' files.
% The script provides a formula which reads group specification directly from the file name.
% It is specified by start and end index of the group codding.

% NOTE: there is an oportunity to exclude given DS in data analysis by specifying them in 'ds_exclude'.

% 5. DATA REVIEW
% For further review see 'sc_ERPvisualisation'. It allows comparison between chosen DC. With 'vis_DC_list' parameter specyfying which DC should be taken into account during visualisation.
% For Emegs export see 'sc_EMEGSexport' which takes 'EMEGS_save_par' parameters (either 'all' or 'avg' for all ds or just grandaveraged data respectively)
% For CSV export see 'sc_CSVexport' which takes 'CSV_save_par' parameters (either 'all' or 'avg' for all ds or just grandaveraged data respectively)

%% ARTIFREE DATA LOADING %%%%%%%


% if ( ~strcmp(rc.load_artrej, 'F') && exist('data_all_arj')  )
if exist('data_all_arj')
    disp( [ 'Using either:', newline, '1. no arifact data from memory (assuming no data change in data_all_arj!!!)', newline, 'or', newline, '2. loading previously calculated ERP (if given design configuration has been calcluated before)', newline ] );
    
else
    loadFolder = [analysisFolder '/3_ARTIFREE' ];
    if ~exist(loadFolder); error( ['There is no /3_ARTIFREE folder.' , newline, "Most likely no-artifact data haven't been saved"] ); end
    
    clear data_all_arj
    infile_all = sc_reading(loadFolder, '*ARJ.mat'); %reads ART REJ files from begId to endId   %mmw
    infile = infile_all;
    
    if exist('begId') && exist('endId')
        infile = infile_all(begId : endId);   
    end
    
    if ~exist('begId')
        begId=1; 
    end   
    if ~exist('endId')
        endId=length(infile); 
    end   
    
    
    parfor ds = begId-begId+1 : endId-begId+1   % actual loading on ART REJ data
        disp([' [' num2str( round( 100 * (ds-begId+1) / (length(infile)-begId+1) ) ) '%] Loading DS', num2str(ds), ' - ', infile{ds}, ' artifact free data'] );
        datatmp = load( infile_all{ds}, 'data_artf' );
        data_all_arj(ds) = datatmp.data_artf;
    end
end

clear datatmp

saveFolder = [analysisFolder '/4_AVERAGED' ];

if strcmp(rc.load_artrej, 'F'); rmdir(saveFolder, 's'); end

if ~exist(saveFolder); mkdir(saveFolder); end

%% EXCLUDING 


include = ones( length(infile),1 ); %contain matrix with ones which are filled with zeros if subject is wanted to be excluded from analysis

for ds = ds_exclude
    include(ds) = 0;
end

%% NAME   %%%

% Here names of Data Configurations are produced. They are further used to save already computed data.

for DC = 1 : DCnr % length(SES) %checks how many DataConfiguration has been specified. Must be at least two. Either SES or GRP are equal in size to DC number, that's why SES is used here
    
    NAME{DC} = [];
    
    %%% actual naming of DataConfigurations
    
    %GRP
    if any( isempty(GRP{1,DC})) || any( strcmp( GRP{1,DC} , 'all') ) %if there is no GRP specified or it is specified as all, call it 'all'
        NAME{DC} = [ NAME{DC} '-' 'all'];
    else %otherwise add each GRP instance to the name
        for ii = 1:length(GRP{1,DC})
            NAME{DC} = [ NAME{DC} '-' GRP{1,DC}{1,ii} ];
        end
    end
    
    %SES
    if any( isempty(SES{1,DC})) || any( strcmp( SES{1,DC} , 'all') ) %if there is no SES specified or it is specified as all, call it 'all'
        NAME{DC} = [ NAME{DC} '-' 'all'];
    else %othervise add each SES instance to the name
        for ii = 1:length(SES{1,DC})
            NAME{DC} = [ NAME{DC} '-' SES{1,DC}{1,ii} ];
        end
    end
    
    if exist('begIdARTF') && exist('endIdARTF')    %CHECK what for begin/endIdARTIF
        NAME{DC} = [ NAME{DC} '-' 'ds-allARTF' ];   %FIXME change into ARJ and check the whole condition if needed
    elseif exist('begId') && exist('endId') %begId always exists but endId exists only if it was specified in EX_SETUP
        NAME{DC} = [ NAME{DC} '-' 'ds-',num2str(begId),'-',num2str(endId) ];
    else
        %don't add any more details to NAME
    end
    
    %COND
    for c = 1 : length(design.COND)
        NAME{DC} = [ NAME{DC} '-' ];
        for ii = 1 : length( COND(c).DS{1,DC} )
            NAME{DC} = [ NAME{DC} COND(c).DS{1,DC}{1,ii} ',']; %add all instances of each COND to the name
        end
        NAME{DC} = NAME{DC}(1 , 1:end-1);
    end
    
    %adding excluded ds to the name (so that the datasets with excluded ds can differ from this with all ds included)
    if length( ds_exclude ) >= 1
        NAME{DC} = [ NAME{DC} '_no'];
        for ds_ex = ds_exclude
            NAME{DC} = [ NAME{DC} '-' num2str(ds_ex) ];
        end
    end
    
    NAME{DC} = NAME{DC}(1 , 2:end); %removes first'-'
    
end


%% DATASET LISTS  %%%

% Creating dataset list based on GRP and SES specifications

if exist('begIdARTF') && exist('endIdARTF')
    
    begId = begIdARTF;
    endId = endIdARTF;
    
elseif exist('begId') && exist('endId')
    %do nothing
else
    begId = 1;
    endId = length(data_all_arj);
end

for DC = 1 : DCnr; %length(SES)
    
    DS_LIST{DC} = [];
    
    % 1st case: if all SES and GRP to be taken
    if (any( isempty( SES{1,DC})) || any( strcmp( SES{1,DC} , 'all') ) ) && any( isempty( GRP{1,DC})) || any( strcmp( GRP{1,DC} , 'all') )%lists all subjects ||| any converts logical arrays into single logical character (0 or 1 insted of 0x0 logic array)
        
        for ds = begId-begId+1 : endId-begId+1  %length(infile)
            DS_LIST{DC} = [ DS_LIST{DC} ds ];
        end
        % 2nd case: if to take all GRP
    elseif any( isempty( GRP{1,DC})) || any( strcmp( GRP{1,DC} , 'all') ) %lists subjects finishing with specified design.sesPosStart and design.sesPosEnd
        
        for ss = 1 : length( SES{1,DC} )
            
            for ds = begId-begId+1 : endId-begId+1 
                
                [fp,fn,fe] = fileparts(infile{ds});
                if strcmp( fn( design.sesPosStart :  design.sesPosEnd) , SES{1,DC}{1,ss} ) % if name of SESsion overlaps with name of infile (within given index) saves it.
                    DS_LIST{DC} = [ DS_LIST{DC} ds ];
                end
                clear fp fn fe
            end
        end
        
        % 3rd case: if to take all SES
    elseif any( isempty( SES{1,DC})) || any( strcmp( SES{1,DC} , 'all') ) %lists subjects finishing with specified design.sesPosStart and design.sesPosEnd
        
        for gg = 1 : length( GRP{1,DC} )
            
            for ds = begId-begId+1 : endId-begId+1 
                [fp,fn,fe] = fileparts(infile{ds});
                if strcmp( fn( design.grpPosStart : design.grpPosEnd), GRP{1,DC}{1,gg} )
                    DS_LIST{DC} = [ DS_LIST{DC} ds ];
                end
                clear fp fn fe
                
            end
        end
        
        %4th case: both SES and GRP are specified
    else
        
        for sg = 1 : length( GRP{1,DC} )
            for ds = begId-begId+1 : endId-begId+1 
                [fp,fn,fe] = fileparts(infile{ds});
                if strcmp( fn(design.grpPosStart :  design.grpPosEnd ), GRP{1,DC}{1,sg} ) && strcmp( fn( design.sesPosStart : design.sesPosEnd ), SES{1,DC}{1,sg} ) %both SES and GRP names must agree with infile ds name,
                    DS_LIST{DC} = [ DS_LIST{DC} ds ];
                end
                clear fp fn fe
                
            end
        end        
    end
    
    %eliminating ds_exclude elements from the DS_LIST
    for ds_ex = ds_exclude
        DS_LIST{DC}(DS_LIST{DC} == ds_ex) = [];
    end
    
    DS_LIST{DC} = sort( DS_LIST{DC}, 'ascend');
    
end

%% TRIGGER LIST   %%%

% Trigger lists based on specified COND(i) are built here

for DC = 1 : DCnr % length(SES)
    
    trig_COND = [];
    TRIG_LIST{DC} = [];
    
    for c = 1 : length(design.COND)
        trig_COND(c).DS{1,DC} = [];
        
        for ii = 1 : length( COND(c).DS{1,DC} )
            [tf,idx] = ismember( COND(c).DS{1,DC}{1,ii} , design.COND(c).name );
            if tf==0 & idx==0
                error('design is not properly defined. check condition names and DC definitions');
            end
            for tr = 1:length( design.COND(c).trig{ 1, idx } )
                trig_COND(c).DS{1,DC} = [ trig_COND(c).DS{1,DC} design.COND(c).trig{ 1, idx}{ 1, tr } ];
            end
        end
        
    end
    
    % if there is more than one level of contitions, their intersection is calculated here
    if length(design.COND) >= 2
        
        if length(design.COND) == 2
            for c = 1 : ( length(design.COND) - 1 ) %if there are just two conditions one intersection works
                TRIG_LIST{DC} = intersect( trig_COND(c+1).DS{1,DC}, trig_COND(c).DS{1,DC} );
            end
        else  %more than two levels
            TRIG_LIST{DC} = intersect( trig_COND(2).DS{1,DC}, trig_COND(1).DS{1,DC} );  %intersect between 1st and 2nd lev
            for c = 2 : ( length(design.COND) - 1 )
                TRIG_LIST{DC} = intersect( trig_COND(c+1).DS{1,DC}, TRIG_LIST{DC} );
            end
        end
        
    else
        TRIG_LIST{DC} = trig_COND(1).DS{1,DC};     
    end
    
end


%% DATA   CALCULATION %%%

% ERP data and grandAveraging over ERP for given DC_LISTs is done here

clear DATA
warn_message = '';

%checks if data with given configuration has been already computed
if exist( fullfile(saveFolder, NAME{DC}) ) && strcmp(rc.load_artrej, 'L')
    
    for DC = 1 : length(SES)
        
        disp( ['Loading previosuly calculated grandAveraged data from file: ' NAME{DC} ]);
        % DATA{DC} = load( [saveFolder '/' NAME{DC} '/' NAME{DC} '.mat']).data_grandERP;
        datatmp = load( [saveFolder '/' NAME{DC} '/' NAME{DC} '.mat']);
        DATA{DC} = datatmp.data_grandERP;
        clear datatmp
        
        for ds = 1:length( DS_LIST{DC} )
            disp( ['Loading previosuly calculated averaged data ds: ' num2str( DS_LIST{DC}(ds) ) ]);
            dataERP{1,DC}(ds) = load( [saveFolder '/' NAME{DC} '/ds' num2str( DS_LIST{DC}(ds) ) '.mat']).ds_ERP;
        end
    end
    
else
    
    clear dataERP instr
    
    for DC = 1 : length(SES)
        
        for ds = 1 : length( DS_LIST{DC} )
            
            if isempty(TRIG_LIST{DC})
                msgg=['NO TRIALS FOUND for DC ' num2str(DC) '; DS: ' replace(dsname, '_ARJ', '') ' !!!'];
                warning (msgg)
                clear msgg
            end
            
            [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{DS_LIST{1,DC}(ds)} ); % extract file path, data set name, and extension
            disp( ['DC ', num2str(DC), ': [' num2str( round( ds / length( DS_LIST{DC} ) *100 ) ) '%] Calculating ERP for ds: ' num2str( DS_LIST{1,DC}(ds) ) ' - ' dsname] );
            
            cfg = [];
            cfg.trials = [];
            
            for tr = 1:length( TRIG_LIST{DC} ) %finding all trials related to given trigger list
                cfg.trials = [cfg.trials find( data_all_arj( DS_LIST{1,DC}(ds) ).trialinfo(:,1) == TRIG_LIST{1,DC}(tr))']; %goes through all triggers on trig list and find their position in data
            end
            
            if length(cfg.trials) <= cond_tr_limit % disply warning if number of trials is belove specified threshold
                warn_message = [ warn_message, newline, strcat('For DC ', num2str(DC), ' ds: ', num2str(ds), ' has just ', num2str( length(cfg.trials)), ' trials. The threshold limit is  ', num2str(cond_tr_limit) ) ];
            end
            
            cfg.datafile = infile{DS_LIST{1,DC}(ds)}; %needs to be provided too
            cfg.dataset = infile{DS_LIST{1,DC}(ds)};
            dataERP{1,DC}(ds) = ft_timelockanalysis(cfg, data_all_arj( DS_LIST{1,DC}(ds) ) ); % performs analysis for each ds separately            
            dataERP{1,DC}(ds).cfg = []; % WARNING - USED TO SAVE DISC SPACE. SO FAR NO SIDE EFEECTS OBSERVED DURING GRANDAVERAGING
            
        end
        
        % building instruction for grand averaging.
        % due to specification of ft_timelockgrandaveraging it has to be built from string.
        
        instr{DC} = [];
        instr{DC} = ['ft_timelockgrandaverage(cfg,'];
        
        if isempty( DS_LIST{DC}  )
            error( ['There is no single ds in DC:' , num2str(DC)] );
        end
        
        for ds = 1:length( DS_LIST{DC}  )
            instr{DC} = [ instr{DC} 'dataERP{1,' num2str(DC) '}(' num2str(ds) '), '];
        end
        
        instr{DC} = instr{DC}( 1 , 1:end-2 ); %removes last coma
        instr{DC} = [ instr{DC} ');' ];
        
        cfg = [];
        cfg.covariance = 'yes';
        cfg.covariancewindow = [-inf 0];
        DATA{DC} = eval( instr{DC} ); % final calling of ft_timelockgrandaveraging( cfg, dataERP{1,1}, ..., dataERP{1, length(dataERP{DC}) } )
        DATA{DC}.cfg = []; %might be useful leter in order to save disc space
        
        %saving data
        data_grandERP = DATA{DC};
        data_grandERP.cfg = []; %saves disc space | data_grandERP.cfg.previous = [];
        
        if ~exist( [saveFolder '/' NAME{DC}] )
            mkdir( [saveFolder '/' NAME{DC}] );
        end
        
        save( [saveFolder '/' NAME{DC} '/' NAME{DC} '.mat'] , 'data_grandERP'); %saves grand averaged data
        
        for ds = 1:length( DS_LIST{DC} ) %saves individual ERPs
            
            ds_ERP = dataERP{1,DC}(ds);
            save( [saveFolder '/' NAME{DC} '/ds' num2str( DS_LIST{DC}(ds) ) ] , 'ds_ERP' );
            
        end
        
    end
    
end

warning(warn_message); %display warning with information of remaining trials



%% VISUALISATION OF ERPs   %%%
% Here calculated ERPs are visualised in an interactive mode (all DC are plotted)

%specify axis parameters
ylim_start = -8;
ylim_end = 16;

xlim_start = -1 * seg.prestim;
xlim_end = seg.poststim;

%code below runs automatic ERP visualisation
title = [];
for DC = 1:length(NAME)
    title = [ title ' vs ' NAME{DC} ];
end
title = title(1, 5:end);

load(fullfile(analysisFolder, '1_PREPROCESSED/', 'layout.mat'))

cfg = [];
cfg.fontsize = 8;
cfg.linewidth   = 1.5;
cfg.layout = layout;
cfg.xlim = [xlim_start xlim_end];
% cfg.ylim = [ylim_start ylim_end];
cfg.showlabels = 'yes'; %shows labels AF7, CPz and so on
cfg.figurename  = title;
cfg.dataname  = NAME; % used when naming DC in ft_sigleplot
cfg.showlegend  = 'yes'; %uses NAME{i} to create legend with DC names.
cfg.baseline = 'no';
cfg.interactive = 'yes'; % enables interactive selecion of given channels by useing ft_singleplot
cfg.showoutline = 'yes'; % draws outerline of the head model on multiplot
cfg.showscale = 'no'; %in order to avoid plotting an extra box with axes' limits.
cfg.showcomment = 'yes'; % yes if youw want to see axes limits and name of each DataConfiguration.
cfg.linecolor   = 'bgrkym';
% cfg.refchannel  = {'A1', 'A2'};

instr_plot = 'ft_multiplotER(cfg, '; %again, instruction for ft_multiplotER must be built manually

for DC = 1:length(DATA)
    instr_plot = [ instr_plot 'DATA{1,' num2str(DC) '}, ' ];
end

instr_plot = instr_plot(1,1:end-2); %removes last coma
instr_plot = [instr_plot ');'];

gcf = figure('Name', title ,'NumberTitle','on','visible','on');
eval(instr_plot); % finall call of ft_multiplotER( cfg, DATA{1,vis_DC_list(1)}, ..., DATA{1, vis_DC_list(length(vis_DC_list))} )
set(gcf,'name', title ,'numbertitle','off'); %since cfg.figure name ap

