% check whether all files are preprocessed


prepfiles = 0;
segmfiles = 0;
nartfiles = 0;


for f = 1:length(infile)
    
    [filepth,filenme,fileex] = fileparts(infile{f});
    
    if exist([analysisFolder '/1_PREPROCESSED/' filenme '_PREP.mat']) == 2
        prepfiles = prepfiles+1;
    else
        fstr = num2str(f);
        disp([fstr ': /1_PREPROCESSED/' filenme '_PREP.mat']);
    end
    
    
end


for f = 1:length(infile)
    
    [filepth,filenme,fileex] = fileparts(infile{f});
    
    if exist([analysisFolder '/2_SEGMENTED/' filenme '_SEGM.mat']) == 2
        prepfiles = prepfiles+1;
    else
        fstr = num2str(f);
        disp([fstr ': /2_SEGMENTED/' filenme '_SEGM.mat']);
        
    end
    
    
end

for f = 1:length(infile)
    
    [filepth,filenme,fileex] = fileparts(infile{f});
    
    if exist([analysisFolder '3/_NO_ARTIFACT/' filenme '_NO_ARTIF.mat']) == 2
        prepfiles = prepfiles+1;
    else
        fstr = num2str(f);
        disp([fstr ': 3/_NO_ARTIFACT/' filenme '_NO_ARTIF.mat']);
        
    end
    
end

clear fstr prepfiles segmfiles nartfiles f filepth filenme fileex

