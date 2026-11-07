
function [pk, loc, wid, prom] = sc_foofEstim(sig_temp,trialLength,Fs)
    rmpath('/opt/MATbox/emegs3.3/emegs2dLib') % Temporarily disable path to avoid conflicts of matlab native findpeaks with that of Jurgen

    % This function aproximates aperiodic component of a Power Spectrum of
    % a signal and then computes Number of distinct Peaks from it

    win =  trialLength;            % Window equal to trial length (Convention in ASCT)
    noverlap = round(win * 0.5);   % 50% overlap
    nfft = win;                    % larger FFT for smoother freq axis

    [pxx, freqs] = pwelch(sig_temp, win, noverlap, nfft, Fs);

    f_range = [2 30];                   %%% Re-cut to range
    pxx = pxx(freqs >f_range(1) & freqs <=f_range(2));
    freqs = freqs(freqs >f_range(1) & freqs <=f_range(2));


    %%% --- 2) Fit aperiodic (1/f) ------------------------------------------
    log_f = log10(freqs);
    log_p = log10(pxx);

    coef   = polyfit(log_f, log_p, 1);   % coef(1)=slope, coef(2)=intercept
    fit_lp = polyval(coef, log_f);       % log10 of aperiodic fit
    ap_lin = 10.^fit_lp;                 % aperiodic fit in linear power

    % 3) remove aperiodic component (flatten)
    flat_lin = pxx ./ ap_lin;             % ~1 = baseline, >1 = peaks
    % or in log-space: flat_log = log_p - fit_lp;

    % 4) find oscillatory peaks on flattened spectrum
    [pk, loc, wid, prom] = findpeaks(flat_lin, freqs, ...
        'MinPeakHeight', 1.4, ...       % 5% above background
        'MinPeakProminence', 0.4);

    addpath('/opt/MATbox/emegs3.3/emegs2dLib') % Add path back on

end
