function oord=estimateModelOrder(dat,method,trial_mode)
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

chans=size(dat,1);
npts=size(dat,2);

METHODS=[1,2,4,8];
if nargin<6
    meth_num = 1;
else
    meth_num = METHODS(method);
end

MAXORDER=20;
MAXCRIT=2;
if trial_mode~=0
    dat=squeeze(dat(:,:,1)); % just the first trial
end
CRIT=zeros(MAXCRIT,MAXORDER);
rdmsg_h=waitbar(0,'Estimating criteria...');
for ord=1:MAXORDER
    if meth_num<4
        [rleft,rright,r]=countCorr(dat,ord,meth_num);
    else
        [rleft,rright,r]=countCov(dat,ord,meth_num);
    end
    xres=linsolve(rleft,rright);
    mip=chans*ord;
    Vr=DGEMM_symul('T','N',chans,chans,mip,-1,xres,mip,rright,mip,1,r,chans);

    %CRIT(1,ord)=log(det(Vr))+2*ord*chans/npts; % AIC
    K=ord*chans*chans+chans*(chans-1); %number of estimated parameters (coefs and variance)
    CRIT(1,ord)=log(det(Vr))+2*K/npts; % AIC
    CRIT(2,ord)=det(Vr)*((npts+chans*ord)/(npts-chans*ord))^chans; % FPE
    waitbar(ord/MAXORDER);
end
close(rdmsg_h);
[handle,xOrder]=selOptmalOrder('String','AIC',CRIT,MAXORDER);
oord=cell2mat(xOrder);
