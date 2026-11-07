function sig_out = lh_filtering(sig, h_filtering, l_filtering, Fs);

switch h_filtering
    case 0.5
        sig_out = filter_h05(sig,Fs);
    case 1
        sig_out = filter_h1(sig,Fs);
    case 40
        sig_out = filter_h40(sig,Fs);
end
sig = sig_out;
switch l_filtering
    case 80
        sig_out = filter_l80(sig,Fs);
    case 100
        sig_out = filter_l100(sig,Fs);
    case 150
        sig_out = filter_l150(sig,Fs);
end
