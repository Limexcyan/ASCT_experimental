%%%%%%%% TRIG. DEF. AND SEGMENTATION %%%%%%%

% This function segments continous data into epochs.
% Triggers of interest should be specified in 'EX_SETUP.m' script in 'design' section.
% It supports optional recoding of triggers.
% If recoding of triggers is needed 'sc_recoddingFn' script should be provided
% and saved in experiment folder with an original name.
% It's name is passed along as a 'recod_fun_to_call' parameter to this function.
% for more info chek 'sc_recodding_TEMPLATE.m'
% Parameters such as prestim, poststim and baseline should be specified in EX_SETUP, accordingly to experimental disgign.

%% loading data

clear data_all_prep data_all_prep_eogcorr data_segm data_all_segm data_all_segm_eogcorr infileses

loadFolder = fullfile(rc.analysisFolder, '/1_PREPROCESSED');

% reading 'infile' file
if exist(loadFolder)

    switch rc.dataFormat
        case {'bdf', 'eeglab', 'ctf'}
            infile_all = sc_reading(loadFolder, '*PREP.mat');
            infile = infile_all;
            if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
                infile_all_eogcorr = sc_reading(loadFolder, '*PREP_EOGcorr.mat');
                infile_eogcorr = infile_all_eogcorr;
            else
                infile_all_eogcorr = infile;
                infile_eogcorr = infile_all_eogcorr;
            end
        case {'itab-sim', 'syn-sim', 'itab'}
            infile_all = sc_reading(loadFolder, '*PREP.mat');
            infile = infile_all;
            infile_eogcorr = infile; % fix for feeding parloop with non-existing var, even if not used
        otherwise
            error('!!! rc.dataFormat not supported or uncorrectly set');
    end
else
    error( ['There is no infile file in the /1_PREPROCESSED folder.' , newline, 'Most likely preprocessed data havent been saved'] );
end


if design.concatSes     % ses merge. adjust beg/end id
    [~,filelast,~] = fileparts(infile{length(infile)});
    missingses = design.concatSes - str2num(filelast(design.sesPosStart:design.sesPosEnd));  % how many sessions to add to have all
end

if design.concatSes     % ses merge. adjust beg/end id
    i2 = 1; infile01 = {};
    for i = 1:length(infile)
        [~,filenm,~] = fileparts(infile{i});
        if str2num(filenm(design.sesPosStart:design.sesPosEnd)) == 1  % only leave entries that point at the first session
            infile01{i2} = infile{i};
            i2 = i2+1;
        end
    end
    infile = infile01';
    clear infile01
end


% reading preprocessed data + eventually defining 'begId' and 'endId' variables

if exist('begId') && exist('endId')
    infile = infile(begId : endId);
    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG))
        infile_eogcorr = infile_all_eogcorr(begId : endId);
    end
end

parfor ds =  1 : length(infile)
    if isempty(infile{ds})
        error(['There is no data in infile(',num2str(ds),').' ] );
    else
        disp(strcat(' [', num2str( round( 100 * ds / length(infile) ) ), '%] Loading DS', num2str(ds), ' - ', infile{ds}, ' file - prep data') );
        datatmp = load(infile{ds});
        data_all_prep(ds) = datatmp.data_prep;
    end
end

if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
    parfor ds =  1 : length(infile_eogcorr)
        if isempty(infile_eogcorr{ds})
            error(['There is no data in infile(',num2str(ds),').'] );
        else
            disp([' [' num2str( round( 100 * ds / length(infile_eogcorr) ) ) '%] Loading DS', num2str(ds), ' - ', infile_eogcorr{ds}, ' file - prep data'] );
            datatmp = load(infile_eogcorr{ds});
            data_all_prep_eogcorr(ds) = datatmp.data_prep;
        end
    end
end



% concatenate data if needed
if design.concatSes
    infileses = {};
    sesnamelen = design.sesPosEnd - design.sesPosStart + 1;
    for ses = 2:design.concatSes       
        sesname = num2str(ses);
        for l = 2:sesnamelen; sesname = ['0', sesname]; end  % add trailing zeros
        sesname = strcat(sesname, '_PREP');
        infileses = horzcat(infileses, [strrep(infile, '01_PREP', sesname)]);   % fixme - here only two0digit sess is supported
    end

    for ds =  1 : size(infileses,1)
        parfor ses = 1 : size(infileses,2)
            if isempty(infileses{ds, ses})
                error(['There is no data in infile(',num2str(ds),').' ] );
            else
                disp(strcat(' [', num2str( round( 100 * ds / length(infileses) ) ), '%] Loading DS', num2str(ds), ' - ', infileses{ds, ses}, ' next runs - prep data') );
                datatmp = load(infileses{ds, ses});
                data_all_prep_ses{ds, ses} = datatmp.data_prep;
            end
        end
    end

end

%% CONSISTENCY CHECK %%%

if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
    if length(data_all_prep) ~= length(data_all_prep_eogcorr); error('CONSISTENCY CHECK FAILED: size of PREP data not equal to PREP_EOGcorr data. ABORTING.'); end
    for i = 1;length(data_all_prep)
        if ~strcmp(data_all_prep(i).hdr.dsname, data_all_prep_eogcorr(i).hdr.dsname); error('CONSISTENCY CHECK FAILED: ds names do not match between PREP and PREP_EOGcorr data. ABORTING.'); end
    end
