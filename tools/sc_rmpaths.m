function sc_rmpaths(search_string)
% RMPATH_CONTAINING Remove all paths containing a specific string
%   sc_rmpaths('spm12') removes all paths that contain 'spm12' anywhere
%   in the path string
%
%   Examples:
%       sc_rmpaths('spm12')     % Remove all SPM12 paths
%       sc_rmpaths('toolbox')   % Remove all toolbox paths
%       sc_rmpaths('\@')        % Remove all class directories

% Get all paths
all_paths = strsplit(path, pathsep);

% Find paths that contain the search string (case-sensitive by default)
matching_mask = contains(all_paths, search_string);
matching_paths = all_paths(matching_mask);

% Remove them
if ~isempty(matching_paths)
    % Use try-catch to handle any permission issues
    try
        rmpath(matching_paths{:});
        fprintf('Removed %d path(s) containing: "%s"\n', ...
                length(matching_paths), search_string);

        % Show what was removed (first few for brevity)
        if length(matching_paths) <= 10
            disp(matching_paths);
        else
            fprintf('First 5 removed paths:\n');
            disp(matching_paths(1:5));
            fprintf('... and %d more\n', length(matching_paths)-5);
        end
    catch ME
        fprintf('Error removing paths: %s\n', ME.message);
    end
else
    fprintf('No paths found containing: "%s"\n', search_string);
end
end



%function sc_rmpaths(start_dir)
% RMPATH_STARTINGWITH Remove all paths starting with a specific directory
%   sc_rmpaths('/some/directory') removes all paths that begin with
%   '/some/directory' from the MATLAB search path

% Get all paths
%all_paths = strsplit(path, pathsep);

% Find paths that start with the target directory
%matching_paths = all_paths(startsWith(all_paths, start_dir));

% Remove them
%if ~isempty(matching_paths)
%    rmpath(matching_paths{:});
%    fprintf('Removed %d path(s) starting with:\n%s\n', ...
%            length(matching_paths), start_dir);
%else
%    fprintf('No paths found starting with:\n%s\n', start_dir);
%end
%end
