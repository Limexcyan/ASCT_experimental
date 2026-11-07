%%
%--- PARAMETERS ----%
clear id2stat id2stat1 id2stat2 data2stat

if ~strcmp(class(con.useRange), 'logical')  %fix for multar to get logic value not a number
    if con.useRange==0
        con.useRange=false;
    else
        con.useRange=true;
    end
end

multarFolder_unc = fullfile (rc.analysisFolder, '8_CONN',con.conName,'unc');
multarFolder_lc = fullfile (rc.analysisFolder, '8_CONN',con.conName, 'lc');


set(groot,'defaultfigureposition',[4440 1230 2300 1500])

if ~strcmp(con.chanSel,'1-')

    temp_new_ROI =[];
    splits = split(con.chanSel,',');
    if length(splits) == 1
        splits = split(splits,'-');
        ourROIs = [];
        for splt = 1:length(splits)
            ourROIs =[ourROIs str2num(splits{splt})];
        end
        loc.ROI = loc.ROI(ourROIs(1):ourROIs(2));
    else
        ourROIs = [];
        for splt = 1:length(splits)
            ourROIs =[ourROIs str2num(splits{splt})];
        end
        loc.ROI = loc.ROI(ourROIs);
    end

end

conditions = design.COND.name; %if DC is not present use classic COND
cond_cell = {};

if con.unc
    if con.lc 
        multars = {multarFolder_unc, multarFolder_lc};
    else
        multars = {multarFolder_unc};
    end
else
    multars = {multarFolder_lc};
end


for curr_multarFolder = multars

    dc2compare = design.DC([con.contrast2test_curr(1),con.contrast2test_curr(2)]);

    %     analysisConditions = {strcat(design.DC(contrastno1).COND{:}),strcat(design.DC(contrastno2).COND{:})};

    anacond1 = design.DC( con.contrast2test_curr(1) ).COND ;
    anacond2 = design.DC( con.contrast2test_curr(2) ).COND ;

    analysisConditions = {[anacond1{:}], [anacond2{:}]};

    if isfield(design.DC, 'SES')
        if  isempty(design.DC( con.contrast2test_curr(1) ).SES) || isempty(design.DC( con.contrast2test_curr(2) ).SES)
                    % if  isempty(design.DC( con.contrast2test_curr(1) ).SES{:}) || isempty(design.DC( con.contrast2test_curr(2) ).SES{:})
            analysisSessions = [];
        else
            analysisSessions = {strcat('[', design.DC( con.contrast2test_curr(1) ).SES{:}, ']'  ), strcat('[', design.DC( con.contrast2test_curr(2) ).SES{:}, ']'  )};
        end

        if isempty(analysisSessions)
            design.betweenses = 0;
        else
            if strcmp ( design.DC( con.contrast2test_curr(1) ).SES{:}, design.DC( con.contrast2test_curr(2) ).SES{:} )
                design.betweenses = 0;
            else
                design.betweenses = 1;
            end
        end
        design.sesindesign = 1;
    else
        design.betweenses = 0;
        design.sesindesign = 0;
    end

    counter = 1;
    for i = con.contrast2test_curr
        currFolder = fullfile(curr_multarFolder{1}, sprintf("DC%d",i));  % new multar ver / dir change
        trimmedInfile{counter} = sc_reading(currFolder, "*mltout.mat")';
        counter = counter+1;
    end
    clear counter

    if design.betweenses
        contrasts2compare = analysisSessions;
    else
        contrasts2compare = analysisConditions;
    end

    % if sesindesign==1 && betweenses == 0
    %     for i = 1:length(contrasts2compare)
    %         contrasts2compare{i} = strcat('[', design.DC( con.contrast2test_curr(i) ).SES, ']_', contrasts2compare{i});
    %     end
    % end

    for i = 1:2 %complength
        clear col_multar
        for  ds = 1 : length(trimmedInfile{i})
            [~, dsname, ~] = fileparts(trimmedInfile{i}{ds});
            % disp(['Loading ICA2 and source DS: ' char(strrep(dsname,'_mltout','')) ] );
            load_pathfile = trimmedInfile{i}{ds}; %Loading multar data
            [~, load_file, ~] = fileparts(load_pathfile);
            NDTF = load(load_pathfile,'NDTF');
            col_multar{ds}= NDTF;
            load_ids{ds} = load_file(design.idPosStart:design.idPosEnd);
            if design.grpinfiles 
                load_grp{ds} = load_file(design.grpPosStart:design.grpPosEnd);
            else
                load_grp{ds} = [];
            end 
            if design.sesinfiles  %it merans we have multiple dss for singgle subject as multiple sessions are present
                load_ses{ds} = load_file(design.sesPosStart:design.sesPosEnd);
            else
                load_ses{ds} = [];
            end
        end
        all_multar{i} = col_multar;
        all_ids{i} = load_ids;
        all_grp{i} = load_grp;
        all_ses{i} = load_ses;
