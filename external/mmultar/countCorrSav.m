function [rleft_tot,rright_tot,r_tot]=countCorrSav(x,ip,iwhat)
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

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
rleft_tot=zeros(mip,mip,trials);
rright_tot=zeros(mip,m,trials);
r_tot=zeros(m,m,trials);

for trial=1:trials
    for k=1:ip
        if iwhat==1
            corrscale=1/n;
            nn=n-k;
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
        elseif iwhat==2
            corrscale=1/(n-k);
            nn=n-k;
            r(:,:)=DGEMM_symul('N','T',m,m,nn,corrscale,x(1:m,1:nn,trial),m,x(1:m,k+1:k+nn-1+1,trial),m,0,0,m);
        end

        rright((k-1)*m+1:(k-1)*m+1+m-1,:)=r(:,:);

        if k<ip
            for i=1:ip-k
                rleft((k+i-1)*m+1:(k+i-1)*m+1+m-1,(i-1)*m+1:(i-1)*m+1+m-1)=r(:,:);
                rleft((i-1)*m+1:(i-1)*m+1+m-1,(k+i-1)*m+1:(k+i-1)*m+1+m-1)=r(:,:)';
            end
        end
    end

    corrscale=1/n;
    r(:,:)=DGEMM_symul('N','T',m,m,n,corrscale,x(:,:,trial),m,x(:,:,trial),m,0,0,m);

    for k=1:ip
        rleft((k-1)*m+1:(k-1)*m+1+m-1,(k-1)*m+1:(k-1)*m+1+m-1)=r(:,:);
    end

    rleft_tot(:,:,trial)=rleft;
    rright_tot(:,:,trial)=rright;
    r_tot(:,:,trial)=r;
end
