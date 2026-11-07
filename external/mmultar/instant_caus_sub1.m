function [ARb0,ARb,Vb]=instant_caus_sub1(ARr,Vr)

sz=size(ARr);
chans=sz(1);
p=sz(3);

[L,Vb]=ldl(Vr);
LI = inv(L);

ARb0=eye(chans)-LI;
ARb=zeros(sz);
for ord=1:p
    ARb(:,:,ord)=LI*ARr(:,:,ord);
end