end
    newline;
    cprintf('*black',  'Stat progress: ');
    cprintf('*black',  num2str(actualstatperc));
    disp('%');
    newline;
    disp(['Currently calculating contrast: ', mat2str(con.contrast2test_curr), '; ', con.subTitle_curr]);

    if design.sesinfiles
        subject_table = cell2table(cell(0,4),'VariableNames' ,{'num','id','grp','ses'});
    else
        subject_table = cell2table(cell(0,3),'VariableNames' ,{'num','id','grp'});
    end

    % count =0;
    % tableRowCounter =1;

    sessions ={};
    validdsNames = {};
    sessId = [];
    sess_counter = 1;
    new_id = '';
    IDs = {};
    countss = 1;

    % clear curr_ids

    for l = 1:length(contrasts2compare)
        for i = 1:length(trimmedInfile{l})
            abortFlag =0;
            split_path = regexp(trimmedInfile{l}{i},'/','split');
            ds_name = strrep(split_path(end),'_mltout.mat','');
            ds_name = ds_name{1};
            validdsNames{countss} = ds_name;
            IDs{countss} = ds_name(design.idPosStart:design.idPosEnd);
            curr_ids{i,l} = ds_name(design.idPosStart:design.idPosEnd);
            if design.sesindesign
                sessions{countss} = ds_name(design.sesPosStart:design.sesPosEnd);
            else
                sessions{countss} = 'all';
            end
            countss = countss+1;
        end
    end

 uniid = unique([all_ids{:}]);
 uniidsize = length(uniid);

    %--- Averaging Freq by chunk data ----%
    %% 3D STATS
    if ndims( all_multar{1}{1}.NDTF) == 3

        if strcmp(con.testType, 'within')
            for contrnr = 1:2  %length(all_multar)    %2
                col_multar = all_multar{contrnr}; %%Getting individual reaserch conditions
                col_ids = all_ids{contrnr};
                col_grp = all_grp{contrnr};
                col_ses = all_ses{contrnr};
                % temp_dtf = zeros(uniidsize, size(load_multar{1},2),size(load_multar{1},3));
                tblrow = 0;
                for ds = 1:uniidsize %length(temp_multar)
                    actualid = uniid{ds};
                    idfound = 0;
                    for dsds = 1:length(col_multar)   %length(curr_ids)
                        if strcmp(col_ids{dsds}, actualid)
                            idfound = 1; tblrow = tblrow + 1;
                            tempndtf = col_multar{dsds}.NDTF ; %Getting Multar data for individual person
                            for i = 1:size(tempndtf,1)
                                for j = 1:size(tempndtf,2) % Getting ROI x ROI elements each individualy, and then sliding vector of 100 to freq
                                    dtfslice = tempndtf(i,j,2*con.freqRange_curr(1):con.freqRange_curr(2)*2); %slicing to specific window  FIXME - this assumes 1-100Hz output
                                    temp_dtf(tblrow,i,j) = mean(dtfslice); % Averaging each slice
                                end
                            end
                            temp_ids2stat{tblrow,:} = col_ids(dsds);
                            temp_grp2stat{tblrow,:} = col_grp(dsds);
                            temp_ses2stat{tblrow,:} = col_ses(dsds);
                        end
                    end
                    % if idfound ==0
                    %     temp_dtf(tblrow,:,:) = NaN;
                    % end
                end
                data2stat(contrnr).data = temp_dtf;
                data2stat(contrnr).id = temp_ids2stat;
                data2stat(contrnr).grp = temp_grp2stat;
                data2stat(contrnr).ses = temp_ses2stat;
            end
        end

        if strcmp(con.testType, 'between')
            for contrnr = 1:2 %length(all_multar)
                col_multar = all_multar{contrnr}; %%Getting individual reaserch conditions
                temp_dtf = zeros(length(col_multar),size(col_multar{1},2),size(col_multar{1},3));
                for ds = 1:length(col_multar)
                    temp_multar_ds = col_multar{ds} ; %Getting Multar data for individual person
                    tempndtf = temp_multar_ds.NDTF;       % Getting NDTFs
                    for i = 1:size(tempndtf,1)
                        for j = 1:size(tempndtf,2) % Getting ROI x ROI elements each individualy, and then sliding vector of 100 to freq
                            dtfslice = tempndtf(i,j,2*con.freqRange_curr(1):con.freqRange_curr(2)*2); %slicing to specific window  FIXME - this assumes 1-100Hz output
                            temp_dtf(ds,i,j) = mean(dtfslice); % Averaging each slice
                        end
                    end
                    [~, dsnejm, ~] = fileparts(trimmedInfile{contrnr}(ds));
                    if contrnr == 1; id2stat1{ds,:} = dsnejm{1}(design.idPosStart:design.idPosEnd); end
                    if contrnr == 2; id2stat2{ds,:} = dsnejm{1}(design.idPosStart:design.idPosEnd); end
                end
                data2stat(contrnr).data = temp_dtf;
            end
        end
    end

    %% 4D - % the same, but in data that has 4 dimensions - if done with window!
    if ndims(all_multar{1}{1}.NDTF) == 4
        error('sDTF - not implemented yet')
    end
    %% Saving %%%

    curr_multarFoldersub=fullfile(curr_multarFolder(1),con.subTitle_curr);
    if ~exist(curr_multarFoldersub{1}); mkdir(curr_multarFoldersub{1});     end

    %% % Subject Data CSV %%

    if design.sesindesign   %FIXME
        if (~isempty(design.DC(con.contrast2test_curr(1)).SES) && ~isempty(design.DC(con.contrast2test_curr(2)).SES))
            expSessions = [design.DC(con.contrast2test_curr(1)).SES  ,  design.DC(con.contrast2test_curr(2)).SES];
        else
            % expSessions = design.sessions;
            expSessions = {'all'};
        end
    else
        expSessions = {'all-fixme'};
    end
    sess2infileindex.name = 'dd';
    sess2subjid.name = 'dd';

    % MD - Whats the purpose of this loop? Is it to get session name and ID
    % from subject files? 
    for nm = 1:length(validdsNames)
        currName = validdsNames{nm};
        for sess = expSessions
            if ~isfield(sess2infileindex,sess{1}) % MD -  adds empty fields if no sessions of that kind were specified
                sess2infileindex.(sess{1}) = [];
                sess2subjid.(sess{1}) = {};
            end
            if design.sesindesign
                if strcmp(currName(design.sesPosStart:design.sesPosEnd),sess{1}) % MD -  I Think this is were it becomes unstable -as there are no sessions named "all"
                    sess2infileindex.(sess{1}) = unique([sess2infileindex.(sess{1}) nm]);
                    sess2subjid.(sess{1}) = unique([sess2subjid.(sess{1}) {currName(design.idPosStart:design.idPosEnd)}]);
                end
            else
                sess2infileindex.(sess{1}) = unique([sess2infileindex.(sess{1}) nm]);
                sess2subjid.(sess{1}) = unique([sess2subjid.(sess{1}) {currName(design.idPosStart:design.idPosEnd)}]);
            end
        end
    end

    % ids = {};
    % id_count=1;

    % if strcmp(con.testType, 'within')
    %     tableiter = 1;
    % else
    %     tableiter = 2;
    % end

    if strcmp(con.testType, 'within')

        for r = 1:size(data2stat(1).data,1)

            currow = cell2table(num2cell(zeros(1,length(subject_table.Properties.VariableNames))),'VariableNames' ,subject_table.Properties.VariableNames);
            currow.num = r;
            currow.id = data2stat(1).id{r}{1};
            if design.grpinfiles 
                currow.grp = data2stat(1).grp{r}{1}; 
            else
                currow.grp = "";
            end
            if design.sesinfiles
                currow.ses = data2stat(1).ses{r}{1}; 
            else
                currow.ses = "";
            end

            subject_table = [subject_table; currow] ;


        end

    end

    id_count = 0
    for l = 1:2 %length(contrasts2compare)
        latest_id = 0;
        for i = 1:length(trimmedInfile{l})
            abortFlag =0;
            split_path = regexp(trimmedInfile{l}{i},'/','split');
            ds_name = strrep(split_path(end),'_mltout.mat','');
            ds_name = ds_name{1}; % Get ds_name

            id = ds_name(design.idPosStart:design.idPosEnd);
            if isempty(find(strcmp(data2stat(1).id,id))) % Add to the DS Counter
                data2stat(1).id{id_count} = id;
                id_count = id_count+1;
            else
                abortFlag = 1;
            end

            if isfield(design,'grpPosStart') && isfield(design,'grpPosEnd')
                if design.grpPosStart ~=0 && design.grpPosEnd ~=0
                    group = (ds_name(design.grpPosStart:design.grpPosEnd));
                    if ~isempty(dc2compare(l).GRP)
                        if ~any(strcmp(group,dc2compare(l).GRP))
                            abortFlag = 1;
                        end
                    end
                else
                    group = NaN;
                end
            else
                group =NaN;
            end

            if design.sesindesign
                if design.sesPosStart ~=0 && design.sesPosEnd ~=0
                    session =(ds_name(design.sesPosStart:design.sesPosEnd));
                    if ~isempty(dc2compare(l).SES)
                        if ~any(strcmp(session,dc2compare(l).SES))
                            abortFlag = 1;
                        end
                    end
                else
                    session =NaN;
                end
            else
                session =NaN;
            end
            currow = cell2table(num2cell(zeros(1,length(subject_table.Properties.VariableNames))),'VariableNames' ,subject_table.Properties.VariableNames);
            currow.num = tableRowCounter;
            currow.id = id;
            currow.group = group ;

            sess_counter = sess_counter+1;
            if~strcmp(latest_id, id)

                subject_table = [subject_table; currow];
                tableRowCounter = tableRowCounter+1;
            end
            %             end
            latest_id = id;
        end
    end
    ROI_names = {loc.ROI.name};


    clear iqr_temp
    %%% Calculating Outliers:
    % - Creates a cell matrix with vectors designating indicies that are outliers
    if isfield(con, 'iqr')
        if con.iqr_curr
            data2stat_iqr = data2stat;

            % IQR of CLusters across subjects
            for compari =1:2 % Cond 1 vs Cond 2
                for from = 1:size(data2stat(compari).data,2) % Cluster vs...
                    for to = 1:size(data2stat(compari).data,3) % ...Cluster
                        not_in_iqr = [];
                        currrent_cond_data = data2stat(compari).data(:,from,to);
                        [iqrcurr, q1, q3] = sc_iqr(currrent_cond_data);
                        not_in_iqr = sort([not_in_iqr; find(currrent_cond_data>(q3+con.iqr_curr*iqrcurr))]);
                        not_in_iqr = sort([not_in_iqr; find(currrent_cond_data<(q1-con.iqr_curr*iqrcurr))]);
                        data2stat_iqr(compari).data(not_in_iqr,from,to) = NaN; % NaN If an Outlier
                    end
                end
            end
            data2stat = data2stat_iqr;
        end
    else
        con.iqr_curr = 0;
    end

    clear vec2table
    compari_names = contrasts2compare;   % column names
    if strcmp(compari_names{1}, compari_names{2}) %Check whether compari names are the same (between)- if so, no new columns should be generated
        vec2table(1).data = [data2stat(1).data; data2stat(2).data];%Generate joint Data Matrix!
        vec2table(1).name = compari_names{1};
        vec2table(2).data = [];  
        compari_names = {contrasts2compare{1}};

    else
        vec2table = data2stat;
    end

    % fix for session matrix (this is within test but with some possible data lacking)
    if design.betweenses
        sessions = []; % previous sess based on existing mmultar files (which may be lacking between sessions) will be replaced to fix
        sess1 = char(design.DC(con.contrast2test_curr(1)).SES);
        sess2 = char(design.DC(con.contrast2test_curr(2)).SES);
        for ss = 1:size(data2stat(1).data,1)  % the size of the stat vector (both should be the same for ses comparison)
            sessions{ss} = sess1;
            sessions{ss + size(data2stat(1).data,1)} = sess2;
        end
    end

