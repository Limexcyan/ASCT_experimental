function fun=licz_mtmvarBaseln(dat,mv,plev)
% estimates baseline for selected functions
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

p=mv.pord;
frqmin=mv.fstart;
frqmax=mv.fend;
fs=mv.fsamp;
method=mv.method;
bootnum=mv.basenum;

chans=size(dat,1);
npts=size(dat,2);
if length(size(dat))>2
    trials=size(dat,3);
else
    trials=1;
end

METHODS=[1,2,4,8];
if nargin<6
    meth_num = 1;
else
    meth_num = METHODS(method);
end

fnumbs=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs,fnumbs2),8); % 8 jest dla AR i H do poprawienia
FUNS=length(fnumbs);
global FVL
global FRQPMAX

fun_tot = zeros(FUNS,chans,chans,FRQPMAX,bootnum);
fun = zeros(FUNS,chans,chans,length(plev));

hnd=waitbar(0,'Calculating baseline...');
dat2=dat;
for boot=1:bootnum
    for ic=1:chans
        for it=1:trials
            dat2(ic,:,it)=dat(ic,randperm(npts),it);
        end
    end
    if meth_num<4
        [rleft,rright,r]=countCorr(dat2,p,meth_num);
    else
        [rleft,rright,r]=countCov(dat2,p,meth_num);
    end

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
        fun_tot(funcnum,:,:,:,boot)=FVL{fnumbs(funcnum)}.f(s0,h0,a0,0);
    end
    waitbar(boot/bootnum);
end
fun(:,:,:,:)=prctile(reshape(fun_tot,[FUNS chans chans FRQPMAX*bootnum]),plev,4);
close(hnd);
