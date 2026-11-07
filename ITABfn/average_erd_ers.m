function ave = average_erd_ers(image,peaks,t_pre,t_post,basel_s,basel_f)

% Average of a time-frequency representation
% INPUT: image   - DATA MATRIX (rows: different frequencies; columns: time lags)
%        peaks   - time lags of trigger. Expressed IN POINTS
%        t_pre   - pre-trigger interval in points (with sign: MINUS - pretrigger before trigger)
%        t_post  - post-trigger interval in points
%        basel_s - baseline onset (in points) with sign
%        basel_f - baseline offset (in points) with sign
% OUTPUT: ave    - averaged data matrix (rows: different freqeuncies; columns: time lags in points from t_pre to t_post)

if nargin < 6
    basel_s = t_pre;
    basel_f = 0;
end


peaks=sort(peaks);

while peaks(1)+t_pre < 1
    peaks(1)=[];
end

while peaks(end)+t_post > size(image,2)
    peaks(end)=[];
end

ntri = length(peaks);
[nfreq,ntp] = size(image);
period = t_post-t_pre+1;
ave = zeros(nfreq,period);
mat = zeros(ntri,period);
for i = 1:nfreq
    sig = image(i,:);
    for ind = 1:ntri
        mat(ind,:) = sig(peaks(ind)+t_pre:peaks(ind)+t_post);
    end
    tmp = sum(mat)/ntri;
    ave_tmp = mean(tmp(1+basel_s-t_pre:1+basel_f-t_pre));
    ave(i,:) = 100*(tmp-ave_tmp)/ave_tmp;
end