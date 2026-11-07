
function senstrimmed = sc_trim_sens(chan_labels, chanstruct)

%selects channels from the elecloc full structure based on provided chan_labels

if strcmp(class(chanstruct), 'char')
    load( chanstruct ); % assuming elecfile name  
else
    sens = chanstruct; % assumin sens structure
end

% flag = zeros(length(sens.label),1);

% for e = 1:length(sens.label)
%     for el = 1:length(chan_labels)
%         if strcmpi(sens.label{e}, chan_labels{el}); flag(e)=1; end % flag=1 => do nothing, just keeps the structure as it is
%     end
% end

senstempl = sens;
clear sens

senstrimmed.unit = senstempl.unit;
senstrimmed.type = senstempl.type;

for e = 1:length(chan_labels)
    for s = 1:length(senstempl.label)
        if strcmpi(chan_labels{e}, senstempl.label{s})
            senstrimmed.label(e,1) = senstempl.label(s);
            senstrimmed.chanpos(e,:) = senstempl.chanpos(s,:);
            senstrimmed.chantype(e,1) = senstempl.chantype(s);
            senstrimmed.chanunit(e,1) = senstempl.chanunit(s);
            if isfield(chanstruct,'elecpos'); senstrimmed.elecpos(e,:) = senstempl.elecpos(s,:); end
            if isfield(chanstruct,'coilpos'); senstrimmed.coilpos(e,:) = senstempl.coilpos(s,:); end
            if isfield(chanstruct,'coilori'); senstrimmed.coilori(e,:) = senstempl.coilori(s,:); end
            break;
        end
    end
end




% for e = length(sens.label):-1:1
%     if flag(e) ==0
%         %         disp(e)
%         senstrimmed.label(e) = [];
%         senstrimmed.chanpos(e,:) =[];
%         if isfield(senstrimmed,'elecpos')
%             senstrimmed.elecpos(e,:) =[];
%         end
%         if isfield(senstrimmed,'coilpos')   %assuming MEG sens  FIXME: possibly should not be used for MEG
%             senstrimmed.chanori(e,:) = [];
%             senstrimmed.coilori(e,:) = [];
%             senstrimmed.coilpos(e,:) = [];
%         else  %assuming EEG sens
%                     if isfield(senstrimmed,'tra')
%                         senstrimmed.tra = eye(length(chan_labels));   %this is not proper for MEG sens!
%                     end
%         end
%         if isfield(senstrimmed,'chantype')
%             senstrimmed.chantype(e) = [];
%         end
%         if isfield(senstrimmed,'chanunit')
%             senstrimmed.chanunit(e) = [];
%         end
% 
%     end
% end

end
