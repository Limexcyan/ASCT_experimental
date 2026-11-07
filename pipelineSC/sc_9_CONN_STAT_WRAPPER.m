
% wrapper for statisics allowing define multipl tests (multiple contrast & freq bins)

if rc.simStats   % exception: single case stats for simulations
    sc_simstats

else  % regular statistics for experimental mode

cnl = length(con.contrast2test);
frl = length(con.freqRange);
iql = length(con.iqr);
ptl = length(con.pThresh);

if frl ~= length(con.subTitle); disp('ERROR in STATS section.  The number of freq ranges must be the same as relevant labels.'); error('Correct EXSetup before continuing'); end

    statsteps = cnl*frl*iql*ptl;

    for cn = 1:cnl
        for fr = 1:frl
            for iq = 1:iql
                for pt = 1:ptl

                    con.contrast2test_curr = con.contrast2test{cn};
                    
                    con.freqRange_curr = con.freqRange{fr};
                    con.subTitle_curr = con.subTitle{fr};
                    
                    con.iqr_curr = con.iqr{iq};
                    con.pThresh_curr = con.pThresh{pt};
                    
                    actualstatperc = round(( (cn-1)*frl*iql*ptl + (fr-1)*iql*ptl + (iql-1)*ptl + (ptl-1)  ) / statsteps * 100);

                    if con.sensorLevel == 0
                        sc_9_CONN_STAT
                    else
                        sc_9_CONN_STAT_sensors
                    end
                end
            end
        end
    end

end
