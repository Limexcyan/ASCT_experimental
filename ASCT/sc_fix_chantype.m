function [data_all] = sc_fix_chantype (data_all)

%% this function recreates hdr.actualchantype field to keep actual channel types as present in the 'trial' signal matrix

for ds = 1: length(data_all)
    if isfield(data_all(ds).hdr, 'actualchantype')
        data_all(ds).hdr.actualchantype = {};
    end
    for e = 1: length(data_all(ds).label)
        nre = find(strcmpi(data_all(ds).label(e), data_all(ds).hdr.label));
        data_all(ds).hdr.actualchantype(e,1) = data_all(ds).hdr.chantype(nre);
    end
end

end