end


%% SEGMENTATION %%%

% RELEVANT TRIGGER LIST

seg.final_trig_list = {};
for i = 1:length( design.COND )
    for j = 1 : length( design.COND(i).trig )
        for k = 1 : length( design.COND(i).trig{1,j} )
            seg.final_trig_list = [ seg.final_trig_list design.COND(i).trig{1,j}{1,k} ];
        end
    end
end
if ~ischar(seg.final_trig_list{1})  % triggers are numeric
    % if  ~ ( strcmp(rc.dataFormat, 'ctf') || strcmp(event_type, 'Stimulus') )  % neither ctf format nor BVA triggers. they are both in text format
    seg.final_trig_list = cell2mat (num2cell( unique( cell2mat(seg.final_trig_list) ) ) );
end

clear j k

% segmentation

infile_trg = [];

for ds = 1 : length(infile)   % routine segmentation
    disp(newline);

    disp( [ '[' num2str( round( 100 * ds / length(infile) ) ) '%] Ds: ', num2str(ds) ' is being segmented' ]);    disp(newline);

    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
        [data_all_segm(ds), data_all_segm_eogcorr(ds)] = sc_segment(infile{ds}, data_all_prep(ds), data_all_prep_eogcorr(ds), rc, chan, filter, seg);
    else
        [data_all_segm(ds), ~] = sc_segment(infile{ds}, data_all_prep(ds), [], rc, chan, filter, seg);
    end
end

if design.concatSes
    for ds =  1 : size(infileses,1)
        for ses = 1 : size(infileses,2)
            disp(newline);
            disp( [ '[' num2str( round( 100 * ds / length(infileses) ) ) '%] Ds: ', num2str(ds) ' is being segmented (session ', num2str(ses+1), ')' ]); disp(newline);

            if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
                [data_all_segm_ses{ds, ses}, data_all_segm_ses_eogcorr{ds, ses}] = sc_segment(infileses{ds, ses}, data_all_prep_ses{ds, ses}, data_all_prep_ses_eogcorr(ds, ses), rc, chan, filter, seg);
            else
                [data_all_segm_ses{ds, ses}, ~] = sc_segment(infileses{ds, ses}, data_all_prep_ses{ds, ses}, [], rc, chan, filter, seg);
            end
        end
    end

    cfg = [];  cfg.keepsampleinfo='no' ;

    for ds =  1 : size(infileses,1)
        dd = data_all_segm(ds);
        dd2 = dd;
        for ses = 1 : size(infileses,2)
            dd = ft_appenddata(cfg, dd, data_all_segm_ses{ds, ses});
        end
        for tri = 1:length(dd.trialinfo); dd.trialinfo(tri,2)=tri; end  % correct trialinfo column
        dd.hdr = dd2.hdr;
        if ~isfield(dd, 'grad') && isfield(dd2, 'grad'); dd.grad = dd2.grad; end
        if ~isfield(dd, 'elec') && isfield(dd2, 'elec'); dd.elec = dd2.elec; end
        dd.hdr.dsname = dd.hdr.dsname(1:length(dd.hdr.dsname)+(design.sesPosStart-design.sesPosEnd-2)); % cut right strings containing session id
        data_all_segm_cnt(ds) = dd;
    end


    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg  % concatenate eog
        dd = data_all_segm_eogcorr(ds);
        for ses = 1 : size(infileses,1)
            dd = ft_appenddata(cfg, dd, data_all_segm_ses{ses, ds});
        end
        data_all_segm_cnt(ds) = dd;
    end

    data_all_segm = data_all_segm_cnt;

end


clear data_all_prep data_all_prep_eogcorr


%% SAVE %%

saveFolder = fullfile(rc.analysisFolder, '2_SEGMENTED');

if ~exist(saveFolder); mkdir(saveFolder); end

file_name = fullfile(saveFolder, '_SEGM_param.mat');
save(file_name, 'seg' );
file_name = fullfile(saveFolder, '_SEGM_infile.mat');
save(file_name, 'infile');


for ds = 1 : length(infile)
    [~, dsname, ~] = fileparts( infile{ds} ); % extract file path, data set name, and extension
    if ~design.concatSes
        dsname = replace(dsname, '_PREP', '');
    else
        dsname = replace(dsname, '_01_PREP', '');
    end
    file_name = fullfile(saveFolder, strcat(dsname, '_SEGM.mat'));
    file_name_eogcorr = replace (file_name, '_SEGM.mat', '_SEGM_EOGcorr.mat');
    disp( strcat( '[', num2str(round( 100 * ds / length(infile) ) ) , '%] Saving SEGM DS: ', num2str(ds), ' - ', dsname) );

    data_segm = data_all_segm(ds);

    if rc.saveCompress
        save(file_name, 'data_segm', '-v7.3');
    else
        save(file_name, 'data_segm', '-nocompression', '-v7.3');
    end

    if (~isempty(chan.eog) || ~isempty(chan.addMockEOG)) && rc.eeg
        data_segm_eogcorr = data_all_segm_eogcorr(ds);
        if rc.saveCompress
            save(file_name_eogcorr, 'data_segm_eogcorr', '-v7.3');
        else
            save(file_name_eogcorr, 'data_segm_eogcorr', '-nocompression', '-v7.3');
        end
    end
end

