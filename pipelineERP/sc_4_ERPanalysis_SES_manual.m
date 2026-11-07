
%%%%%%%%% ERP ANALYSIS %%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% NOTE: the exist an oportunit to exclude given DS in data analysis by specifying them in 'ds_exclude'.

% 5. DATA REVIEW
% Dor further review see '_sc_VISUALISATION'. It allows comparison between chosen DC. With 'vis_DC_list' parameter specyfying which DC should be taken into account during visualisation.
% For emegs export see 'sc_exportEMEGS' which takes 'EMEGS_export' parameters (either 'all' or 'avg' for all ds or just grandaveraged data respectively)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% DATA NO ARTIFACT LOADING %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
if ( strcmp(rc.load_artf, 'L') && ~exist('data_all_artf')  )     %load no artif data

    loadFolder = [analysisFolder '/3_NO_ARTIFACT' ];

    if ~exist(loadFolder)

        error( ['There is no /3_NO_ARTIFACT folder.' , sprintf('\n'), 'Most likely no artifact data havent been saved'] );
        
    else
        
        % reading 'no artifact' files 
        if exist('begId') & exist('endId')

            matfiles(begId : endId) = sc_reading(loadFolder, '*NO_ARTF.mat', begId, endId); %reads '.bdf' files from begId to endId

        else

            matfiles = sc_reading(loadFolder, '*NO_ARTF.mat'); %reads all files with '.bdf' extension
            begIdARTF = 1;
            endIdARTF = length(matfiles);

        end

        for ds = begIdARTF : endIdARTF
            
            % preparing infile variable
            if isempty(matfiles{ds})
                %do nothing %this skips empty matfiles instances. For example, if user wants to load ds from 32 on.
            else

                [tmpinpathname, dsname, tmpmatfilesext] = fileparts( matfiles{ds} ); %decomposing matfiles name into parts

                idcs   = strfind(tmpinpathname,'/'); %finding indexes of '/'
                inpathname = tmpinpathname( 1 : idcs(end-1) ); %going back two directories (what is from 3_ARTIFACTS to the main idrectory) last idcs indicates last '/'
                inpathname = [inpathname '0_bdf']; %going into 0_bdf directory

                dsname = dsname(1:end-8); %stripping 'NO_ARTF' sufix from file name
                matfilesext = '.bdf'; %asigning '.bdf' extension instead of '.mat' extension.

                filename = fullfile(inpathname, dsname); %building file name
                infile{ds} = [filename matfilesext]; %adding extension
            end
            
        end
        
        % actual loading ds
        for ds = begIdARTF : endIdARTF

            disp([' [' num2str( round( 100 * (ds-begIdARTF+1) / (endIdARTF-begIdARTF+1) ) ) '%] Loading DS', num2str(ds), ' - ', infile{ds}, ' file - no artf data'] );

            [tmpinpathname, dsname, tmpinfileext] = fileparts(infile{ds});
            load_file = [loadFolder,'/', dsname, '_NO_ARTF.mat']
            load( load_file, 'data_artf' );

            data_all_artf(ds) = data_artf;

        end
                
    end
    
    

elseif ( strcmp(rc.load_artf, 'L') && exist('data_all_artf') )      %skip loading no artif data if they are already present in memory

    disp( [ 'Using either:', sprintf('\n'), '1. no arifact data from memory (assuming no data change in data_all_artf!!!)', sprintf('\n'), 'or', sprintf('\n'), '2. loading previously calculated ERP (if given design configuration has been calcluated before)', sprintf('\n') ] );
    
else

    disp('Continuing ERP analysis after artifact rejection or loading prviously calculated ERP');
        
end

% saveFolder should be assigned here
saveFolder = [analysisFolder '/4_AVERAGED' ];

if ~exist(saveFolder)
    mkdir(saveFolder);
end

%%%%%%%%%%%%%%%%%%%%%%%
%%%%% EXCLUDING %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%

include = ones( length(infile) ); %contain matrix with ones which are filled with zeros if subject is wanted to be excluded from analysis

for ds = ds_exclude
    include(ds) = 0;
end

%%%%%%%%%%%%%%
%%% NAME   %%%
%%%%%%%%%%%%%%
% Here names of Data Configurations are speciied. They are further used to save already computed data.

for DC = 1 : length( SES ) %checks how many DataConfiguration has been specified. Must be at least two.
       
    NAME{DC} = [];
    
