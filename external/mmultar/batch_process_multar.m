%cmdfile='wlosi_lista.txt';
cmdfile='files_to_process.txt';


% MULTAR_DEFAULT_VALUES = struct(...
%     'fname','','chans',1,'recl',[],'ntrls',1,'fsamp',100,'fstart',0,'fend',50,...
%     'pord',5,'method',1,'format',1,'trial_mode',1,...
%     'chansel','1-',...
%     'descfil','',...
%     'winlen',[],'winshf',0,'winnum',[],...
%     'norm0',1,'norm1',0,'norm2',0,...
%     'baseln',0,'bootst',0,'siglev',3,'basenum',100,'bootpool',200,'bootnum',100,...
%     'pDTF',1,'pNDTF',1,'pSpect',1,'pCohs',1,'pdDTF',0,'pPDC',0,'pffDTF',0,...
%     'sDTF',1,'sNDTF',1,'sSpect',1,'sCohs',1,'sdDTF',0,'sPDC',0,'sffDTF',0,...
%     'sAR',0,'savefigs',0,...
%     'userange',0,'timerangestart',0,'timerangeend',0,'pautoflag',0);
% FORMAT={'float32','int16','int32','float64','ASCII','MAT file'};
global FRQPMAX % number of points in frequency domain
global FVL FVS
FRQPMAX = 100;
FVL = { struct('f',@liczSpectrum,'sx','_spec','tt','Power spectrum','hn','pSpect'),...
        struct('f',@liczCohs,'sx','_cohs','tt','Coherences','hn','pCohs'),...
        struct('f',@liczDTF,'sx','_DTF','tt','Normalized DTF','hn','pDTF'),...
        struct('f',@liczNDTF,'sx','_NDTF','tt','Non-normalized DTF','hn','pNDTF'),...
        struct('f',@liczdDTF,'sx','_dDTF','tt','Direct DTF','hn','pdDTF'),...
        struct('f',@liczPDC,'sx','_PDC','tt','Partial directed coherence','hn','pPDC'),...
        struct('f',@liczffDTF,'sx','_ffDTF','tt','Full frequency DTF','hn','pffDTF'),...
    };
FVS = { struct('f',@podajSpectrum,'vn','spectrum'),...
        struct('f',@podajCohs,'vn','cohs'),...
        struct('f',@liczDTF,'vn','DTF'),...
        struct('f',@liczNDTF,'vn','NDTF'),...
        struct('f',@liczdDTF,'vn','dDTF'),...
        struct('f',@liczPDC,'vn','PDC'),...
        struct('f',@liczffDTF,'vn','ffDTF'),...
        struct('f',@podajAR,'vn','AR_A_H'),...
    };

fid=fopen(cmdfile,'rt');
if fid~=0
    % 1:filename 2:desc_filename 3:chans 4:recl 5:ntrls
    % 6:fsamp 7:fstart 8:fend 9:pord 10:method
    % 11:format 12:winlen 13:winshf 14:winnum 15:trial_mode
    % 16:chansel 17:norm0 18:norm1 19:norm2 20:baseln
    % 21:bootst 22:siglev 23:basenum 24:bootpool 25:bootnum
    % 26:pDTF 27:pNDTF 28:pSpect 29:pCohs 30:pdDTF
    % 31: pPDC 32:pffDTF 33:sDTF 34:sNDTF 35:sSpect
    % 36:sCohs 37:sdDTF 38:sPDC 39:sffDTF 40:sAR
    % 41:savefigs 42:userange 43:timerangestart
    % 44:timerangeend 45:pautoflag
    Cinfo = textscan(fid,'%q%q%f%f%f%f%f%f%f%d%d%f%f%f%d%q%d%d%d%d%d%d%f%f%f%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d%d',...
        'Delimiter',',','EmptyValue',0,'CommentStyle','%');
    fclose(fid);
    dlugosc=size(Cinfo{3},1);
    for plik=1:dlugosc
        mv.fname=Cinfo{1}{plik};
        mv.descfil=Cinfo{2}{plik};
        mv.chans=Cinfo{3}(plik);
        mv.recl=Cinfo{4}(plik);
        mv.ntrls=Cinfo{5}(plik);
        mv.fsamp=Cinfo{6}(plik);
        mv.fstart=Cinfo{7}(plik);
        mv.fend=Cinfo{8}(plik);
        mv.pord=Cinfo{9}(plik);
        mv.method=Cinfo{10}(plik);
        mv.format=Cinfo{11}(plik);
        mv.winlen=Cinfo{12}(plik);
        mv.winshf=Cinfo{13}(plik);
        mv.winnum=Cinfo{14}(plik);
        if mv.chans==0 mv.chans=[]; end
        if mv.recl==0  mv.recl=[];  end
        if mv.ntrls==0 mv.ntrls=[]; end
        if isnumeric(mv.descfil) mv.descfil=''; end
        if mv.winnum==0 mv.winnum=[]; end
        if mv.winlen==0 mv.winlen=[]; end
        mv.trial_mode=Cinfo{15}(plik);
        mv.chansel=Cinfo{16}(plik);
        mv.chansel=mv.chansel{1};
        mv.norm0=Cinfo{17}(plik);
        mv.norm1=Cinfo{18}(plik);
        mv.norm2=Cinfo{19}(plik);
        mv.baseln=Cinfo{20}(plik);
        mv.bootst=Cinfo{21}(plik);
        mv.siglev=Cinfo{22}(plik);
        mv.basenum=Cinfo{23}(plik);
        mv.bootpool=Cinfo{24}(plik);
        mv.bootnum=Cinfo{25}(plik);
        mv.pDTF=Cinfo{26}(plik);
        mv.pNDTF=Cinfo{27}(plik);
        mv.pSpect=Cinfo{28}(plik);
        mv.pCohs=Cinfo{29}(plik);
        mv.pdDTF=Cinfo{30}(plik);
        mv.pPDC=Cinfo{31}(plik);
        mv.pffDTF=Cinfo{32}(plik);
        mv.sDTF=Cinfo{33}(plik);
        mv.sNDTF=Cinfo{34}(plik);
        mv.sSpect=Cinfo{35}(plik);
        mv.sCohs=Cinfo{36}(plik);
        mv.sdDTF=Cinfo{37}(plik);
        mv.sPDC=Cinfo{38}(plik);
        mv.sffDTF=Cinfo{39}(plik);
        mv.sAR=Cinfo{40}(plik);
        mv.savefigs=Cinfo{41}(plik);
        mv.userange=Cinfo{42}(plik);
        mv.timerangestart=Cinfo{43}(plik);
        mv.timerangeend=Cinfo{44}(plik);
        mv.pautoflag=Cinfo{45}(plik);
        mv.incl_instant=Cinfo{46}(plik);
        
        multar1m(mv);
        close all hidden
    end
end