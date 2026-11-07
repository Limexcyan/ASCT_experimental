% C Author: Rafal Kus <rkus@fuw.edu.pl>, (C) 2005
% C CORRELCOV computes covariance matrices needed by 
% C covariance and modificated covariance alorithms, which estimates
% C Multivariate Autoregressive Model's coefficients.
function [rleft_tot,rright_tot,r_tot]=countCorr(x,ip,iwhat)

sdt=size(x);
m=sdt(1);
n=sdt(2);
if length(sdt)>2
    trials=sdt(3);
else
    trials=1;
end

mip=m*ip;

rleft=zeros(mip,mip);
rright=zeros(mip,m);
r=zeros(m,m);
rleft_tot=zeros(mip,mip);
rright_tot=zeros(mip,m);
r_tot=zeros(m,m);

for trial=1:trials
    for k=1:ip
        if iwhat==1
            corrscale=1/n;
            nn=n-k;
            %disp([1,m,nn,k+1,k+nn-1+1])
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
            %disp(r)
        elseif iwhat==2
            corrscale=1/(n-k);
            nn=n-k;
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
        end

        %disp([2,k,m,(k-1)*m+1,(k-1)*m+1+m-1]);
        rright((k-1)*m+1:(k-1)*m+1+m-1,:)=r(:,:);

        if k<ip
            for i=1:ip-k
                %disp([3,k,m,(k+i-1)*m+1,(k+i-1)*m+1+m-1,(i-1)*m+1,(i-1)*m+1+m-1]);
                rleft((k+i-1)*m+1:(k+i-1)*m+1+m-1,(i-1)*m+1:(i-1)*m+1+m-1)=r(:,:);
                %disp([4,k,m,(i-1)*m+1,(i-1)*m+1+m-1,(k+i-1)*m+1,(k+i-1)*m+1+m-1]);
                rleft((i-1)*m+1:(i-1)*m+1+m-1,(k+i-1)*m+1:(k+i-1)*m+1+m-1)=r(:,:)';
            end
        end
    end

    corrscale=1/n;
    %disp([5,m,n]);
    r(:,:)=DGEMM_symul('N','T',m,m,n,corrscale,x(:,:,trial),m,x(:,:,trial),m,0,0,m);

    for k=1:ip
        %disp([6,k,m,(k-1)*m+1,(k-1)*m+1+m-1,(k-1)*m+1,(k-1)*m+1+m-1]);
        rleft((k-1)*m+1:(k-1)*m+1+m-1,(k-1)*m+1:(k-1)*m+1+m-1)=r(:,:);
    end

    rleft_tot=rleft_tot+rleft;
    rright_tot=rright_tot+rright;
    r_tot=r_tot+r;
end

if trials>1
    rleft_tot=rleft_tot/trials;
    rright_tot=rright_tot/trials;
    r_tot=r_tot/trials;
end