%sorting GRP, SES and COND (in order to save it alphabetically)
    sort( GRP{1,DC} );
    sort( SES{1,DC} );
    
    for c = 1 : length(design.COND) %goes through all condition fields cond(1), ..., cond(N)
        sort( COND(c).DS{1,DC} );
    end
    
    
%%% actual naming of DataConfigurations
    
    %GRP
    if any( isempty(GRP{1,DC})) | any( strcmp( GRP{1,DC} , 'all') ) %if there is no GRP specified or it is specified as all, call it 'all'
        NAME{DC} = [ NAME{DC} '-' 'all'];
    else %othervise add each GRP instance to the name
        
        for ii = 1:length(GRP{1,DC})
            NAME{DC} = [ NAME{DC} '-' GRP{1,DC}{1,ii} ];
        end
        
    end
    
    %SES
    if any( isempty(SES{1,DC})) | any( strcmp( SES{1,DC} , 'all') ) %if there is no SES specified or it is specified as all, call it 'all'
        NAME{DC} = [ NAME{DC} '-' 'all'];
    else %othervise add each SES instance to the name
        
        for ii = 1:length(SES{1,DC})
            NAME{DC} = [ NAME{DC} '-' SES{1,DC}{1,ii} ];
        end
        
    end
    
    if exist('begIdARTF') & exist('endIdARTF')
 
        NAME{DC} = [ NAME{DC} '-' 'ds-allARTF' ]; 
        
    elseif exist('begId') & exist('endId') %begId always exists but endId exists only if it was specified in EX_SETUP
        
        NAME{DC} = [ NAME{DC} '-' 'ds-',num2str(begId),'-',num2str(endId) ]; 
        
    else         
        %don't add any more details to NAME        
    end
    
    %COND
    for c = 1 : length(design.COND)
        
        NAME{DC} = [ NAME{DC} '-' ];
        
        for ii = 1:length( COND(c).DS{1,DC} )
            NAME{DC} = [ NAME{DC} COND(c).DS{1,DC}{1,ii} ',']; %add all instances of each COND to the name
        end
        
        NAME{DC} = NAME{DC}(1 , 1:end-1);
    end
    
    %adding excluded ds to the name (so that the datasets with excluded ds can differ from this with all ds included)
    if length( ds_exclude>=1 )
    NAME{DC} = [ NAME{DC} '_no']    
        for ds_ex = ds_exclude
            NAME{DC} = [ NAME{DC} '-' num2str(ds_ex) ];
        end
    end
    
    NAME{DC} = NAME{DC}(1 , 2:end); %removes first'-'
    
end


%%%%%%%%%%%%%%%%%%%%%%
%%% DATASET LISTS  %%%
%%%%%%%%%%%%%%%%%%%%%%
% Creating dataset list based on GRP and SES specifications


% if exist('begIdARTF') & exist('endIdARTF')
%     begId = begIdARTF;
%     endId = endIdARTF;
%         
% elseif exist('begId') & exist('endId')
%     %do nothing    
% else
%     begId = 1;
%     endId = length(data_all_artf);      
% end
% 
% for DC = 1 : length(SES)
%     
%     DS_LIST{DC} = []; 
%     
%     % 1st case: if to take all SES and GRP
%     if (any( isempty( SES{1,DC})) | any( strcmp( SES{1,DC} , 'all') ) ) & any( isempty( GRP{1,DC})) | any( strcmp( GRP{1,DC} , 'all') )%lists all subjects ||| any converts logical arrays into single logical character (0 or 1 insted of 0x0 logic array)
%     
%         for ds = begId : length(data_all_artf)
%             DS_LIST{DC} = [ DS_LIST{DC} ds ];
%         end
%     % 2nd case: if to take all GRP
%     elseif any( isempty( GRP{1,DC})) | any( strcmp( GRP{1,DC} , 'all') ) %lists subjects finishing with specified design.sesPosStart and design.sesPosEnd
% 
%         for ss = 1 : length( SES{1,DC} )
% 
%             for ds = begId : length(data_all_artf)
% 
%                 if strcmp( infile{ds}(1 , (end - design.sesPosStart) :  (end - design.sesPosEnd) ), SES{1,DC}{1,ss} ) % if name of SESsion overlaps with name of infile (within given index) saves it.
% 
%                     DS_LIST{DC} = [ DS_LIST{DC} ds ];
% 
%                 end
%             end
%         end
%     
%     % 3rd case: if to take all SES
%     elseif any( isempty( SES{1,DC})) | any( strcmp( SES{1,DC} , 'all') ) %lists subjects finishing with specified design.sesPosStart and design.sesPosEnd
% 
%         for gg = 1 : length( GRP{1,DC} )
% 
%             for ds = begId : length(data_all_artf)
%                 
%                 if strcmp( infile{ds}(1 , (end - design.grpPosStart) :  (end - design.grpPosEnd) ), GRP{1,DC}{1,gg} )
% 
%                     DS_LIST{DC} = [ DS_LIST{DC} ds ];
% 
%                 end
%             end
%         end
%     
%     %4th case: both SES and GRP are specified
%     else 
% 
%         for sg = 1 : length( GRP{1,DC} )
% 
%             for ds = begId : length(data_all_artf)
% 
%                 if strcmp( infile{ds}(1 , (end - design.grpPosStart) :  (end - design.grpPosEnd) ), GRP{1,DC}{1,sg} ) & strcmp( infile{ds}(1 , (end - design.sesPosStart) :  (end - design.sesPosEnd) ), SES{1,DC}{1,sg} ) %both SES and GRP names must agree with infile ds name,
% 
%                     DS_LIST{DC} = [ DS_LIST{DC} ds ];
% 
%                 end
%             end
%         end
% 
%     end
%     
%     %eliminating ds_exclude elements from the DS_LIST
%     for ds_ex = ds_exclude
%         DS_LIST{DC}(DS_LIST{DC} == ds_ex) = []; 
%     end
%     
%     DS_LIST{DC} = sort( DS_LIST{DC}, 'ascend');
% 
% end


