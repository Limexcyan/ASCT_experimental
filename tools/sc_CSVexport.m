% This function allows export to CSV.
% It exports either grandaveraged data or both grand averaged as well as timewidow and channel selected data
% If all ds are exported an additional list with emegs ds paths is created.
%
% % here specify if you want to export just grandAveraged data or both grandAveraged as well as timewidow and channel selected data
% CSV_save_par = 'all' % 'all'  or 'avg'
%
% % if here you have choosen 'all', please specify below timewindow and channel lists of your interest.
% CSV_win_def = { {'P3', 400, 450} , { 'LPP1', 500, 700} };
% CSV_ele_def = { {'Cz', 'FCz'}, {'Cz'} };

% CSV_save_par = 'avg'; % 'all'  or 'avg'  %temporary set for all as it exports averagas !FIXME



%% ARTIFREE DATA LOADING %%%%%%%

loadFolder = [analysisFolder '/3_ARTIFREE' ];

infile_all = sc_reading(loadFolder, '*ARJ.mat'); %reads ART REJ files from begId to endId   %mmw
infile = infile_all;

if ~exist('data_all_arj')
    
    if exist('begId') && exist('endId')
        infile = infile_all(begId : endId);   %mmw
        warning('USING ONLY SUBSET OF FILES as begId and endId are set!');
    end
    
    if ~exist('begId'); begId=1; end   %mmw
    
    for ds = begId : length(infile)   % actual loading on ART REJ data
        disp([' [' num2str( round( 100 * (ds-begId+1) / (length(infile)-begId+1) ) ) '%] Loading DS', num2str(ds), ' - ', infile{ds}, ' artifact free data'] );
        load( infile{ds}, 'data_artf' );
        data_all_arj(ds) = data_artf;
    end
end

saveFolder = [analysisFolder '/4_AVERAGED' ];
if ~exist(saveFolder); mkdir(saveFolder); end


%%% Actual code of the function %%%

if ~exist('CSV_save_subdir')
    CSV_save_subdir = '';
end

samp_freq = data_all_arj(1).fsample;


%% NO SMOTHING %%%


if ~exist('ERP_smoothing');ERP_smoothing=0; end

condlev=size(COND,2);

