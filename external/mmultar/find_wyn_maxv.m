function maxv=find_wyn_maxv(wyn)

if isempty(wyn) return; end

sz=size(wyn);
if length(sz)>3
    maxv=max(max(max(zerujdiag(squeeze(wyn(:,:,:,1))))));
    for i=2:sz(4)
        maxv=max([maxv max(max(max(zerujdiag(squeeze(wyn(:,:,:,i))))))]);
    end
else
    maxv=max(max(max(zerujdiag(wyn(:,:,:)))));
end