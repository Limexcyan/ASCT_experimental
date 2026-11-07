function [s,h,a]=mult_ar_calc(A,V,fmin,fmax,deltat)
% calculates basic frequency-domain functions from AR coefficents
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

global FRQPMAX
frqstep=(fmax-fmin)/(FRQPMAX-1);
chans=size(A,1);
p=size(A,3);
h=complex(zeros(chans,chans,FRQPMAX));
s=complex(zeros(chans,chans,FRQPMAX));
a=complex(zeros(chans,chans,FRQPMAX));
ci=complex(zeros(1,p));
for frqp=1:FRQPMAX
    frq=fmin+(frqp-1)*frqstep;
    ce=exp(-2*pi*i*frq*deltat);
    ci(1)=ce;
    for k=2:p
        ci(k)=ci(k-1)*ce;
    end
    c=eye(chans);
    for k=1:p
        c=c-A(:,:,k)*ci(k);
    end
    a(:,:,frqp)=c;
    h(:,:,frqp)=inv(c);
    s(:,:,frqp)=h(:,:,frqp)*V*conj(h(:,:,frqp)');
end


    