%%%%%%%%%%%%%%%%%%%%%%
%%% TRIGGER LIST   %%%
%%%%%%%%%%%%%%%%%%%%%%
% Trigger lists based on specified COND(i) are built here

for DC = 1 : length(SES)
    
    TRIG_LIST{DC} = [];
    
    for c = 1 : length(design.COND)
        trig_COND(c).DS{1,DC} = [];
    
        for ii = 1 : length( COND(c).DS{1,DC} )
            [tf,idx] = ismember( COND(c).DS{1,DC}{1,ii} , design.COND(c).name );

            for tr = 1:length( design.COND(c).trig{ 1, idx } )
                trig_COND(c).DS{1,DC} = [ trig_COND(c).DS{1,DC} design.COND(c).trig{ 1, idx}{ 1, tr } ];
            end

        end
    
    end

    % if there is more than one level of contitions, their intersection is calculated here
    if length(design.COND) >= 2
        
        for c = 1 : ( length(design.COND) - 1 ) %if there are just two conditions one intersection works
            TRIG_LIST{DC} = intersect( trig_COND(c+1).DS{1,DC}, trig_COND(c).DS{1,DC} );
        end
        
    else
        
        TRIG_LIST{DC} = trig_COND(1).DS{1,DC};
        
    end
        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% DATA   CALCULATION %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%
% ERP data and grandAveraging over ERP for given DC_LISTs is done here

warn_message = '';

%checks if data with given configuration has been already computed
if exist( [saveFolder '/' NAME{DC} '.mat'] )

    for DC = 1 : length(SES)
        disp( ['Loading previosuly calculated grandAveraged data from file: ' NAME{DC} ]);
        DATA{DC} = load( [saveFolder '/' NAME{DC} '.mat']).data_grandERP;
    end
    