% check if id table is consistent with data2stat
% if size(data2stat(1).data,1) ~= length(id2stat1) | size(data2stat(2).data,1) ~= length(id2stat2); error('data mismatch. bug or bad config'); end


    % for l = 1:2
    %     svt(l) = size(vec2table(l).data,1);
    % end

    if strcmp(con.testType,'between')
        lsize = 1;
        id2stat = [id2stat1; id2stat2];
    elseif strcmp(con.testType,'within')
        lsize = 2;
    else
        error('con.testType not defined properly. either within or between is valid');
    end
%%
    for l = 1:lsize
            for j = 1:size(vec2table(1).data,2)
                for k =1:size(vec2table(1).data,3)
                    if j~=k
                        sess = sessions(i);
                        % sess = char( sessions(j + (l-1)*svt(1)) );         %%% get true subj table

                        if design.sesindesign
                            currenDataChunk = vec2table(l).data(:,k,j);  % fill with NaNs - WARNING! Do it accordingly to the groups!
                        else
                            sesvec = sess2infileindex.(char(sess)); 
                            sesvec = sesvec(1:size(vec2table(l).data,1));
                            currenDataChunk = vec2table(l).data(:,k,j);  % fill with NaNs - WARNING! Do it accordingly to the groups!
                        end
                        %where is the second group?
                        tempdtfess = [sess2infileindex.(char(sess))];
                        %Get IDs and subsequently fill those that are missing with NaNs
                        currentSessPrep = sess2subjid.(char(sess));

                        CurrentDataChunk2 = [];
                        idpresent =subject_table.id;
                        iterCurrentPreprocessed = 1;
                        for indic = 1:height(subject_table)
                            if ~isempty(find(strcmp(currentSessPrep,idpresent(indic,:))))
                                if strcmp(con.testType,'between')
                                    % CurrentDataChunk2(indic) = currenDataChunk(find(strcmp(currentSessPrep,idpresent(indic,:))));
                                    
                                        if ~isempty( currenDataChunk(find(strcmp(id2stat,idpresent(indic,:)))) ); 
                                            CurrentDataChunk2(indic) = currenDataChunk(find(strcmp(id2stat,idpresent(indic,:)))) ;
                                        else
                                            CurrentDataChunk2(indic) = NaN;
                                        end
                                end
                                if strcmp(con.testType,'within')
                                    if l==1; CurrentDataChunk2(indic) = currenDataChunk(find(strcmp(id2stat1,idpresent(indic,:)))); end
                                    if l==2; CurrentDataChunk2(indic) = currenDataChunk(find(strcmp(id2stat2,idpresent(indic,:)))); end
                                end
                            else
                                CurrentDataChunk2(indic) = NaN;
                            end
                        end
                        currenDataChunk = CurrentDataChunk2;

                        subject_table.(sprintf( '%s_%s_%s_%s',string(compari_names{l}),string(ROI_names(j)), string(ROI_names(k)))) = currenDataChunk';%vec2table(l).data(:,k,j);
                    end
                end
            end
        % end
    end
