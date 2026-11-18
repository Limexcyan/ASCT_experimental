function dtf = asct_mvar_dtf(A,fs,freqHz)
% Row-normalized DTF: dtf(target,source,freq), matching TestDTF.
n=size(A,1);
assert(size(A,2)==n && size(A,3)>=1,'ASCT:InvalidMVAR','Expected square MVAR matrices');
assert(fs>0 && all(freqHz>=0) && all(freqHz<=fs/2),'ASCT:InvalidFrequency','Frequencies must be within Nyquist');
dtf=zeros(n,n,numel(freqHz));
for k=1:numel(freqHz)
    mat=eye(n);
    for lag=1:size(A,3)
        mat=mat-A(:,:,lag)*exp(-2i*pi*lag*freqHz(k)/fs);
    end
    H=mat\eye(n);
    pow=abs(H).^2;
    dtf(:,:,k)=sqrt(bsxfun(@rdivide,pow,sum(pow,2)));
end
end
