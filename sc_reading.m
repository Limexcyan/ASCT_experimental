% The sc_reading function provides a tool to create a list of files with specified extension
% dataFolder - spcifies the absolute path of the folder where data of interest is located
% end_pattern - specifies extension of files or the end of directory name
% varargin{1} - if exists, specifies whether file or folders are searched for

function infile = sc_reading(dataFolder_reading, end_pattern, varargin)

if length(varargin) == 0 || strcmp (varargin{1}, 'file')

    % Check to make sure that folder actually exists.
    if ~isfolder(dataFolder_reading)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s\nPlease specify a new one.', dataFolder_reading);
        uiwait(warndlg(errorMessage));
        dataFolder_reading = uigetdir(); % Ask for a new one.
        return;
    end

    % Get a list of all files in the folder with the desired extension
    filePattern = fullfile(dataFolder_reading, end_pattern); % Specify extension of the file
    theFiles = dir(filePattern);

    for k = 1 : length(theFiles)
        baseFileName = theFiles(k).name;
        fullFileName = fullfile(dataFolder_reading, baseFileName);
        infile{k} = fullFileName; % I don't know why it should be {} but it is fantastic that it works ;)
    end


end

if ~isempty(varargin)
    if strcmp(varargin{1}, 'dir')
        % cd (dataFolder_reading)
        %  flist=dir('*/*.*');
        % 
        %  j = 0; infile = [];
        %  for i = 1:length(flist)
        %      if flist(i).isdir && endsWith(flist(i).name, end_pattern)
        %          j = j+1;
        %          infile{j} = fullfile(flist(i).folder, flist(i).name);
        %      end
        %  end

        cd (dataFolder_reading)
         flist=dir(dataFolder_reading);

         j = 0; infile = [];
         for i = 1:length(flist)
             if flist(i).isdir && endsWith(flist(i).name, end_pattern)
                 j = j+1;
                 infile{j} = fullfile(flist(i).folder, flist(i).name);
             end
         end


        % Get matching directories (non-recursive)
        % searchPath = fullfile(dataFolder_reading, end_pattern);
        % dirInfo = dir(searchPath);
        % 
        % % Keep only directories
        % dirInfo = dirInfo([dirInfo.isdir]);
        % 
        % % Handle empty result
        % if isempty(dirInfo)
        %     fprintf('No directories matching "%s" found in %s\n', pattern, rootPath);
        %     dirTable = table();
        %     return;
        % end
        % 
        % % Extract names and folders
        % names = {dirInfo.name}';
        % folders = {dirInfo.folder}';
        % 
        % % Create table
        % dirTable = table(names, folders, 'VariableNames', {'Name', 'Folder'});


    else
        error('Unknown option for file/folder search');
    end
end

if ~exist('infile'); error('!!!!!!!!!!!  No data files found'); end

infile = infile'; % just for easier reading
infile = cellstr(infile);
end