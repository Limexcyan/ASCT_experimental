function sc_clientSaveHandler(payload)
    % Tis function allows for Client and not parallel saving of
    % information via payload type. 

    % This funciton is specifically for SAVING information - TBD -
    % Graphical information 
    switch payload.type
        case 'ICA1_decomp'
            disp( strcat( 'ICA1 decomp: Saving DS ', payload.dsname) );
            payload.data = sc_4_DECOMPOSITION_ICA1_class_viz(payload.data, payload.chan, payload.rc, payload.ica);
            
            filename = payload.file_name;
            decomp_ica1 = payload.data;
            if ~exist(payload.saveFolder, 'dir'); mkdir(payload.saveFolder); end     % Ensure folder exists

            % Save data (MATLAB client now does it!)
            save(filename, 'decomp_ica1', '-v7.3');  % Or whatever variables are needed
        case 'ICA1_ar'
            disp(strcat( '[', num2str( round(payload.ds/payload.infileLen*100)), '%] Saving post-ICA1 ARTIFREE data: ', payload.dsname, ' (DS ', num2str(payload.ds), ')'));

            filename = payload.file_name;
            data_ica1 = payload.data;
            if ~exist(payload.saveFolder, 'dir'); mkdir(payload.saveFolder); end     % Ensure folder exists
            
            % Save data (MATLAB client now does it!)
            save(filename, 'data_ica1', '-v7.3');  % Or whatever variables are needed
        case 'ICA2'

            disp( [ 'Saving ICA2 decomposed data; DS: ', num2str(payload.ds), ' - ', payload.dsname] );

            file_name = fullfile(payload.saveFolder, strcat(payload.dsname, '_ica2.mat'));
            sc_parsave_data_ica2(file_name, payload.data);
            return;

        otherwise
            warning('Unknown payload type received.');
            return;
    end
end