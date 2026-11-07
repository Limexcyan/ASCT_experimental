MULTAR_DEFAULT_VALUES = struct(...
    'fname','','chans',1,'recl',[],'ntrls',1,'fsamp',100,'fstart',0,'fend',50,...
    'pord',5,'method',1,'format',1,'trial_mode',1,...
    'chansel','1-',...
    'descfil','',...
    'winlen',[],'winshf',0,'winnum',[],...
    'norm0',1,'norm1',0,'norm2',0,...
    'baseln',0,'bootst',0,'siglev',3,'basenum',100,'bootpool',200,'bootnum',100,...
    'pDTF',1,'pNDTF',1,'pSpect',1,'pCohs',1,'pdDTF',0,'pPDC',0,'pffDTF',0,...
    'sDTF',1,'sNDTF',1,'sSpect',1,'sCohs',1,'sdDTF',0,'sPDC',0,'sffDTF',0,...
    'sAR',0,'savefigs',0,...
    'userange',0,'timerangestart',0,'timerangeend',0,'pautoflag',0,...
    'incl_instant',0);

MULTAR_FIELD_NAMES = {
    'fname','chans','recl','ntrls','fsamp','fstart','fend','pord','method','format',...
    'trial_mode','chansel','descfil','winlen','winshf','winnum','norm0','norm1','norm2',...
    'baseln','bootst','siglev','basenum','bootpool','bootnum','pDTF','pNDTF','pSpect','pCohs',...
    'pdDTF','pPDC','pffDTF','sDTF','sNDTF','sSpect','sCohs','sdDTF','sPDC','sffDTF','sAR',...
    'savefigs','userange','timerangestart','timerangeend','pautoflag','incl_instant'};

filename='m:\Data\CAT2\outfin\params_set.mat';
load('-mat',filename);

for i=[1,13,2:10,14:16,11,12,17:length(MULTAR_FIELD_NAMES)]
    if isfield(mv,MULTAR_FIELD_NAMES{i})
        F=getfield(mv,MULTAR_FIELD_NAMES{i});
    else
        F=getfield(MULTAR_DEFAULT_VALUES,MULTAR_FIELD_NAMES{i});
    end
    switch i
        case 1
            outs=['"' F '"'];
        case {12,13}
            outp=['"' F '"'];
        case {2,3,4,14,15,16}
            if isempty(F)
                outp='';
            else
                outp=num2str(F);
            end
        case {26,27,28,29,30,31,32} % plot flags
            outp='0';
        case 33
            outp='*';
        otherwise
            outp=num2str(F);
    end
    if i~=1
        outs=[outs ',' outp];
    end
end

disp(outs);
    