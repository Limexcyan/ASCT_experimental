function [X,F,decx]=calculate_spec(sig,Fsnew,fmax)


%dec=2;
%npt=512;
npt=2^round(log2(2*Fsnew));
decx=round(Fsnew/25);
nwind=npt-decx;

%sig_res=resample(sig,dec,1);
    
%[B,F,T]=specgram(sig_res,npt,Fsnew,npt,nwind);
[B,F,T]=specgram(sig,npt,Fsnew,npt,nwind);


fy=find(F < fmax);

F=F(fy);

B=B(fy,:);

% X=abs(B);

X=B.*conj(B);

clear B;

%decx=npt-nwind;