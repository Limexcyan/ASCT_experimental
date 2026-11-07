function export_nii_to_itab_asc(nii_filename, asc_filename, isovalue)
    % 1. Carica il file NIfTI
    data = niftiread(nii_filename);
    
    % Se non specificato, calcola una soglia empirica per lo scalpo
    if nargin < 3
        isovalue = mean(data(:)) + std(double(data(:))); 
    end
    
    % 2. Genera l'isosuperficie (FV: Faces & Vertices)
    fv = isosurface(data, isovalue);
    
    % Opzionale: riduci le facce per alleggerire la triangolazione (es. max 20.000 vertici)
    if size(fv.vertices, 1) > 20000
        fv = reducepatch(fv, 20000 / size(fv.vertices, 1));
    end
    
    vertices = fv.vertices;
    faces = fv.faces;
    
    % 3. Scrittura del file .asc
    fileID = fopen(asc_filename, 'w');
    if fileID == -1
        error('Impossibile aprire il file in scrittura.');
    end
    
    num_v = size(vertices, 1);
    num_f = size(faces, 1);
    
    % Intestazione
    fprintf(fileID, '# Created for ITAB / ASCT pipeline\n');
    fprintf(fileID, '%d %d\n', num_v, num_f);
    
    % Scrittura Vertici: X Y Z 0
    for i = 1:num_v
        fprintf(fileID, '%.4f %.4f %.4f 0\n', vertices(i,1), vertices(i,2), vertices(i,3));
    end
    
    % Scrittura Facce (Convertiti a indici 0-based sottrando 1)
    for j = 1:num_f
        fprintf(fileID, '%d %d %d 0\n', faces(j,1)-1, faces(j,2)-1, faces(j,3)-1);
    end
    
    fclose(fileID);
    fprintf('asc file %s is succesfully generated! (%d vertices, %d polygons)\n', asc_filename, num_v, num_f);
end
