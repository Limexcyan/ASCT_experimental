%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Recodding triggers %%%
%%%%%%%%%%%%%%%%%%%%%%%%%%

% The script provides code which recodes triggers assigned during experiment.
% One has to specify which trigger transforms into which one, and under which circumstances.
% Parameters are:
% - 'trig_config' - trigger configuration for all triggers in given ds (previously obtained by calling 'ft_definetrial', which is done automtically in the code of 'sc_2_SEGM' just beofre calling recodding), and
% - 'seg.final_trig_list' - what is a desired list of triggers (chosen from all triggers) you want to further analyse. They are calculated automatically from desing configuration and shoul dbe passed on to this function
% (during recodding the code needs to have access to all triggers in given recording. Therefore, field 'triggers' concatenates all of the triggers to the desired ones in further analysis)
% Structure 'triggers' chooses only those triggers which were specified for analysis in 'design', [see EX_SETUP script under 'design' structure] )
% structure.
%
% WARNING: each template should be edited accordingly to the experiment requirements
% and saved in the experiment folder with an original name (eg. 'sc_recod_ResDep').
% The name of created script is subsequently provided as a parameter in 'EX_SETUP', which passes it further to 'sc_2_SEGM' script.
% ('sc_2_SEGM' script searches for the recodding code under 'recod_fun_to_call = ')

% NOTE: It is important to mentione that trig_config is needed for lasting trigger change.
% This structure is further used as a parameter in 'ft_preprocessing'!


% function [trig_config] = Recoding(trig_config, seg, ds)
function [trig_config] = Recoding(trig_config)


% for i = length(trig_config.event):-1:1    % remove triggers other than 'STATUS' or 'Stimulus'. in Biosemi bdf only 'STATUS' marks experimental events 
%     if ~strcmp(trig_config.event(i).type, 'STATUS')
%         trig_config.event(i)=[];
%     end
% end

% if ~isempty(seg.origTrig)       % creating clean list of triggers that include only relevant ones (as defined in seg.origTrig). this is a fix for possible ghost triggers
%     if ~isempty(seg.origTrig) 
%         for e = length(trig_config.event):-1:1
%             if ~any( seg.origTrig == trig_config.event(e).value )
%                 trig_config.event(e) = [];
%                 % cleantrl(e,:) = [];
%             end
%         end
%     end
% end

for tr = 1 : length(trig_config.event)-1   % actual recoding of triggers
    if trig_config.event(tr).value == 113 & trig_config.event(tr+1).value == 241    % CONG followed by correct resp 241
        trig_config.event(tr).value = 33;
    end

    if trig_config.event(tr).value == 123 & trig_config.event(tr+1).value == 241   % INCO followed by correct resp 241
        trig_config.event(tr).value = 32;
    end
end

% recreating cfg_trigconfig structure based on recoded trig_config.event 
% to comply with the FieldTrip data format

for tr = 1 : length(trig_config.event)
    trig_config.trl(tr,4) = trig_config.event(tr).value;
end

% eventually rejectig trials with triggers out of our interest

for tr = length(trig_config.trl):-1:1
    if ~any( seg.final_trig_list == trig_config.trl(tr,4) )
        trig_config.trl(tr,:)  = [];
        trig_config.event(tr) = [];
    end

end

end
