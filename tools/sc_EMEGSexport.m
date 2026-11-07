% This function allows export to EMEGS.
% It exports either grandAveraged data or both grandAveraged and all DataSets.
% If all ds are exported an additional list with emegs ds paths is created.

EMEGS_save_par = 'all'; % 'all'  or 'avg'

if ~exist('samp_freq')
    
    if exist('data_all_artf')
        samp_freq = data_all_artf(1).fsample;
    else
        str_to_displ = ['There is no samp_freq specified.' , sprintf('\n')  'There is no data_all_artf variable from which it can be read, either.', sprintf('\n'), 'Please either load data_all_artf or provide samp_freq manualy.'];
        warning(str_to_displ);
    end
end


%% NO SMOTHING %%%


if isequal(ERP_smoothing, 0)
    
    disp('classical DATA approach');
    
    if strcmp(EMEGS_save_par, 'avg')

        if ~exist('vis_DC_list')
            for DC = 1:length(DATA)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                SaveAvgFile( [exportFolder '/' NAME{DC} '.at' ], DATA{DC}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
            end

            disp('EMEGS export - AVG - option. Vis_DC_list doesnt exist. All DC has been saved');

        else

            for DC = 1:length(vis_DC_list)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{vis_DC_list(DC)}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                SaveAvgFile( [exportFolder '/' NAME{vis_DC_list(DC)} '.at' ], DATA{vis_DC_list(DC)}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
            end
            disp( [ 'EMEGS export - AVG - option. Since vis_DC_list exists. DC ' num2str(vis_DC_list) ' has been saved' ] );
        end
    end


    if strcmp(EMEGS_save_par, 'all')

        if ~exist('vis_DC_list')

            file_list = '';

            for DC = 1:length(DATA)

                exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                SaveAvgFile( [exportFolder '/' NAME{DC} '.at' ], DATA{DC}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension

                for ds = 1:length(dataERP{1,DC})

                    ds_file_name = [ 'ds' num2str(DS_LIST{DC}(1,ds)) ]; %names each ds separately
                    [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{ DS_LIST{DC}(1,ds)} );
                    SaveAvgFile([exportFolder '/' dsname '.at'], dataERP{1,DC}(ds).avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                    file_list = [file_list [exportFolder '/' dsname '.at'] newline]
                end

            end

            file_name = [analysisFolder '/5_EXPORT/' NAME{DC} '.txt'];
            fid = fopen( file_name, 'w' );
            fprintf( fid, '%s', file_list );
            fclose(fid);

        else

            file_list = '';

            for DC = 1:length(vis_DC_list)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{vis_DC_list(DC)}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end

                SaveAvgFile( [exportFolder '/' NAME{vis_DC_list(DC)} '.at' ], DATA{vis_DC_list(DC)}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension

                for ds = 1 : length(dataERP{1,vis_DC_list(DC)})

                    ds_file_name = [ 'ds' num2str(DS_LIST{vis_DC_list(DC)}(ds)) ]; %names each ds separately
                    [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{ DS_LIST{vis_DC_list(DC)}(ds)} );
                    SaveAvgFile([exportFolder '/' dsname '.at'], dataERP{1,vis_DC_list(DC)}(ds).avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                    file_list = [file_list [exportFolder '/' dsname '.at'] newline]
                end
            end

            file_name = [analysisFolder '/5_EXPORT/' NAME{vis_DC_list(DC)} '.txt'];
            fid = fopen( file_name, 'w' );
            fprintf( fid, '%s', file_list );
            fclose(fid);
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
    
    % run the procedure the same mane as before but substitue DATA_sh instead of DATA
    if strcmp(EMEGS_save_par, 'avg')

        if ~exist('vis_DC_list')
            for DC = 1:length(DATA_sh)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                SaveAvgFile( [exportFolder '/' NAME{DC} '.at' ], DATA_sh{DC}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
            end
            disp('EMEGS export - AVG - option. Vis_DC_list doesnt exist. All DC has been saved');
        else

            for DC = 1:length(vis_DC_list)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{vis_DC_list(DC)}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                SaveAvgFile( [exportFolder '/' NAME{vis_DC_list(DC)} '.at' ], DATA_sh{vis_DC_list(DC)}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
            end
            disp( [ 'EMEGS export - AVG - option. Since vis_DC_list exists. DC ' num2str(vis_DC_list) ' has been saved' ] );
        end
    end

    if strcmp(EMEGS_save_par, 'all')

        if ~exist('vis_DC_list')

            file_list = '';

            for DC = 1:length(DATA_sh)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{DC}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
                SaveAvgFile( [exportFolder '/' NAME{DC} '.at' ], DATA_sh{DC}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                for ds = 1:length(dataERP{1,DC})
                    ds_file_name = [ 'ds' num2str(DS_LIST{DC}(1,ds)) ]; %names each ds separately
                    [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{ DS_LIST{DC}(1,ds)} );
                    SaveAvgFile([exportFolder '/' dsname '.at'], dataERP{1,DC}(ds).avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                    file_list = [file_list [exportFolder '/' dsname '.at'] newline]
                end
            end
            file_name = [analysisFolder '/5_EXPORT/' NAME{DC} '.txt'];
            fid = fopen( file_name, 'w' );
            fprintf( fid, '%s', file_list );
            fclose(fid);

        else

            file_list = '';

            for DC = 1:length(vis_DC_list)
                exportFolder = [analysisFolder '/5_EXPORT/' NAME{vis_DC_list(DC)}];
                if ~exist(exportFolder)
                    mkdir(exportFolder);
                end
    
                SaveAvgFile( [exportFolder '/' NAME{vis_DC_list(DC)} '.at' ], DATA_sh{vis_DC_list(DC)}.avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                for ds = 1 : length(dataERP{1,vis_DC_list(DC)})
                    ds_file_name = [ 'ds' num2str(DS_LIST{vis_DC_list(DC)}(ds)) ]; %names each ds separately
                    [tmpinpathname, dsname, tmpinfileext] = fileparts( infile{ DS_LIST{vis_DC_list(DC)}(ds)} );
                    SaveAvgFile([exportFolder '/' dsname '.at'], dataERP{1,vis_DC_list(DC)}(ds).avg, 1, [], samp_freq, [], [], [], [], round(seg.prestim*samp_freq)+1); %saves each ds with emegs extension
                    file_list = [file_list [exportFolder '/' dsname '.at'] newline]
                end

            end

            file_name = [analysisFolder '/5_EXPORT/' NAME{vis_DC_list(DC)} '.txt'];
            fid = fopen( file_name, 'w' );
            fprintf( fid, '%s', file_list );
            fclose(fid);

        end

    end    
    
end
    
    