if ERP_smoothing == 0
    
    disp('unsmoothed DATA export');
    
    if strcmp(CSV_save_par, 'all')
        if ~exist('DC_list')
            
            for DC = 1:length(DATA)
                exportFolder = fullfile(analysisFolder, '5_EXPORT', NAME{DC});
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
            end
            
            disp('CSV export - AVG - option. DC_list doesnt exist. All DC has been saved.');
            
        else
            
            for DC = DC_list
                exportFolder = fullfile(analysisFolder, '5_EXPORT', NAME{DC});
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
            end
            
            disp( [ 'CSV export - AVG - option. Since DC_list exists. DC ' num2str(DC_list) ' has been saved' ] );
        end
    end
    
    if ~exist('DC_list')
        
        clear ods_matrix_export
        
        file_list = '';
        
        %%% filling fixed elements of the table
        % filling elements 11, 12, 13, 14
        ods_matrix_export{1,1} = 'ID';
        ods_matrix_export{1,2} = 'GR';
        ods_matrix_export{1,3} = 'SES';
        for c=1:condlev
            ods_matrix_export{1,3+c} = strcat ('COND', num2str(c));
        end
        
        % filling elements related to widows and channels selection
        we_ind = 1;
        
        for w = 1:length(CSV_win_def)
            
            for e = 1: length(CSV_ele_def)
                
                ch_str = ''; % here string with channel list refered to given condition is kept
                
                for ch = 1: length(CSV_ele_def{e})
                    ch_str = [ ch_str , CSV_ele_def{e}{ch} , '+']; %channels from the same conditions are concatenated with '+'
                end
                
                ch_str = ch_str(1:end-1);
                
                ods_matrix_export{1,4+we_ind} = [ CSV_win_def{w}{1} , '(' , num2str(CSV_win_def{w}{2}) , '-' , num2str(CSV_win_def{w}{3}) , ').' , ch_str ];
                we_ind = we_ind + 1;
                
            end
        end
        
        % calculating mean values
        for DC = 1 : length( DATA )
            ods_matrix_export=ods_matrix_export(1,:); %clean export matrix except the header line
            
            exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
            
            if ~exist(exportFolder)
                mkdir(exportFolder);
            end
            
            for ds = 1 : length( dataERP{1,DC} )
                
                % for each ds id, gr, ses and cond_name are being alocated
                id = '';
                gr = '';
                ses = '';
                cond_name = '';
                
                [~, dsname, ~] = fileparts(infile{ DS_LIST{DC}(1,ds) });
                id=dsname(design.idPosStart:design.idPosEnd);
                gr=dsname(gr_pos_start:gr_pos_end);
                ses=dsname(design.sesPosStart:design.sesPosEnd);
                
                %COND
                for c = 1 : condlev
                    cond_name = [ cond_name COND(c).DS{DC} '-']; %add all instances of each COND to the name
                end
                cond_name = cond_name(1 , 1:end-1);
                cond_name = strrep(string(strjoin(cond_name)),' ','');
                
                % assigning id, gr, ses and cnd_name to the matrix
                ods_matrix_export{1+ds,1} = id;
                ods_matrix_export{1+ds,2} = gr;
                ods_matrix_export{1+ds,3} = ses;
                ods_matrix_export{1+ds,4} = cond_name;
                
                %actual computing of averaged data
                
                we_index = 1;
                
                for w = 1 : length(CSV_win_def)
                    
                    start_samp =  round ( (seg.prestim + CSV_win_def{w}{2}/1000 ) * samp_freq) ; %start timepoint for averaging
                    if start_samp == 0; start_samp=1; end
                    end_samp = round ( (seg.prestim + CSV_win_def{w}{3}/1000 ) * samp_freq ) ; %end timepoint for averaging
                    
                    for e = 1 : length(CSV_ele_def)
                        
                        ch_ind = []; %indexes of raws for given channels are kept here. They are subsequently used to specify for which row averaging should be applied
                        
                        for el = 1: length( CSV_ele_def{e} )
                            
                            i_ch = [];
                            i_ch = ismember( dataERP{1, DC}(ds).label, CSV_ele_def{e}{el} ); %marks fittinf elements as 1
                            i_channel = find(i_ch, 1); %finds which elements are equal to 1
                            ch_ind = [ ch_ind i_channel ]; %saves which one are equal 1
                            
                        end
                        
                        ERP_mean = mean( dataERP{1,DC}(ds).avg( ch_ind, start_samp : end_samp), 'all' );
                        
                        % tu wpisać całość
                        ods_matrix_export{ 1+ds , 4+we_index } = ERP_mean;
                        we_index = we_index+1;
                        
                    end
                end
            end
            
            writecell(ods_matrix_export, [exportFolder '/' 'CSV_averages.xls'] , 'Sheet',1, 'WriteMode', 'overwrite'); % saving ods_matrix_export
            
        end
        
    else %DC_list exists
        
        clear ods_matrix_export
        file_list = '';
        
        %%% filling fixed elements of the table
        ods_matrix_export{1,1} = 'ID';
        ods_matrix_export{1,2} = 'GR';
        ods_matrix_export{1,3} = 'SES';
        ods_matrix_export{1,4} = 'COND';
        %             end
        
        % filling elements related to widows and channels selection
        we_ind = 1;
        
        for w = 1 : length(CSV_win_def)
            
            for e = 1 : length(CSV_ele_def)
                
                ch_str = ''; % here string with channel list refered to given condition is kept
                
                for ch = 1 : length(CSV_ele_def{e})
                    ch_str = [ ch_str , CSV_ele_def{e}{ch} , '+']; %channels from the same conditions are concatenated with '+'
                end
                
                ch_str = ch_str(1:end-1);
                
                %                     ods_matrix_export{1,3+c+we_ind} = [ CSV_win_def{w}{1} , '(' , num2str(CSV_win_def{w}{2}) , '-' , num2str(CSV_win_def{w}{3}) , ').' , ch_str ];
                ods_matrix_export{1,4+we_ind} = [ CSV_win_def{w}{1} , '(' , num2str(CSV_win_def{w}{2}) , '-' , num2str(CSV_win_def{w}{3}) , ').' , ch_str ];
                we_ind = we_ind + 1;
                
            end
        end
        
        for DC = DC_list %loop over grandAveraged data
            
            ods_matrix_export=ods_matrix_export(1,:); %clean export matrix except the header line
            
            exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
            exportFileName = [NAME{DC} '.xls'];
            
            if ~exist(exportFolder); mkdir(exportFolder); end
            
            for ds = 1 : length( dataERP{1,DC} ) %loop over individual ds
                
                
                % for each ds id, gr, ses and cond_name are being alocated
                id = '';
                gr = '';
                ses = '';
                cond_name = '';
                
                [~, dsname, ~] = fileparts(infile{ DS_LIST{DC}(1,ds) });
                id=dsname(design.idPosStart:design.idPosEnd);
                gr=dsname(design.grpPosStart:design.grpPosEnd);
                ses=dsname(design.sesPosStart:design.sesPosEnd);
                
                %COND
                for c = 1 : condlev    %length(COND.DS{DC})
                    cond_name = [ cond_name COND(c).DS{DC} '-']; %add all instances of each COND to the name
                end
                cond_name = cond_name(1 , 1:end-1);
                cond_name = strrep(string(strjoin(cond_name)),' ','');
                
                
                % assigning id, gr, ses and cnd_name to the matrix
                ods_matrix_export{1+ds,1} = id;
                ods_matrix_export{1+ds,2} = gr;
                ods_matrix_export{1+ds,3} = ses;
                ods_matrix_export{1+ds,4} = cond_name;
                
                % actual computing of averaged data
                
                we_index = 1;
                
                for w = 1 : length(CSV_win_def)
                    
                    start_samp =  round ( (seg.prestim + CSV_win_def{w}{2}/1000 ) * samp_freq) ; %start timepoint for averaging
                    if start_samp == 0; start_samp=1; end
                    end_samp = round ( (seg.prestim + CSV_win_def{w}{3}/1000 ) * samp_freq ) ; %end timepoint for averaging
                    
                    for e = 1 : length(CSV_ele_def)
                        
                        ch_ind = []; %indexes of raws for given channels are kept here. They are subsequently used to specify for which row averaging should be applied
                        
                        for el = 1: length( CSV_ele_def{e} )
                            
                            i_ch = [];
                            i_ch = ismember( dataERP{1, DC}(ds).label, CSV_ele_def{e}{el} ); %marks fittinf elements as 1
                            i_channel = find(i_ch, 1); %finds which elements are equal to 1
                            ch_ind = [ ch_ind i_channel ]; %saves which one are equal 1
                            
                        end
                        
                        ERP_mean = mean( dataERP{1,DC}(ds).avg( ch_ind, start_samp : end_samp), 'all' );
                        
                        % tu wpisać całość
                        ods_matrix_export{ 1+ds , 4+we_index } = ERP_mean;
                        we_index = we_index+1;
                    end
                    
                end
                
            end
            
            writecell(ods_matrix_export, fullfile(exportFolder, exportFileName) , 'Sheet',1, 'WriteMode', 'overwrite'); % saving ods_matrix_export
            display (strcat('Writing individual avareages: ', exportFileName));
            
        end
    end
