function [rleft_tot,rright_tot,r_tot]=countCovSav(x,ip,iwhat)
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
nnconst=n-2*ip;

rleft=zeros(mip,mip);
rright=zeros(mip,m);
r=zeros(m,m);
rleft_tot=zeros(mip,mip,trials);
rright_tot=zeros(mip,m,trials);
r_tot=zeros(m,m,trials);

for trial=1:trials
    rconst=zeros(m,m,ip+1);
    for k=0:ip
        rconst(:,:,k+1)=DGEMM_symul('N','T',m,m,nnconst,1,x(1:m,ip-k+1:ip-k+nnconst-1+1,trial),m,x(1:m,ip+1:ip+nnconst-1+1,trial),m,0,0,m);
        if iwhat==8
            rconst(:,:,k+1)=DGEMM_symul('N','T',m,m,nnconst,1,x(1:m,ip+k+1:ip+k+nnconst-1+1,trial),m,x(1:m,ip+1:ip+nnconst-1+1,trial),m,1,rconst(:,:,k+1),m);
        end
    end

    for i=0:ip
        for j=i:ip
            k=j-i;
            r(:,:)=squeeze(rconst(:,:,k+1));
            if i>0
                nn_beg=i;
                r(:,:)=DGEMM_symul('N','T',m,m,nn_beg,1,x(1:m,ip-i-k+1:ip-i-k+nn_beg-1+1,trial),m,x(1:m,ip-i+1:ip-i+nn_beg-1+1,trial),m,1,r,m);
            end
            if i~=ip
                nn_end=ip-i;
                r(:,:)=DGEMM_symul('N','T',m,m,nn_end,1,x(1:m,n-ip-k+1:n-ip-k+nn_end-1+1,trial),m,x(1:m,n-ip+1:n-ip+nn_end-1+1,trial),m,1,r,m);
            end

            if iwhat==8
                if i<ip
                    nn_beg=ip-i;
                    r(:,:)=DGEMM_symul('N','T',m,m,nn_beg,1,x(1:m,i+k+1:i+k+nn_beg-1+1,trial),m,x(1:m,i+1:i+nn_beg-1+1,trial),m,1,r,m);
                end
                if i~=0
                    nn_end=i;
                    r(:,:)=DGEMM_symul('N','T',m,m,nn_end,1,x(1:m,n-ip+k+1:n-ip+k+nn_end-1+1,trial),m,x(1:m,n-ip+1:n-ip+nn_end-1+1,trial),m,1,r,m);
                end
            end

            if (i==0) && (j>0)
                rright((j-1)*m+1:(j-1)*m+1+m-1,:)=r(:,:);
            end
            if (i>0) && (j>0)
                rleft((j-1)*m+1:(j-1)*m+1+m-1,(i-1)*m+1:(i-1)*m+1+m-1)=r(:,:);
                rleft((i-1)*m+1:(i-1)*m+1+m-1,(j-1)*m+1:(j-1)*m+1+m-1)=r(:,:)';
            end
        end
    end

    for column=1:m
        r(:,column)=rconst(:,column,1);
    end

    nn_end=ip;
    r(:,:)=DGEMM_symul('N','T',m,m,nn_end,1,x(1:m,n-ip+1:n-ip+nn_end-1+1,trial),m,x(1:m,n-ip+1:n-ip+nn_end-1+1,trial),m,1,r,m);
    if iwhat==8
        nn_beg=ip;
        r(:,:)=DGEMM_symul('N','T',m,m,nn_beg,1,x(1:m,1:nn_beg,trial),m,x(1:m,1:nn_beg,trial),m,1,r,m);
    end

    rleft_tot(:,:,trial)=rleft;
    rright_tot(:,:,trial)=rright;
    r_tot(:,:,trial)=r;
end

if iwhat==4
    covscale=1/(n-ip);
elseif iwhat==8
    covscale=1/(2*(n-ip));
end

rleft_tot=covscale*rleft_tot;
rright_tot=covscale*rright_tot;
r_tot=covscale*r_tot;