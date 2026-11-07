%function [fun,AR_tot,H_tot]=licz_smtmvarBoots(dat,mv,plev)
function [fun,ARs]=licz_smtmvarBoots(dat,mv,plev)
% estimates bootstrapped percentiles for selected functions
% in short-time mode
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

global FRQPMAX

p=mv.pord;
frqmin=mv.fstart;
frqmax=mv.fend;
fs=mv.fsamp;
method=mv.method;
winlen=mv.winlen;
winshf=mv.winshf;
winnum=mv.winnum;
bootnum=mv.bootnum;
bootsiz=mv.bootpool;

chans=size(dat,1);
dlug=size(dat,2);
trials=size(dat,3);

METHODS=[1,2,4,8];
if nargin<6
    meth_num = 1;
else
    meth_num = METHODS(method);
end

if isempty(winlen)
    winlen = dlug-winnum*winshf;
    if winlen<=0
        disp('Illegal window length');
        fun=[]; AR_tot=[]; H_tot=[];
        return
    end
end
if isempty(winshf)
    winshf = floor((dlug-winlen)/winnum);
end
if isempty(winnum)
    winnum = floor((dlug-winlen)/winshf);
    if winnum<=0
        disp('Illegal number of windows');
        fun=[]; AR_tot=[]; H_tot=[];
        return
    end
end
[winlen winshf winnum]

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
if mv.sAR
    AR_tot=zeros(chans,chans,p,length(plev),winnum);
    H_tot=complex(zeros(chans,chans,FRQPMAX,length(plev),winnum));
    V_tot=zeros(chans,chans,length(plev),winnum);
    AR_boot=zeros(chans,chans,p,bootnum);
    H_boot=zeros(chans,chans,FRQPMAX,bootnum);
    V_boot=zeros(chans,chans,bootnum);
else
    AR_tot=[];
    H_tot=[];
    V_tot=[];
end
fun = zeros(chans,chans,FRQPMAX,FUNS,length(plev),winnum);

hnd=waitbar(0,'Processing windows...');
for win=1:winnum
    sstart = (win-1)*winshf;
    if meth_num<4
        [rleft_tot,rright_tot,r_tot]=countCorrSav(dat(:,(sstart+1):(sstart+winlen),:),p,meth_num);
    else
        [rleft_tot,rright_tot,r_tot]=countCovSav(dat(:,(sstart+1):(sstart+winlen),:),p,meth_num);
    end
    
    for boot=1:bootnum
        ix=m_randint(1,bootnum,[1 bootsiz]);
        %ix=randi([1 bootsiz],[1,bootnum]);
        rleft=mean(rleft_tot(:,:,ix),3);
        rright=mean(rright_tot(:,:,ix),3);
        r=mean(r_tot(:,:,ix),3);
        
        xres=linsolve(squeeze(rleft),squeeze(rright));
        mip=chans*p;
        Vr=DGEMM_symul('T','N',chans,chans,mip,-1,xres,mip,rright,mip,1,squeeze(r),chans);
        AR=reshape(xres,[chans p chans]);
        ARr=permute(AR,[3 1 2]);

        [s0,h0,a0]=mult_ar_calc(ARr,Vr,frqmin,frqmax,1./fs);
        for funcnum=1:FUNS
            fun_boot(:,:,:,funcnum,boot)=FVL{fnumbs(funcnum)}.f(s0,h0,a0,0);
        end
        if mv.sAR
            AR_boot(:,:,:,boot)=ARr;
            H_boot(:,:,:,boot)=h0;
            V_boot(:,:,boot)=Vr;
        end
        
        waitbar(((win-1)*bootnum+boot)/winnum/bootnum);
    end
    
    fun(:,:,:,:,:,win)=prctile(fun_boot,plev,5);
    if mv.sAR
        AR_tot(:,:,:,:,win)=prctile(AR_boot,plev,4);
        H_tot(:,:,:,:,win)=prctile(H_boot,plev,4);
        V_tot(:,:,:,win)=prctile(V_boot,plev,4);
    end
    waitbar(win/winnum);
end
close(hnd);
ARs.coefs=AR_tot;
ARs.H=H_tot;
ARs.V=V_tot;