else
    
    clear dataERP instr
    
    for DC = 1 : length(SES)     
        
        for ds = 1 : length( DS_LIST{DC} )
            
        if isempty( data_all_artf( DS_LIST{1,DC}(ds) ).hdr )
    
            error(['There is no data in data_all_artf(',num2str(ds),').' sprintf('\n'), 'It may happen that due to begId and endId speficifaction this ds has not been clan from artifacts earlier'] );
    
        else
            
            [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{DS_LIST{1,DC}(ds)} ); % extract file path, data set name, and extension
            disp( ['DC ', num2str(DC), ': [' num2str( round( ds / length( DS_LIST{DC} ) *100 ) ) '%] Calculating ERP for ds: ' num2str( DS_LIST{1,DC}(ds) ) ' - ' dsname] );

            cfg = [];
            cfg.trials = [];

            for tr = 1:length( TRIG_LIST{DC} ) %finding all trials related to given trigger list

                cfg.trials = [cfg.trials find( data_all_artf( DS_LIST{1,DC}(ds) ).trialinfo(:,1) == TRIG_LIST{1,DC}(tr))']; %goes through all triggers on trig list and find their position in data

            end
            
            if length(cfg.trials) <= cond_tr_limit % disply warning if number of trials is belove specified threshold
                warn_message = [ warn_message, sprintf('\n'), strcat('For DC ', num2str(DC), ' ds: ', num2str(ds), ' has just ', num2str( length(cfg.trials)), ' trials. The threshold limit is  ', num2str(cond_tr_limit) ) ];
            end
            
            %disp( [ 'For DC ' num2str(DC) ' ds ' num2str( DS_LIST{1,DC}(ds) ) ' - ' dsname ', trl = ' num2str(cfg.trials) ] );
            
            cfg.datafile = infile{DS_LIST{1,DC}(ds)}; %needs to be provided too
            cfg.dataset = infile{DS_LIST{1,DC}(ds)};
            %cfg = [];
%             cfg.covariance = 'yes';
%             cfg.covariancewindow = [-inf 0];
            dataERP{1,DC}(ds) = ft_timelockanalysis(cfg, data_all_artf( DS_LIST{1,DC}(ds) ) ); % performs analysis for each ds separately
            
            dataERP{1,DC}(ds).cfg = []; % WARNING - USED TO SAVE DISC SPACE. SO FAR NO SIDE EFEECTS OBSERVED DURING GRANDAVERAGING

        end
        
        end
        
        
        % building instruction for grand averaging. 
        % due to specification of ft_timelockgrandaveraging it has to be built from string.
        
        instr{DC} = [];
        instr{DC} = ['ft_timelockgrandaverage(cfg,'];

        for ds = 1:length( DS_LIST{DC}  )  

            instr{DC} = [ instr{DC} 'dataERP{1,' num2str(DC) '}(' num2str(ds) '), '];

        end

        instr{DC} = instr{DC}(1,1:end-2); %removes last coma
        instr{DC} = [instr{DC} ');'];

        cfg = [];
        cfg.covariance = 'yes';
        cfg.covariancewindow = [-inf 0];
        DATA{DC} = eval( instr{DC} ); % final calling of ft_timelockgrandaveraging( cfg, dataERP{1,1}, ..., dataERP{1, length(dataERP{DC}) } )
        DATA{DC}.cfg = []; %might be useful leter in order to save disc space
        
        %saving data
        data_grandERP = DATA{DC};
        data_grandERP.cfg = []; %saves disc space | data_grandERP.cfg.previous = [];
        save( [saveFolder '/' NAME{DC} '.mat'] , 'data_grandERP');
        
    
    end

end

warning(warn_message); %display warning with information of remaining trials


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% VISUALISATION OF EPR   %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here calculated ERPs are visualised in an interactive mode (all DC are plotted)

%specify axis parameters
ylim_start = -8; 
ylim_end = 16;
    
xlim_start = -1 * seg.prestim;
xlim_end = seg.poststim;

%code below runs automatical ERP visualisation
title = [];
for DC = 1:length(NAME)
    title = [ title ' vs ' NAME{DC} ];
end
title = title(1, 5:end);

cfg = [];
cfg.fontsize = 8;
cfg.linewidth   = 1.5;
cfg.layout = chan.layout_type;
cfg.xlim = [xlim_start xlim_end];
cfg.ylim = [ylim_start ylim_end];
cfg.showlabels = 'yes'; %shows labels AF7, CPz and so on
cfg.figurename  = title;
cfg.dataname  = NAME; % used when naming DC in ft_singleplot
cfg.showlegend  = 'yes'; %uses NAME{i} to create legend with DC names.
cfg.baseline = 'no';
cfg.interactive = 'yes'; % enables interactive selecion of given channels by useing ft_singleplot
cfg.showoutline = 'yes'; % draws outerline of the head model on multiplot
cfg.showscale = 'no'; %in order to avoid plotting an extra box with axes' limits.
cfg.showcomment = 'yes'; % yes if youw want to see axes limits and name of each DataConfiguration.
cfg.linecolor   = 'bgrkym';
cfg.refchannel  = {'A1', 'A2'}; 

instr_plot = 'ft_multiplotER(cfg, '; %again, instruction for ft_multiplotER must be built manually

for DC = 1:length(DATA)
    instr_plot = [ instr_plot 'DATA{1,' num2str(DC) '}, ' ];
end

instr_plot = instr_plot(1,1:end-2); %removes last coma
instr_plot = [instr_plot ');'];

figure('Name', title ,'NumberTitle','on');
eval(instr_plot); % finall call of ft_multiplotER( cfg, DATA{1,vis_DC_list(1)}, ..., DATA{1, vis_DC_list(length(vis_DC_list))} )
set(gcf,'name', title ,'numbertitle','off'); %since cfg.figure name ap