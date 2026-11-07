
% addpath '/mnt/devv/SourceConn/SC_functions/MNE_functions/_templates/' % in order to have acces to _grad_150.mat file

clear sensors

% load('sensors.mat', 'sensors');
% load('grad_153.mat')


g_diff = 0; % minds shortening of grad structure due to removal of subsequent instances

for g = 1 : length(sensors.label)
    g_flag = 0; % flag = 0 => remove this sensor of glocloc file

    if strcmp(rc.dataFormat, 'itab')    % probable doesnt needed for simlated itab-sim data
        for gl = 1 : length(header.ch)
            if strcmp(sensors.label{g - g_diff, 1}, header.ch(gl).label) && header.ch(gl).flag == 0 % tak to jest czytane z plików Sary |
                g_flag = 1; % flag=1 => do nothing, just keeps the structure as it is
            end
        end
    end

    for gl = 1 : size(ch_rej) %removng not only channels spotted as bad by chieti team but also by Krakow programme
        if g == ch_rej(gl)
            g_flag = 0;
        end
    end

    if ~g_flag %removal of given instance of grad structure

        sensors.chanori(g-g_diff, :) = [];
        sensors.chanpos(g-g_diff, :) =[];
        sensors.chantype(g-g_diff) = [];
        sensors.chanunit(g-g_diff) = [];
        sensors.coilori(g-g_diff, :) = [];
        sensors.coilpos(g-g_diff, :) =[];
        sensors.tra(g - g_diff , :) = [];
        sensors.tra(: , g-g_diff) = [];
        sensors.label(g - g_diff) = [];

        g_diff = g_diff + 1;

    end
end