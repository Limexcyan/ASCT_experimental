%function [fun,AR_tot,H_tot]=licz_mtmvarBoots(dat,mv,plev)
function [fun,ARs]=licz_mtmvarBoots(dat,mv,plev)
% calculates bootstraped percentiles for selected functions
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

p=mv.pord;
frqmin=mv.fstart;
frqmax=mv.fend;
fs=mv.fsamp;
method=mv.method;
bootnum=mv.bootnum;
bootsiz=mv.bootpool;
            
chans=size(dat,1);
if length(size(dat))>2
    trials=size(dat,3);
else
    trials=1;
end
if trials==1
    errordlg('Only one trial available for bootstrap');
    fun=[];
    return
end

METHODS=[1,2,4,8];
if nargin<6
    meth_num = 1;
else
    meth_num = METHODS(method);
end

global FRQPMAX
if bootsiz>trials
    bootsiz=trials;
    disp(sprintf('Bootsrap pool size changed to %d',bootsiz));
    %mv.bootpool=bootsiz;
end

fnumbs=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);
global FVL
fun_boot = zeros(chans,chans,FRQPMAX,FUNS,bootnum);
fun = zeros(chans,chans,FRQPMAX,FUNS,length(plev));
if mv.sAR
    AR_tot=zeros(chans,chans,p,length(plev));
    H_tot=complex(zeros(chans,chans,FRQPMAX,length(plev)));
    V_tot=zeros(chans,chans,length(plev));
    AR_boot=zeros(chans,chans,p,bootnum);
    H_boot=zeros(chans,chans,FRQPMAX,bootnum);
    V_boot=zeros(chans,chans,bootnum);
else
    AR_tot=[];
    H_tot=[];
    V_tot=[];
end


if meth_num<4
    [rleft_tot,rright_tot,r_tot]=countCorrSav(dat,p,meth_num);
else
    [rleft_tot,rright_tot,r_tot]=countCovSav(dat,p,meth_num);
end
hnd=waitbar(0,'Calculating bootstrap...');
for boot=1:bootnum
    ix=m_randint(1,bootnum,[1 bootsiz]);
    %ix=randi([1 bootsiz],[1,bootnum]);
    rleft=mean(rleft_tot(:,:,ix),3);
    rright=mean(rright_tot(:,:,ix),3);
    r=mean(r_tot(:,:,ix),3);

    xres=linsolve(rleft,rright);
    mip=chans*p;
    Vr=DGEMM_symul('T','N',chans,chans,mip,-1,xres,mip,rright,mip,1,r,chans);
    AR=reshape(xres,[chans p chans]);
    ARr=permute(AR,[3 1 2]);

    if mv.incl_instant
        [ARb0,ARb,Vb]=instant_caus_sub1(ARr,Vr);
        [s0,h0,a0]=mult_ar_calc(ARb,Vb,frqmin,frqmax,1/fs);
    else
        [s0,h0,a0]=mult_ar_calc(ARr,Vr,frqmin,frqmax,1/fs);
    end
    for funcnum=1:FUNS
        fun_boot(:,:,:,funcnum,boot)=FVL{fnumbs(funcnum)}.f(s0,h0,a0,0);
    end
    if mv.sAR
        H_boot(:,:,:,boot)=h0;
        if mv.incl_instant
            AR_boot(:,:,:,boot)=ARb;
            V_boot(:,:,boot)=Vb;
        else
            AR_boot(:,:,:,boot)=ARr;
            V_boot(:,:,boot)=Vr;
        end
    end
    waitbar(boot/bootnum);
end
fun(:,:,:,:,:)=prctile(fun_boot,plev,5);
if mv.sAR
    AR_tot=prctile(AR_boot,plev,4);
    H_tot=prctile(H_boot,plev,4);
    V_tot=prctile(V_boot,plev,4);
end
close(hnd);
ARs.coefs=AR_tot;
ARs.H=H_tot;
ARs.V=V_tot;