%%
    %--- Conducting T or Wilcoxon Test ----%

    clear vec2stat
    count_sig = 0; %MD - for boxplotting


    %% Stats if Multar matrix == 3D - single time window connectivity
    if ndims(all_multar{1}{1}.NDTF) == 3

        p_matrix = ones(size(data2stat(1).data,2),size(data2stat(1).data,3));
        s_matrix = ones(size(data2stat(1).data,2),size(data2stat(1).data,3));

        for i = 1:size(data2stat(1).data,2)
            for j = 1:size(data2stat(1).data,3)
                for k = 1:length(data2stat)
                    vec2stat{k} = data2stat(k).data(:,i,j);
                end

                if i ~= j
                    if strcmp(con.testType, 'between')
                        [p,~] =  ranksum(vec2stat{1},vec2stat{2});  % STAT TEST
                    elseif strcmp(con.testType, 'within')
                        [p,~] = signrank(vec2stat{1},vec2stat{2});
                    end
                    if con.oneTailed
                        p_matrix(i,j) = p/2;
                    else
                        p_matrix(i,j) = p;
                    end
                end
            end
        end

        if isfield(con, 'p_adjust')
            p_matrix = pval_adjust(p_matrix, con.p_adjust);
            padjlabel = ['; p-values ' con.p_adjust ' thr '];
        else
            padjlabel = ['; p-values unc thr '];
        end


        for i = 1:size(data2stat(1).data,2)
            for j = 1:size(data2stat(1).data,3)
                for k = 1:length(data2stat)
                    vec2stat{k} = data2stat(k).data(:,i,j);
                end

                if i ~= j
                    if p_matrix(i,j) > con.pThresh_curr
                        p_matrix(i,j) =1;
                    else
                        count_sig = count_sig+1;
                        sig_comparisons{count_sig} = vec2stat;
                    end

                    if mean(vec2stat{1},'omitnan') > mean(vec2stat{2},'omitnan')  % set the sign of the compari difference
                        s_matrix(i,j) = 1;
                    else
                        s_matrix(i,j) = -1;
                    end
                end
            end
        end

        if isfield(design.DC, 'name')
            label1 = string(design.DC(con.contrast2test_curr(1)).name) ;
            label2 = string(design.DC(con.contrast2test_curr(2)).name) ;
        else
            if strcmp(con.testType,'between')
                label1 = string(design.DC(con.contrast2test_curr(1)).GRP{1}) ;
                label2 = string(design.DC(con.contrast2test_curr(2)).GRP{1}) ;
            elseif strcmp(con.testType,'within')

                if isfield(design.DC, 'SES')
                    % label1 = string(strcat( design.DC(con.contrast2test_curr(1)).SES{1}, '-', design.DC(con.contrast2test_curr(1)).COND{1} )) ;
                    % label2 = string(strcat( design.DC(con.contrast2test_curr(2)).SES{1}, '-', design.DC(con.contrast2test_curr(2)).COND{1} )) ;
                    kond1=[]; kond2 = [];
                    for le = 1: length(design.DC(con.contrast2test_curr(1)).COND{1})
                        kond1 = strcat(kond1, design.DC(con.contrast2test_curr(1)).COND{le} );
                    end
                    for le = 1: length(design.DC(con.contrast2test_curr(2)).COND{1})
                        kond2 = strcat(kond2, design.DC(con.contrast2test_curr(2)).COND{le} );
                    end
                    label1 = string(strcat( design.DC(con.contrast2test_curr(1)).SES{1}, '-', kond1 )) ;
                    label2 = string(strcat( design.DC(con.contrast2test_curr(2)).SES{1}, '-', kond2 )) ;
                else
                    %                     label1 = string(design.DC(con.contrast2test_curr(1)).COND{1}) ;
                    %                     label2 = string(design.DC(con.contrast2test_curr(2)).COND{1}) ;
                    label1 = strjoin(design.DC(con.contrast2test_curr(1)).COND, '+') ;
                    label2 = strjoin(design.DC(con.contrast2test_curr(2)).COND, '+') ;
                end
            end
        end

        label1 = strrep(label1, '_', '-');
        label2 = strrep(label2, '_', '-');


        %% BOXPLOTTING

        if isfield(design,'grpPosStart') && isfield(design,'grpPosEnd')  %add GRP to the titles
            grr1 = convertCharsToStrings(char(design.DC(con.contrast2test_curr(1)).GRP)');
            grr2 = convertCharsToStrings(char(design.DC(con.contrast2test_curr(2)).GRP)');
            if strcmp(grr1, grr2)
                grptitle = grr1;
            else
                grptitle = strcat(grr1, '-', grr2);
            end
            grptitle=strcat('-', grptitle);
        else
            grptitle = '';
        end

        if isfield(con, 'stat_name')
            stat_name2 = strcat('_', con.stat_name);
        else
            stat_name2 = strcat('-_p', mat2str(con.pThresh_curr), '_iqr', mat2str(con.iqr_curr) );
        
        end

        out_dir = strrep(curr_multarFoldersub{1},'mltout','');
        if strcmp(con.testType, 'within')
            out_file = fullfile( out_dir, strcat(con.conName,'_', con.subTitle_curr, grptitle, '_', label1,'_vs_',label2, stat_name2));
        else
            out_file = fullfile( out_dir, strcat(con.conName,'_', con.subTitle_curr, '_', contrasts2compare{1}, '_', label1,'_vs_',label2, stat_name2));   %group comparison - the same condition / session
        end
        table_file = strcat(out_file, '.xlsx');
        box_file = strcat(out_file, '_BOXPLOT.png');
        mat_file = strcat(out_file, '_MATRIX.png');
        pmat_file = strcat(out_file, '_MATRIX.mat');

        enum_sig = 1;  %for enumerating sig effects
        %%
        if count_sig
            gcf = figure('visible','off');
            set(gcf, 'DefaultTextFontSize', 15);

            tile_numbers =ceil(sqrt(sum(sum(p_matrix < con.pThresh_curr))));
            if count_sig == 1; tile_numbers = 1; end
            tiledlayout(tile_numbers,tile_numbers);   %original subplot layout

            for i = 1:size(p_matrix,1)
                for j= 1:size(p_matrix,2)
                    if i ~= j
                        if p_matrix(i,j) < con.pThresh_curr
                            vecs_to_compare = sig_comparisons{enum_sig};

                            %Create Labels:

                            grp = [zeros(length(vecs_to_compare{1}),1); ones(length(vecs_to_compare{2}),1)];
                            vecs_to_compare = [vecs_to_compare{1}; vecs_to_compare{2}];
                            nexttile
                            boxplot(vecs_to_compare, grp','Labels',{ char(label1), char(label2)})
                            xlabel('Contrast')
                            title([loc.ROI(j).name ' - ' loc.ROI(i).name])
                            enum_sig = enum_sig+1;
                        end
                    end
                end
            end

            %%% Saving BoxPlots
            % set(gcf, 'visible', 'on');
            % exportgraphics(gcf,box_file)

            set(gcf, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');  % save invisible fig with enabled visibility
            exportgraphics(gcf,box_file)

            close(gcf)
            
        else
            warning('There are no significant connectivity effect within the network. Boxplots will not be plotted')
        end
        %%
        data2heatplot = round(p_matrix,3).*s_matrix;
        lowp = find(abs(data2heatplot)<0.0001);
        data2heatplot(lowp) = 0.00001 * s_matrix(lowp);

        if strcmp (extractAfter(string(curr_multarFolder),strlength(string(curr_multarFolder))-2), 'nc')
            lclabel = 'UNC';
        elseif strcmp (extractAfter(string(curr_multarFolder),strlength(string(curr_multarFolder))-2), 'lc')
            lclabel = 'LC';
        else
            error ('sth went wrong :(')
        end
        if con.iqr_curr
            iqrlabel = num2str(con.iqr_curr);
        else
            iqrlabel = 'none';
        end

        %% HEATMAPS

        gcf = figure('visible', 'off');
         % heatmap( data2heatplot,'XData',{loc.ROI(:).name},'YData',{loc.ROI(:).name},'Title', strjoin({con.conName, '-', con.subTitle_curr, grptitle, '; ', label1, ' vs ', label2, padjlabel, num2str(con.pThresh_curr), '; ', lclabel, '; iqr=', iqrlabel}), 'ColorLimits',[-con.pThresh_curr con.pThresh_curr],'FontSize' , 15);
        heatmap( data2heatplot,'XData',{loc.ROI(:).name},'YData',{loc.ROI(:).name},'Title', strjoin(strcat([con.conName, '-', con.subTitle_curr, grptitle, '; ', label1, ' vs ', label2, padjlabel, num2str(con.pThresh_curr), '; ', lclabel, '; iqr=', iqrlabel])), 'ColorLimits',[-con.pThresh_curr con.pThresh_curr],'FontSize' , 15);

        colormap bone
        ccc = colormap;
        sss = zeros(100,3);
        sss(1:50,:) = ccc(1:50,:);
        sss = 1-sss;
        for r = 1:50
            sss(r,:) = sss(r,:) * (1-r/200);
        end
        colormap pink
        ccc = colormap;
        for r = 51:99
            sss(r,:)= ccc(100-r,:);
        end

        for r = 51:99
            sss(r,:) = sss(r,:) * (1-(100-r)/200);
        end
        sss(51:99,:) = 1-sss(51:99,:);
        colormap(sss);
        % shg

        disp('...Saving')
        writetable(subject_table,table_file, 'WriteMode', 'replacefile');
        
        set(gcf, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');  % save invisible fig with enabled visibility
        exportgraphics(gcf,mat_file)

        save (pmat_file, 'p_matrix');
        close(gcf)



        %% ARROWPLOT
        if ~isfield(con, 'arrow_subset')  % set if only subset of ROIs is to be visualized by arrows
            con.arrow_subset = {1:length(loc.ROI)};
        end

        for arrowplotnr = 1:length(con.arrow_subset)
            figvis = 0;
            sc_roiplot;
            curr_arrow_subset = con.arrow_subset{arrowplotnr};
            
            if length(con.arrow_subset) ==1
                arrow_file = strcat(out_file, '_ARROWS.png');
            else
                if isfield(con, 'arrow_subset_name')
                    arrownameadd = con.arrow_subset_name{arrowplotnr};
                else
                    arrownameadd = ['_' mat2str(arrowplotnr)];
                end
                arrow_file = strcat(out_file, '_', arrownameadd, '_ARROWS.png');
            end

            s=size(p_matrix,2);

  
            for columnindex = 1:s
                for rowindex = 1:s
                    if columnindex ~= rowindex && ismember(columnindex, curr_arrow_subset) && ismember(rowindex, curr_arrow_subset)   % plot only ROIs indicated by subset

                        lofr = loc.ROI(columnindex).pos;
                        loto = loc.ROI(rowindex).pos;
                        di = loto - lofr;
                        loto2 = lofr + di*0.95;  %make the arrow finish at 95% of distance

                        if s_matrix(rowindex,columnindex)>0
                            if p_matrix(rowindex,columnindex)<0.05 && p_matrix(rowindex,columnindex)>=0.01
                                lwidth = '1';
                            elseif p_matrix(rowindex,columnindex)<0.01 && p_matrix(rowindex,columnindex)>=0.001
                                lwidth = '2';
                            elseif p_matrix(rowindex,columnindex)<0.001
                                lwidth = '4';
                            else
                                lwidth = '';
                            end
                            if ~isempty(lwidth)
                                arrow3(lofr,loto2,['s',lwidth],0.7,1,0.2,1);
                            end

                        end
                        if s_matrix(rowindex,columnindex)<0
                            if p_matrix(rowindex,columnindex)<0.05 && p_matrix(rowindex,columnindex)>=0.01
                                lwidth = '1';
                            elseif p_matrix(rowindex,columnindex)<0.01 && p_matrix(rowindex,columnindex)>=0.001
                                lwidth = '2';
                            elseif p_matrix(rowindex,columnindex)<0.001
                                lwidth = '4';
                            else
                                lwidth = '';
                            end
                            if ~isempty(lwidth)
                                arrow3(lofr,loto2,['l',lwidth],0.7,1,0.2,1);

                            end
                        end
                    end
                end
            end

            title(['\color{cyan}' label1 ' \color{black} > \color{gray}' label2], 'FontSize', 13)
            set(gcf, 'CreateFcn', 'set(gcbo,''Visible'',''on'')');  % save invisible fig with enabled visibility
            set(gcf, 'Position', [11111 11111 1800 1200]);

            exportgraphics(gcf,arrow_file)
            arrow_file = strrep(arrow_file, 'png', 'fig');
            % figpos = gcf.Position;
            % set(gcf, 'Visible', 'on');
            savefig(gcf, arrow_file);
            % exportgraphics(gcf, arrow_file, 'BackgroundColor', 'white');
            close(gcf)
        end

        % arrows end


    end

    clear png_file ccc sss table_file
end %




