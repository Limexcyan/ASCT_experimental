function multar1m(mv)
% main decision point after user dialog
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

FORMAT={'float32','int16','int32','float64','ASCII','MAT file'};

mv.opisy={};
global Plev_glb
if ~isempty(Plev_glb)
    plev0=Plev_glb;
else
    if isfield(mv,'plev')
        plev0=[mv.plev*100 95 90 75];   %mw
    else
        plev0=[99 95 90 75];
    end
end
plev1=plev0(mv.siglev);
plev2=[(100-plev1)/2 50 100-(100-plev1)/2];
dat=wczytaj_dane(mv.fname,FORMAT{mv.format},mv.chans,mv.recl,mv.ntrls);
if isempty(dat)
    errordlg('Cannot open input file');
    return
else
    if isempty(mv.chans) mv.chans=size(dat,1); end
    if isempty(mv.recl) mv.recl=size(dat,2); end
    if isempty(mv.ntrls) mv.ntrls=size(dat,3); end
end
if mv.userange && (mv.timerangestart>mv.recl || mv.timerangeend>mv.recl || mv.timerangestart<0 || mv.timerangeend<0)
    h=warndlg({'Time range parameters incorrect','The whole range will be used'},'Warning','modal');
    uiwait(h);
    mv.userange=0;
end
if mv.userange
    if mv.timerangestart == 0; mv.timerangestart=1; end
    dat=dat(:,mv.timerangestart:mv.timerangeend,:);
    mv.recl=mv.timerangeend-mv.timerangestart+1;
end
chnss=getrange(mv.chansel,mv.chans);
mv.chnss=chnss;
opis={};
if ~isempty(mv.descfil)
    fid=fopen(mv.descfil,'rt');
    if fid~=-1
        lin=1;
        oplin=fgetl(fid);
        while ischar(oplin)
            opis{lin}=oplin;
            oplin=fgetl(fid);
            lin=lin+1;
        end
        opis=opis(mv.chnss);
        mv.opisy=opis;
    end
end

dat=dat(chnss,:,:);
mv.chans=size(dat,1);
mv.recl=size(dat,2);
mv.ntrls=size(dat,3);
if ~isfield(mv,'norm0') mv.norm0=1; end
if ~isfield(mv,'norm1') mv.norm1=0; end
if ~isfield(mv,'norm2') mv.norm2=0; end
if mv.norm0
    mnd=mean(dat,2);
    lc=mv.chans;
    for tt=1:mv.ntrls
        for cc=1:lc
            dat(cc,:,tt)=dat(cc,:,tt)-mnd(cc,1,tt);
        end
    end
end
if mv.norm1
    sdd=std(dat,0,2);
    lc=mv.chans;
    for tt=1:mv.ntrls
        for cc=1:lc
            dat(cc,:,tt)=dat(cc,:,tt)/sdd(cc,1,tt);
        end
    end
end
if mv.norm2 
    if mv.ntrls>1
        mnd=mean(dat,3);
        lc=mv.chans;
        for nn=1:mv.recl
            for cc=1:lc
                dat(cc,nn,:)=dat(cc,nn,:)/mnd(cc,nn,:);
            end
        end
    else
        disp('No ensemble mean subtracted - only one trial available.');
    end
end
if mv.pord<1
    mv.pord=estimateModelOrder(dat,mv.method,mv.trial_mode,mv);
end
fnumbs1=getfunccalcnumbers(mv);
fnumbs2=getfuncsavenumbers(mv);
fnumbs=setdiff(union(fnumbs1,fnumbs2),8); % 8 jest dla AR i H 

saveflag=0;
if ~isempty(fnumbs2)
    saveflag=1;
    % savname=[mv.fname '_mout.mat'];
    savname=strrep(mv.fname,'_mltin.mat', '_mltout.mat');
    save(savname,'mv','plev1','plev2');
else
    savname='';
end

wl=mv.winlen;
wn=mv.winnum;
ws=mv.winshf;
emp=[isempty(wl),isempty(ws),isempty(wn)];
if sum(emp)>=2
end

if isempty(wl)
    wl = mv.recl-wn*ws;
    mv.winlen = wl;
elseif isempty(ws)
    ws = floor((mv.recl-wl)/wn);
    mv.winshf = ws;
elseif isempty(wn)
    wn = floor((mv.recl-wl)/ws)+1;
    mv.winnum = wn;
end
if wn<2
end

