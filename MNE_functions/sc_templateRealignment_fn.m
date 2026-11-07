% provides realigment for electrode corridante system to the MRI template (ACPC system)
% called only for template head/source models and measured electrodes
% FIXME - currently supports only IBB data with Left|Right Ear canals (LEC|REC) as lateral fiducials


function sens_mni = sc_templateRealignment_fn(rc, mriname, infile, chan)

infile_subj = infile(contains(infile, mriname)); % contains all DSes for the current subject. realigment is performed for each DS separately


%%% REALIGNMENT %%%

for ds = 1:length(infile_subj)

    disp('Loading ICA2 data...');
    dsdata = load(char(infile_subj(ds)));

    [di, fi, ~] = fileparts(char(infile_subj(ds)));
    di = strrep(di, '6_ICA2', '7_SOURCEACT');
    dsFolder = fullfile (di, strrep(fi, '_ica2', ''));
    if ~isfolder(dsFolder); mkdir(dsFolder); end

    sensFolder = fullfile (di, 'sensors', strrep(fi, '_ica2', ''));
    if isfield(rc, 'ica2Name')
        sensFolder = strrep(sensFolder, rc.ica2Name, rc.analysisName) ;
    end
    if ~isfolder(sensFolder); mkdir(sensFolder); end


    n_elec = length(chan.elec); %number of electric channels

    labels = dsdata.data_ica2.label(1:length(dsdata.data_ica2.label)-n_elec);

    %     gradfile = strrep(infile, '6_ICA2', '1_PREPROCESSED');
    %     gradfile = strrep(gradfile, '_ica2.', '_grad_ctf.');
    %     tmpl = load(char(gradfile));
    %     grad_ctf = tmpl.grad_ctf;
    %     clear tmpl;

    grad_ctf = dsdata.data_ica2.hdr.grad;

    %sens_ctf = sc_trim_sens(labels, sens_ctf);

    %     nch = length(sens_ctf.label);
    %     sens_ctf.label(nch+1) = {'NAS'};
    %     sens_ctf.label(nch+2) = {'LPA'};  %should be LEC/REC here, but FT accepts more starndard triad (nas.lpa,rpa). this is only about the labels, so no problem
    %     sens_ctf.label(nch+3) = {'RPA'};
    %     sens_ctf.chanori(nch+1,:) = [0, 0, 0];
    %     sens_ctf.chanori(nch+2,:) = [0, 0, 0];
    %     sens_ctf.chanori(nch+3,:) = [0, 0, 0];
    %     sens_ctf.chanpos(nch+1,:) = [10.8423, 0, 0];          %FIXME!!!!! measured values from bc file should be put here
    %     sens_ctf.chanpos(nch+2,:) = [0.600, 8.690, 0];
    %     sens_ctf.chanpos(nch+3,:) = [-0.600, -8.690, 0];
    %     sens_ctf.coilpos(nch+1,:) = [0, 0, 0];%[10.8423, 0, 0];          %FIXME!!!!! measured values from bc file should be put here
    %     sens_ctf.coilpos(nch+2,:) = [0, 0, 0];%[0.600, 8.690, 0];
    %     sens_ctf.coilpos(nch+3,:) = [0, 0, 0];%[-0.600, -8.690, 0];
    %     sens_ctf.chantype(nch+1) = {'fid'}; sens_ctf.chantype(nch+2) = {'fid'}; sens_ctf.chantype(nch+3) = {'fid'};
    %     sens_ctf.elecpos = sens_ctf.chanpos;
    %

    grad_ctf = ft_convert_units(grad_ctf,'mm');

    nas = [108.423, 0, 0];
    lpa = [6, 86.90, 0];
    rpa = [-6, -86.9, 0];
    fid.unit = 'mm';

    fid.chanpos = [nas; lpa; rpa];
    fid.elecpos = [nas; lpa; rpa];
    fid.label = {'NAS', 'LPA', 'RPA'};
    grad_ctf.fid = fid;

    cfg=[];
    cfg.method = 'fiducial';
    cfg.warp = 'traditional';
    cfg.fiducial = {'NAS', 'LPA', 'RPA'};  %should be LEC/REC here, but FT accepts more starndard triad (nas.lpa,rpa). this is only about the labels, so no problem
    cfg.feedback = 'no';
    cfg.target.pos(1,:) = [  0  84 -41];    % location of the nose
    cfg.target.pos(2,:) = [-70 -30 -56];     % location of the left ear
    cfg.target.pos(3,:) = [ 70 -30 -56] ;    % location of the right ear
    cfg.target.label    = {'NAS', 'LPA', 'RPA'};
    grad_mni = sc_ft_gradrealign(cfg, grad_ctf);
    dsdata.data_ica2.hdr.grad = grad_mni;

    %     sens_mni = rmfield(sens_mni, 'elecpos'); %fixes necessity of adding elecpos for ft_alignelectrodes to work
    %     sens_mni.chantype(nch+3) = []; sens_mni.chantype(nch+2) = []; sens_mni.chantype(nch+1) = [];
    %     sens_mni.label(nch+3) = [];    sens_mni.label(nch+2) = [];    sens_mni.label(nch+1) = [];
    %     sens_mni.chanori(nch+3,:) = [];  sens_mni.chanori(nch+2,:) = [];  sens_mni.chanori(nch+1,:) = [];
    %     sens_mni.chanpos(nch+3,:) = [];  sens_mni.chanpos(nch+2,:) = [];  sens_mni.chanpos(nch+1,:) = [];
    %     sens_mni.coilpos(nch+3) = [];  sens_mni.coilpos(nch+2) = [];  sens_mni.coilpos(nch+1) = [];

    save(fullfile(sensFolder, 'grad_mni.mat'), 'grad_mni')

end
end
