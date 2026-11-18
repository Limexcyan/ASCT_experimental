function filtered = asct_multiverse_bandpass(x,fs,band)
% Reference zero-phase FFT mask, for the ORACLE-source benchmark only.
% Production ASCT filtering is performed by its existing preprocessing.
assert(numel(band)==2 && band(1)>0 && band(2)>band(1) && band(2)<fs/2, ...
    'ASCT:InvalidBand','Band must lie below Nyquist');
N=size(x,2);
f=(0:N-1)*fs/N;
mask=(f>=band(1) & f<=band(2)) | (f>=fs-band(2) & f<=fs-band(1));
filtered=real(ifft(bsxfun(@times,fft(x,[],2),reshape(mask,1,N,1)),[],2));
end
