

% 0 - raw
% 1 - preproc
% 2 - segm
% 3 - arj
% 4 - ICA1
% 5 - ICA1 arj
% 6 - ICA2


rawExt = rc.dataFormat;
rawExt = strrep(rawExt, 'eeglab', 'set');
analysisFolder = fullfile(rc.expFolder, rc.analysisName);

folder0 = fullfile (rc.expFolder, rc.dataRawFolder);
folder1 = fullfile (analysisFolder, '1_PREPROCESSED' );
folder2 = fullfile (analysisFolder, '2_SEGMENTED' );
folder3 = fullfile (analysisFolder, '3_ARTIFREE' );
folder4 = fullfile (analysisFolder, '4_ICA1' );
folder5 = fullfile (analysisFolder, '5_ICA1_AR' );
folder6 = fullfile (analysisFolder, '6_ICA2' );

infile0 = sc_reading(folder0, strcat('*.', rawExt));
infile1 = sc_reading(folder1, '*PREP.mat');
infile2 = sc_reading(folder2, '*SEGM.mat');
infile3 = sc_reading(folder3, '*ARJ.mat');
infile4 = sc_reading(folder4, '*ICA1_decomp.mat');
infile5 = sc_reading(folder5, '*ICA1_arj.mat');
infile6 = sc_reading(folder6, '*ica2.mat');

infile1 = strrep(infile1, '_PREP', '');
infile2 = strrep(infile2, '_SEGM', '');
infile3 = strrep(infile3, '_ARJ', '');
infile4 = strrep(infile4, '_ICA1_decomp', '');
infile5 = strrep(infile5, '_ICA1_arj', '');
infile6 = strrep(infile6, '_ica2', '');



txt = [' RAW: ' num2str(length(infile0)) newline  'PREP: ' num2str(length(infile1)) newline 'SEGM: ' num2str(length(infile2)) newline ' ARJ: ' num2str(length(infile3)) newline 'ICA1: ' num2str(length(infile4)) newline 'ICAR: ' num2str(length(infile5)) newline 'ICA2: ' num2str(length(infile6))];
disp (txt);

%antb = zeros(7, length(infile0));

clear antb

for i = 1:length(infile0)
    for j = 1:6
        antb{i,j}=0;
    end
end

for i = 1:length(infile0)
    [~, dsname, ~] = fileparts (infile0(i));
    antb{i,7} = dsname;
end

for i = 1:length(infile0)
        [~, dsname0, ~] = fileparts (infile0(i));
    for j = 1:length(infile1)
        [~, dsname1, ~] = fileparts (infile1(j));
        if strcmp(dsname0, dsname1)
            antb{i,1} = 1;
            break;
        end
    end
end

for i = 1:length(infile0)
        [~, dsname0, ~] = fileparts (infile0(i));
    for j = 1:length(infile2)
        [~, dsname2, ~] = fileparts (infile2(j));
        if strcmp(dsname0, dsname2)
            antb{i,2} = 1;
            break;
        end
    end
end

for i = 1:length(infile0)
        [~, dsname0, ~] = fileparts (infile0(i));
    for j = 1:length(infile3)
        [~, dsname3, ~] = fileparts (infile3(j));
        if strcmp(dsname0, dsname3)
            antb{i,3} = 1;
            break;
        end
    end
end

for i = 1:length(infile0)
        [~, dsname0, ~] = fileparts (infile0(i));
    for j = 1:length(infile4)
        [~, dsname4, ~] = fileparts (infile4(j));
        if strcmp(dsname0, dsname4)
            antb{i,4} = 1;
            break;
        end
    end
end

for i = 1:length(infile0)
        [~, dsname0, ~] = fileparts (infile0(i));
    for j = 1:length(infile5)
        [~, dsname5, ~] = fileparts (infile5(j));
        if strcmp(dsname0, dsname5)
            antb{i,5} = 1;
            break;
        end
    end
end


for i = 1:length(infile0)
        [~, dsname0, ~] = fileparts (infile0(i));
    for j = 1:length(infile6)
        [~, dsname6, ~] = fileparts (infile6(j));
        if strcmp(dsname0, dsname6)
            antb{i,6} = 1;
            break;
        end
    end
end