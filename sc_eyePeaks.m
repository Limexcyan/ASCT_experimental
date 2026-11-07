
function num_peaks_in_window = sc_eyePeaks(sig_temp,Fs)
    % This function computes bumer of peaks on a signal to estimate the Heart
    % and Eye components. Requires current Signal and Sampling Frequency
    % Returns number of peaks for each 5s window
    %~ MD
    
    rmpath('/opt/MATbox/emegs3.3/emegs2dLib') % Temporarily disable path to avoid conflicts of matlab native findpeaks with that of Jurgen

    num_peaks_in_window = zeros(round(length(sig_temp)/(5*Fs)),1); % 5s Time windows
    for windows = 1:round(length(sig_temp)/(5*Fs))
        try
            current_window = sig_temp((windows-1)*5*Fs +1:windows*5*Fs);
        catch
            current_window = sig_temp((windows-1)*5*Fs +1:end);
        end
        [peaks,LOCS,width,prominence] = findpeaks(current_window,'MinPeakHeight',std(current_window)*5);
        [peaks2,LOCS2,width2,prominence2] = findpeaks(-current_window,'MinPeakHeight',std(current_window)*5);
        peaks = [peaks peaks2]; % Concatenate both Peaks and throughts
        warn = warning('query','last');
        if ~isempty(warn)
            warn_id = warn.identifier;
            warning('off',warn_id)
        end
        num_peaks_in_window(windows) = length(peaks); % Gtet peaks in windoiw
    end

    addpath('/opt/MATbox/emegs3.3/emegs2dLib') % Add path back on

end