end


%% SMOTHING %%%

if ~isequal(ERP_smoothing, 0)
    
    disp('smoothed DATA approach');
    % first calculate smoothed data
    for d = 1:length(DATA)
        DATA_sh{1,d} = DATA{1,d};
        DATA_sh{1,d}.avg = movmean(DATA{1,d}.avg, ERP_smoothing, 2);
    end
    
    if strcmp(CSV_save_par, 'avg')
        
        if ~exist('DC_list')
            
            for DC = 1:length(DATA_sh)
                
                exportFolder = fullfile(analysisFolder, '5_EXPORT', NAME{DC});
                
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                
                csvfilename = [ exportFolder '/' NAME{DC} '.csv' ];
                sensorlist = DATA_sh{DC}.label;
                timelist = horzcat ( ['sensor'], num2cell(DATA_sh{DC}.time));
                dataexp = num2cell(DATA_sh{DC}.avg);
                sprtosave = horzcat(sensorlist,dataexp);
                outtable = vertcat (timelist, horzcat(sensorlist,dataexp));
                writecell(outtable, csvfilename);
                clear csvfilename sensorlist timelist dataexp sprtosave outtable
                
            end
            
            disp('CSV export - AVG - option. DC_list doesnt exist. All DC has been saved');
            
        else  %DC_list exists
            
            for DC = DC_list
                
                exportFolder = fullfile(analysisFolder, '5_EXPORT', NAME{DC});      
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                
                clear csvfilename sensorlist timelist dataexp sprtosave outtable
                
            end
            
            disp( [ 'CSV export - AVG - option. Since DC_list exists. DC ' num2str(DC_list) ' has been saved' ] );
        end
    end
    
    
    if 1 %FIXME  strcmp(CSV_save_par, 'all')
        
        if ~exist('DC_list')
            
            clear ods_matrix_export
            
            file_list = '';
            
            %%% filling fixed elements of the table
            ods_matrix_export{1,1} = 'ID';
            ods_matrix_export{1,2} = 'GR';
            ods_matrix_export{1,3} = 'SES';
            ods_matrix_export{1,4} = 'COND';
            
            % filling elements related to widows and channels selection
            we_ind = 1;
            
            for w = 1:length(CSV_win_def)   %windows
                
                for e = 1: length(CSV_ele_def)   %electrodes
                    
                    ch_str = ''; % here string with channel list refered to given condition is kept
                    
                    for ch = 1: length(CSV_ele_def{e})
                        ch_str = [ ch_str , CSV_ele_def{e}{ch} , '+']; %channels from the same conditions are concatenated with '+'
                    end
                    
                    ch_str = ch_str(1:end-1);
                    
                    ods_matrix_export{1,4+we_ind} = [ CSV_win_def{w}{1} , '(' , num2str(CSV_win_def{w}{2}) , '-' , num2str(CSV_win_def{w}{3}) , ').' , ch_str ];
                    we_ind = we_ind + 1;
                    
                end
            end
            
            % calculating mean values
            for DC = 1 : length( DATA_sh )
                
                exportFolder = fullfile (analysisFolder, '5_EXPORT');
                
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                
                for ds = 1 : length( dataERP{1,DC} )
                    
                    % for each ds id, gr, ses and cond_name are being alocated
                    id = '';
                    gr = '';
                    ses = '';
                    cond_name = '';
                    
                    [~, dsname, ~] = fileparts(infile{ DS_LIST{DC}(1,ds) });
                    id=dsname(design.idPosStart:design.idPosEnd);
                    gr=dsname(design.grpPosStart:design.grpPosEnd);
                    ses=dsname(design.sesPosStart:design.sesPosEnd);
                    
                    %COND
                    
                    for c = 1 : condlev    %length(COND.DS{DC})
                        cond_name = [ cond_name COND(c).DS{DC} '-']; %add all instances of each COND to the name
                    end
                    
                    cond_name = cond_name(1 , 1:end-1);
                    cond_name = strrep(string(strjoin(cond_name)),' ','');
                    
                    % assigning id, gr, ses and cnd_name to the matrix
                    ods_matrix_export{1+ds,1} = id;
                    ods_matrix_export{1+ds,2} = gr;
                    ods_matrix_export{1+ds,3} = ses;
                    ods_matrix_export{1+ds,4} = cond_name;
                    
                    %actual computing of averaged data
                    
                    we_index = 1;
                    
                    for w = 1 : length(CSV_win_def)
                        
                        start_samp =  round ( (seg.prestim + CSV_win_def{w}{2}/1000 ) * samp_freq) ; %start timepoint for averaging
                        end_samp = round ( (seg.prestim + CSV_win_def{w}{3}/1000 ) * samp_freq ) ; %end timepoint for averaging
                        
                        for e = 1 : length(CSV_ele_def)
                            
                            ch_ind = []; %indexes of raws for given channels are kept here. They are subsequently used to specify for which row averaging should be applied
                            
                            for el = 1: length( CSV_ele_def{e} )
                                
                                i_ch = [];
                                i_ch = ismember( dataERP{1, DC}(ds).label, CSV_ele_def{e}{el} ); %marks fittinf elements as 1
                                i_channel = find(i_ch, 1); %finds which elements are equal to 1
                                ch_ind = [ ch_ind i_channel ]; %saves which one are equal 1
                                
                            end
                            
                            ERP_mean = mean( dataERP{1,DC}(ds).avg( ch_ind, start_samp : end_samp), 'all' );
                            
                            ods_matrix_export{ 1+ds , 4+we_index } = ERP_mean;
                            we_index = we_index+1;
                            
                        end
                    end
                end
                
                writecell(ods_matrix_export, [exportFolder '/' 'CSV_averages.xls'] , 'Sheet',1); % saving ods_matrix_export
                
            end
            
        else   %DC_list exists
            
            clear ods_matrix_export
            file_list = '';
            
            %%% filling fixed elements of the table
            ods_matrix_export{1,1} = 'ID';
            ods_matrix_export{1,2} = 'GR';
            ods_matrix_export{1,3} = 'SES';
            ods_matrix_export{1,4} = 'COND';
            
            % filling elements related to widows and channels selection
            we_ind = 1;
            
            for w = 1:length(CSV_win_def)
                
                for e = 1: length(CSV_ele_def)
                    
                    ch_str = ''; % here string with channel list refered to given condition is kept
                    
                    for ch = 1: length(CSV_ele_def{e})
                        ch_str = [ ch_str , CSV_ele_def{e}{ch} , '+']; %channels from the same conditions are concatenated with '+'
                    end
                    
                    ch_str = ch_str(1:end-1);
                    
                    
                    if add_ms_window
                        ods_matrix_export{1,4+we_ind} = [ CSV_win_def{w}{1} , '(' , num2str(CSV_win_def{w}{2}) , '-' , num2str(CSV_win_def{w}{3}) , ').' , ch_str ];
                    else
                        ods_matrix_export{1,4+we_ind} = [ CSV_win_def{w}{1} '.' , ch_str ];
                    end
                    we_ind = we_ind + 1;
                    
                end
            end
            
            % calculating mean values
            for DC = DC_list %loop over grandAveraged data
                ods_matrix_export=ods_matrix_export(1,:); %clean export matrix except the header line
                
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
                exportFileName = [NAME{DC} '.xls'];
                
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                
                %                 SaveAvgFile( [exportFolder '/' NAME{DC} '.at' ], DATA_sh{DC}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                
                for ds = 1 : length( dataERP{1,DC} ) %loop over individual ds
                    
                    % for each ds id, gr, ses and cond_name are being alocated
                    
                    cond_name = '';
                    
                    [~, dsname, ~] = fileparts(infile{ DS_LIST{DC}(1,ds) });
                    id = dsname(design.idPosStart : design.idPosEnd);
                    gr = dsname(design.grpPosStart : design.grpPosEnd);
                    
                    if design.sesPosStart & design.sesPosEnd
                        ses = dsname(design.sesPosStart : design.sesPosEnd);
                    else
                        ses = '';
                    end
                    
                    %COND
                    for c = 1 : condlev
                        cond_name = [ cond_name COND(c).DS{DC} '-']; %add all instances of each COND to the name
                    end
                    cond_name = cond_name(1 , 1:end-1);
                    cond_name = strrep(string(strjoin(cond_name)),' ','');
                    
                    % assigning id, gr, ses and cnd_name to the matrix
                    ods_matrix_export{1+ds,1} = id;
                    ods_matrix_export{1+ds,2} = gr;
                    ods_matrix_export{1+ds,3} = ses;
                    ods_matrix_export{1+ds,4} = cond_name;
                    
                    %actual computing of averaged data
                    
                    we_index = 1;
                    
                    for w = 1 : length(CSV_win_def)  %windows
                        
                        start_samp =  round ( (seg.prestim + CSV_win_def{w}{2}/1000 ) * samp_freq) ; %start timepoint for averaging
                        if start_samp == 0; start_samp=1; end
                        end_samp = round ( (seg.prestim + CSV_win_def{w}{3}/1000 ) * samp_freq ) ; %end timepoint for averaging
                        
                        for e = 1 : length(CSV_ele_def)   %electrodes
                            
                            ch_ind = []; %indexes of raws for given channels are kept here. They are subsequently used to specify for which row averaging should be applied
                            
                            for el = 1: length( CSV_ele_def{e} )
                                
                                i_ch = [];
                                i_ch = ismember( dataERP{1, DC}(ds).label, CSV_ele_def{e}{el} ); %marks fittinf elements as 1
                                i_channel = find(i_ch, 1); %finds which elements are equal to 1
                                ch_ind = [ ch_ind i_channel ]; %saves which one are equal 1
                                
                            end
                            
                            ERP_mean = mean( dataERP{1,DC}(ds).avg( ch_ind, start_samp : end_samp), 'all' );
                            
                            % tu wpisać całość
                            ods_matrix_export{ 1+ds , 4+we_index } = ERP_mean;
                            we_index = we_index+1;
                        end
                    end
                end
                
                writecell(ods_matrix_export, fullfile(exportFolder, exportFileName) , 'Sheet',1, 'WriteMode', 'overwrite'); % saving ods_matrix_export
                display (strcat('Writing individual avareages: ', exportFileName));
                
            end
        end
    end
    
    
end
