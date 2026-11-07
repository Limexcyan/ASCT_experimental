
%%--- PARAMETERS ----%
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
            if design.sesinfiles  %it means we have multiple datasets for each single subject as multiple sessions are present
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

    if design.sesinfiles && design.grpinfiles
        subject_table = cell2table(cell(0,4),'VariableNames' ,{'num','id','grp','ses'});
    elseif design.sesinfiles==0 && design.grpinfiles
        subject_table = cell2table(cell(0,3),'VariableNames' ,{'num','id','grp'});

    elseif design.sesinfiles && design.grpinfiles==0
        subject_table = cell2table(cell(0,3),'VariableNames' ,{'num','id','ses'});
    elseif design.sesinfiles==0 && design.grpinfiles==0
        subject_table = cell2table(cell(0,2),'VariableNames' ,{'num','id'});
    end

    uniid = unique([all_ids{:}]);
    uniidsize = length(uniid);

    %%--- Averaging Freq by chunk data ----%
    
    if ndims( all_multar{1}{1}.NDTF) ~= 3
        error('sDTF - not implemented yet')
    end

    if strcmp(con.testType, 'within')
        for contrnr = 1:2  %length(all_multar)    %2
            col_multar = all_multar{contrnr}; %%Getting individual reaserch conditions
            col_ids = all_ids{contrnr};
            col_grp = all_grp{contrnr};
            col_ses = all_ses{contrnr};
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
    
            end
            data2stat(contrnr).data = temp_dtf;
            data2stat(contrnr).id = temp_ids2stat;
            data2stat(contrnr).grp = temp_grp2stat;
            data2stat(contrnr).ses = temp_ses2stat;
        end
    end

    if strcmp(con.testType, 'between')   %FIXME
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


    %% Saving %%%

    curr_multarFoldersub=fullfile(curr_multarFolder(1),con.subTitle_curr);
    if ~exist(curr_multarFoldersub{1}); mkdir(curr_multarFoldersub{1});     end

    %% % Subject Data CSV %%

    if strcmp(con.testType, 'within')

        for r = 1:size(data2stat(1).data,1)
            currow = cell2table(num2cell(zeros(1,length(subject_table.Properties.VariableNames))),'VariableNames' ,subject_table.Properties.VariableNames);
            currow.num = r;
            currow.id = data2stat(1).id{r}{1};
            if design.grpinfiles
                currow.grp = data2stat(1).grp{r}{1};
            else
                % currow.grp = "";
            end
            if design.sesinfiles
                currow.ses = data2stat(1).ses{r}{1};
            else
                % currow.ses = "";
            end
            subject_table = [subject_table; currow] ;
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
        for j = 1:size(data2stat(1).data,2)
            for k =1:size(data2stat(1).data,3)
                if j~=k
                    subject_table.(sprintf( '%s_%s_%s_%s',string(contrasts2compare{l}),string(ROI_names(j)), string(ROI_names(k)))) = data2stat(l).data(:,k,j);%vec2table(l).data(:,k,j);
                end
            end
        end
    end
    %%
    %--- Conducting T or Wilcoxon Test ----%

    clear vec2stat
    count_sig = 0; %MD - for boxplotting


    %% Stats if Multar matrix == 3D - single time window connectivity

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


    % end

    clear png_file ccc sss table_file
end %




