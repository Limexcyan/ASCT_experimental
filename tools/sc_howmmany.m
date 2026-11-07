loadFolder='/mnt/iSCSI2/Exp/TMS_PFC/erp/TMS2/3_ARTIFREE';
infile_all = sc_reading(loadFolder, '*ARJ.mat');
    infile = infile_all;
    
    tr=zeros(length(infile),1);
    
    for f = 1:length(infile)
       disp(f);
        load(infile{f});
       tr(f) = length(data_artf.trial);
       
    end
    
    disp('AV NO OF TRIALS');
    disp(mean(tr));
        disp('SD');
    disp(std(tr));