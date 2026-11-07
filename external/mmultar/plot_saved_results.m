function plot_saved_results(rfilename)
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

dat=zeros(2,2); % to fool the stupid syntax checking
load(rfilename);
vns=whos('-file',rfilename);
nmcn=0;
for i=1:length(vns)
    nm=vns(i).name;
    if (~strcmp(nm,'mv')) && (~strcmp(nm,'plev'))
        nmcn=nmcn+1;
        k=strfind(nm,'_');
        if ~isempty(k) nm=nm(1:(k-1)); end
        nmc{nmcn}=nm;
    end
end
nmcu=unique(nmc);

FVS = { struct('f',@podajSpectrum,'vn','spectrum'),...
        struct('f',@podajCohs,'vn','cohs'),...
        struct('f',@liczDTF,'vn','DTF'),...
        struct('f',@liczNDTF,'vn','NDTF'),...
        struct('f',@liczdDTF,'vn','dDTF'),...
        struct('f',@liczffDTF,'vn','ffDTF'),...
        struct('f',@liczPDC,'vn','PDC'),...
    };

for i=1:length(nmcu)
end

if (~isempty(mv.winshf) && mv.winshf~=0) || (~isempty(mv.winnum) && mv.winnum>1) % Short-Time
    if mv.baseln
        baselnv=licz_smtmvarBaseln(dat,mv,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method,mv.winlen,mv.winshf,mv.winnum,mv.bootnum,plev);
        % funcs chans chans plev wins
    else
        baselnv=[];
    end
    if mv.bootst
        [sbtfun,ARb,Hb]=licz_smtmvarBoots(dat,mv,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method,mv.winlen,mv.winshf,mv.winnum,...
                             mv.bootnum,mv.bootpool,plev);
        % chans chans frq funcs plev wins
        save([mv.fname 'sboot_res.mat'],'sbtfun','plev','mv');
        plot_smultBoot_ar(sbtfun,plev,mv,baselnv);
        if saveflag saveBoots(savname,mv,baseln,fnumbs,fnumbs2,ARb,Hb); end
    else
        [s,h,a,ARt]=licz_smtmvar(dat,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method,mv.winlen,mv.winshf,mv.winnum);
        plot_smult_ar(s,h,a,mv,baselnv,savname,ARt);
    end
else
    if mv.trial_mode  % regular mode trial-by-trial (bootstrap not available)
        hnd=[];
        plot_active=1;
        decision='';
        for trial=1:mv.ntrls
            if mv.baseln
                baselnv=licz_mtmvarBaseln(dat(:,:,trial),mv,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method,mv.bootnum,mv.bootpool,plev);
                % funcs chans chans plev
                if saveflag saveBaseln(savname,mv,baseln,fnumbs,fnumbs2); end
            else
                baselnv=[];
            end
            if plot_active
                [s,h,a,ARt]=licz_mtmvar(dat(:,:,trial),mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method);
                hnd=plot_mult_ar(hnd,s,h,a,mv,trial,mv.ntrls,baselnv,savname,ARt);
                if trial<mv.ntrls decision=advancePlot(trial+1,mv.ntrls); end
            end
            plot_active=~strcmp(decision,'Quit');
        end
    else              % regular mode multitrial
        if mv.baseln
            baselnv=licz_mtmvarBaseln(dat,mv,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method,mv.bootnum,mv.bootpool,plev);
            % funcs chans chans plev
            if saveflag saveBaseln(savname,mv,baseln,fnumbs,fnumbs2); end
        else
            baselnv=[];
        end
        if mv.bootst
            [sbtfun,ARb,Hb]=licz_mtmvarBoots(dat,mv,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method,mv.bootnum,mv.bootpool,plev);
            % chans chans frq funcs plev
            %save([mv.fname 'sboot_res.mat'],'sbtfun','plev','mv');
            plot_multBoot_ar(sbtfun,plev,mv,baselnv);
            if saveflag saveBoots(savname,mv,baseln,fnumbs,fnumbs2,ARb,Hb); end
        else
            %[s,h,a,ARt]=licz_mtmvar(dat,mv.pord,mv.fstart,mv.fend,mv.fsamp,mv.method);
            plot_mult_ar([],s,h,a,mv,1,1,baselnv,savname,ARt);
        end
    end
end
