function [ave]=average(signal,peakss,t_pre,t_post,basel_s,basel_f)

if nargin < 6
    basel_s=t_pre;
    basel_f=0;
end


peakss=sort(peakss);
%%% Changed from WHILE to IF - MD 
if peakss(1)+t_pre < 0
    % if peakss(1)+t_pre < 1
    peakss(1)=[];
end

if peakss(1)+t_pre == 0  %mw
    peakss(1)=peakss(1)+1;
end

if peakss(end)+t_post > length(signal)
    peakss(end)=[];
end

ntri=length(peakss);
[nch,ntp]=size(signal);
period=t_post-t_pre+1;
ave=zeros(nch,period);
mat=zeros(ntri,period);
for i=1:nch
    sig=signal(i,:);
    for ind=1:ntri
        try
        mat(ind,:)=sig(peakss(ind)+t_pre:peakss(ind)+t_post)-mean(sig(peakss(ind)+basel_s:peakss(ind)+basel_f));
        catch
dddd
        end
    end
    ave(i,:)=sum(mat)/ntri;
end
