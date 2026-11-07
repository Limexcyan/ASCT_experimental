%function [s,h,a,ARr]=licz_mtmvar(dat,mv)
function [s,h,a,ARs]=licz_mtmvar(dat,mv)
% estimates AR model parameters and spectrum, model transfer matrix
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

p=mv.pord;
frqmin=mv.fstart;
frqmax=mv.fend;
fs=mv.fsamp;
method=mv.method;

chans=size(dat,1);
% if length(size(dat))>2
%     trials=size(dat,3);
% else
%     trials=1;
% end

METHODS=[1,2,4,8];
if nargin<6
    meth_num = 1;
else
    meth_num = METHODS(method);
end
    
if meth_num<4
    [rleft,rright,r]=countCorr(dat,p,meth_num);
else
    [rleft,rright,r]=countCov(dat,p,meth_num);
end
xres=linsolve(rleft,rright);
mip=chans*p;
Vr=DGEMM_symul('T','N',chans,chans,mip,-1,xres,mip,rright,mip,1,r,chans);
AR=reshape(xres,[chans p chans]);
ARr=permute(AR,[3 1 2]);
ARs.coefs=ARr;
ARs.V=Vr;

if mv.incl_instant
    [ARb0,ARb,Vb]=instant_caus_sub1(ARr,Vr);
    ARs.inst_sub1_coefs=ARb;
    ARs.inst_sub1_V=Vb;
    ARs.inst_sub1_B0=ARb0;
    [s,h,a]=mult_ar_calc(ARb,Vb,frqmin,frqmax,1/fs);
else
    [s,h,a]=mult_ar_calc(ARr,Vr,frqmin,frqmax,1/fs);
end
