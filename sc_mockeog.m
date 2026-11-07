function [data_prep] = sc_mockeog(data_prep, chan)

% add s a mock EOG channel if noe EOG is present in the signal

    newchnr = length(data_prep.hdr.actualchantype) +1;
    oldchnr = length(data_prep.hdr.label);

    data_prep.label(newchnr)={'EOG'};



    data_prep.hdr.label(oldchnr+1)={'EOG'};
    data_prep.hdr.chantype(oldchnr+1)={'eog'};
    data_prep.hdr.chanunit(oldchnr+1)=data_prep.hdr.chanunit(oldchnr);
    data_prep.hdr.nChans = oldchnr+1;
    
    data_prep.hdr.actualchantype(newchnr)={'eog'};
    
    % data_prep.hdr.elec.label(65)={'EOG'};
    % data_prep.hdr.elec.chanpos(65,1)=0; data_prep.hdr.elec.chanpos(65,2)=0; data_prep.hdr.elec.chanpos(65,2)=0;
    % data_prep.hdr.elec.chantype(65)={'eog'};
    
    for t = 1:length(data_prep.trial)
    data_prep.trial{t}(newchnr,:)=(data_prep.trial{t}(chan.addMockEOG(1),:)+data_prep.trial{t}(chan.addMockEOG(2),:))/2;
    end

    % save(fullfile("ana_class/1_PREPROCESSED/",filename), "data_prep")


return