% trims chanloc structure according to the actual number of channels subjected to ICA and saves for the eeglab topoplot
% if nch=64 then it only copies the original elc to the exp dir

function sc_locfile(chanlocs, saveFolderds)


nch = length(chanlocs.label);
fid=fopen('emptytemplate.elc');
tline = fgetl(fid);
tlines = cell(0,1);
while ischar(tline)
    tlines{end+1,1} = tline;
    tline = fgetl(fid);
end
tlines(4) = strrep(tlines(4),'XXX',mat2str(nch));
tlines(nch+6) = tlines(6);
for i = 1:nch
    tlines(i+5) = {num2str(chanlocs.chanpos(i,:))};
end

for i = 1:length(chanlocs.chanpos) 
    tlines(i+nch+6) = chanlocs.label(i);
end
fclose(fid);

writecell(tlines, fullfile(saveFolderds, 'ch_trimmed.txt'));
movefile(fullfile(saveFolderds, 'ch_trimmed.txt'), fullfile(saveFolderds, 'ch_trimmed.elc'))
end