%if (~isempty(mv.winshf) && mv.winshf>0) || (~isempty(mv.winnum) && mv.winnum>1) % Short-Time
if (ws>0) && (wn>1) % Short-Time
    if mv.baseln
        baselnv=licz_smtmvarBaseln(dat,mv,plev0);
        % funcs chans chans plev wins
        if isempty(baselnv) return; end
        if saveflag saveBaseln(savname,mv,baselnv,fnumbs,fnumbs2,[]); end
        baselnv=baselnv(:,:,:,mv.siglev,:);
    else
        baselnv=[];
    end
    if mv.bootst
        %[sbtfun,ARb,Hb]=licz_smtmvarBoots(dat,mv,plev2);
        [sbtfun,ARs]=licz_smtmvarBoots(dat,mv,plev2);
%         [sbtfun,ARs]=licz_smtmvarBoots_diff2(dat,mv,plev2);
        % chans chans frq funcs plev wins
        if isempty(sbtfun) return; end
        plot_smultBoot_ar(sbtfun,mv,baselnv);
        %if saveflag saveBoots(savname,mv,sbtfun,fnumbs,fnumbs2,ARb,Hb); end
        if saveflag saveBoots(savname,mv,sbtfun,fnumbs,fnumbs2,ARs); end
    else
        %[s,h,a,ARt]=licz_smtmvar(dat,mv);
        [s,h,a,ARs]=licz_smtmvar(dat,mv);
        if isempty(s) return; end
        %plot_smult_ar(s,h,a,mv,baselnv,savname,ARt);
        plot_smult_ar(s,h,a,mv,baselnv,savname,ARs);
    end
else
    if mv.trial_mode  % regular mode trial-by-trial (bootstrap not available)
        hnd=[];
        plot_active=1;
        decision='';
        for trial=1:mv.ntrls
            if plot_active
                if mv.baseln
                    baselnv=licz_mtmvarBaseln(dat(:,:,trial),mv,plev0);
                    % funcs chans chans plev
                    if saveflag saveBaseln(savname,mv,baselnv,fnumbs,fnumbs2,sprintf('_%d',trial)); end
                    baselnv=baselnv(:,:,:,mv.siglev);
                else
                    baselnv=[];
                end
                %[s,h,a,ARt]=licz_mtmvar(dat(:,:,trial),mv);
                [s,h,a,ARs]=licz_mtmvar(dat(:,:,trial),mv);
                %hnd=plot_mult_ar(hnd,s,h,a,mv,trial,mv.ntrls,baselnv,savname,ARt);
                hnd=plot_mult_ar(hnd,s,h,a,mv,trial,mv.ntrls,baselnv,savname,ARs);
                if trial<mv.ntrls decision=advancePlot(trial+1,mv.ntrls); end
            end
            plot_active=~strcmp(decision,'Quit');
        end
    else              % regular mode multitrial
        if ~isempty(mv.winnum) && mv.winnum==1
            if ~isempty(mv.winlen) && mv.winlen>0 && mv.winlen<=mv.recl
                dat=dat(:,1:mv.winlen,:);
                mv.recl=mv.winlen;
            end
        end
        if mv.baseln
            baselnv=licz_mtmvarBaseln(dat,mv,plev0);
            % funcs chans chans plev
            if saveflag saveBaseln(savname,mv,baselnv,fnumbs,fnumbs2,[]); end
            baselnv=baselnv(:,:,:,mv.siglev);
        else
            baselnv=[];
        end
        if mv.bootst
            %[sbtfun,ARb,Hb]=licz_mtmvarBoots(dat,mv,plev2);
            [sbtfun,ARs]=licz_mtmvarBoots(dat,mv,plev2);
%             [sbtfun,ARs]=licz_mtmvarBoots_diff2(dat,mv,plev2);
            % chans chans frq funcs plev
            plot_multBoot_ar(sbtfun,mv,baselnv);
            %if saveflag saveBoots(savname,mv,sbtfun,fnumbs,fnumbs2,ARb,Hb); end
            if saveflag saveBoots(savname,mv,sbtfun,fnumbs,fnumbs2,ARs); end
        else
            %[s,h,a,ARt]=licz_mtmvar(dat,mv);
            [s,h,a,ARs]=licz_mtmvar(dat,mv);
            %plot_mult_ar([],s,h,a,mv,1,1,baselnv,savname,ARt);
            plot_mult_ar([],s,h,a,mv,1,1,baselnv,savname,ARs);
        end
    end
end
