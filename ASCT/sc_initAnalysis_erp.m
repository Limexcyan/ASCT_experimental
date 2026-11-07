analysisFolder = fullfile(rc.expFolder , rc.analysisName);
bdfFolder = fullfile( rc.expFolder , '0_bdf'); %specifies path to '*bdf' files. 

channels = [chan.eeg chan.eog]; %representation of all channels consist of both eeg and eog channels
channels = sort(channels);  

DCnr = DC;

%% TRIGGER LIST %%%
    % that is calculated for function SEGM

    trig_list = {};
    for i = 1:length( design.COND )        
        for j = 1 : length( design.COND(i).trig )
            for k = 1 : length( design.COND(i).trig{1,j} ) 
                trig_list = [ trig_list design.COND(i).trig{1,j}{1,k} ];
            end
        end
    end
    
    seg.trig_list = num2cell( unique( cell2mat(trig_list) ) );


%% START OF FUNCTION CALL  %%%%%%

% manage parpool

if rc.useParallel>0 
    
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        parpool(rc.useParallel);
    else
        if poolobj.NumWorkers ~= rc.useParallel
            delete(poolobj);
            parpool(rc.useParallel);
        end
    end
    
end

% setting defaults

if ~isfield(seg, 'origTrig'); seg.origTrig = []; end



%calling given functions
if strcmp(rc.load_prep , 'L')
    sc_2_SEGM; %if recodding is needed for further data analysis, please check specification in sc_SEGM script
    sc_3_ARTIFACTS;
    sc_4_ERPanalysis;

elseif strcmp(rc.load_segm , 'L')
    sc_3_ARTIFACTS;
    sc_4_ERPanalysis;

elseif strcmp(rc.load_artrej , 'L') || strcmp(rc.load_artrej , 'F') 
    sc_4_ERPanalysis;
    
else
    sc_1_PREPROC;
    sc_2_SEGM; %if recodding is needed for further data analysis, please check specification in sc_SEGM script
    sc_3_ARTIFACTS;
    sc_4_ERPanalysis; % if manual specification of SES and GRP is needed, please check sc_ERPanalysis_SES_set_manual
end
    
    
