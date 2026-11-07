% export ERP trial-by-trial data from preloaded data_all_arj

samp_freq = data_all_arj(1).fsample;


for w = 1 : length(CSV_win_def)


    start_samp =  round ( (seg.prestim + CSV_win_def{w}{2}/1000 ) * samp_freq) ; %start timepoint for averaging
    if start_samp == 0; start_samp=1; end
    end_samp = round ( (seg.prestim + CSV_win_def{w}{3}/1000 ) * samp_freq ) ; %end timepoint for averaging

    for ds = 1: length(data_all_arj)

        for e = 1 : length(CSV_ele_def)

            ch_ind = []; %indexes of raws for given channels are kept here. They are subsequently used to specify for which row averaging should be applied

            for el = 1: length( CSV_ele_def{e} )  % find relevant electrodes
                i_ch = [];
                i_ch = ismember( data_all_arj(ds).label, CSV_ele_def{e}{el} ); %marks fittinf elements as 1
                i_channel = find(i_ch, 1); %finds which elements are equal to 1
                ch_ind = [ ch_ind i_channel ]; %saves which one are equal 1
            end

            for tr = 1: length(data_all_arj(ds).trial)
            tbt(ds).trial{tr} = mean( data_all_arj(ds).trial{tr}( ch_ind, start_samp : end_samp), 'all' );
            tbt(ds).trig{tr} = data_all_arj(ds).trialinfo(tr,1);
            tbt(ds).trialno{tr} = data_all_arj(ds).trialinfo(tr,2);

            end


        end

        % tbt{ds}.trialav =


    end

end