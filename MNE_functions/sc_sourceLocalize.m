%%%% SOURCE ANALYSIS FOR MEG/EEG DATA %%%%

function data_icloc = sc_sourceLocalize(rc, infile, chan, scpath, headmodel, sourcemodel, sensors_real, loc)

load(infile);

[~, dsname, ~] = fileparts(infile);
dsname = strrep(dsname, '_ica2', '');
savefolder = fullfile( rc.analysisFolder, '7_SOURCEACT', 'icloc');

if ~isfolder(savefolder); mkdir(savefolder); end

% create a 'timelock' structure
tlck = [];         %TLCK - FieldTrip data format to be re-created

n_elec = length(chan.elec);

switch rc.dataFormat
    case {'itab' 'itab-sim' 'syn-sim'}
        if ~isempty(rc.mriRawFolder) % INDIV models
            tlck.grad = sensors_real;
        else
            error('fixme');
        end
        tlck.label = tlck.grad.label;
        tlck.grad.tra = eye(length(tlck.grad.label));
    case {'bdf', 'eeglab'}
        if isempty(rc.mriRawFolder) % TEMPLATE brain
            % tlck.sens = sc_trim_sens(data_ica2.label(1:length(data_ica2.label)-n_elec), data_ica2.hdr.elec);  %provides labels of chans that survived AR and were used for ICA
            tlck.sens = sc_trim_sens(data_ica2.label(find(strcmp(data_ica2.hdr.actualchantype, 'eeg'))), data_ica2.hdr.elec);  %provides labels of chans that survived AR and were used for ICA
        else  % INDIV models
            tlck.sens = sc_trim_sens(data_ica2.label(find(strcmp(data_ica2.hdr.actualchantype, 'eeg'))), sensors_real);  %provides labels of chans that survived AR and were used for ICA
        end
        tlck.label = tlck.sens.label;    % CHECK ??? maybe unused
    case {'ctf'}
        if isempty(rc.mriRawFolder)
            tmp = load(fullfile( rc.expFolder, rc.analysisName, '7_SOURCEACT', 'sensors', dsname, 'grad_mni.mat'));
            tlck.grad = tmp.grad_mni;   %% ??
        else
            error('FIXME');
        end
        tlck.label = data_ica2.label(1:length(data_ica2.label)-n_elec);
        
end

tlck.time = 1;
tlck.dimord = 'chan_time';

besticdata = data_ica2.ICA.iter(data_ica2.ICA.best_iter.index);   % loading best iter of ICA classificaion

% Prepare the component data in order for ft_sourceanalysis to be able to swallow it
% chan2mne = [find(strcmp(data_ica2.hdr.actualchantype, 'eeg'))' find(strcmp(data_ica2.hdr.actualchantype, 'mag'))'...
%             find(strcmp(data_ica2.hdr.actualchantype, 'meg')) find(strcmp(data_ica2.hdr.actualchantype, 'meggrad'))...
%             find(strcmp(data_ica2.hdr.actualchantype, 'megmag'))];

chan2mne = find(~cellfun(@isempty, regexpi(data_ica2.hdr.actualchantype, 'eeg|mag|meg|grad')));
mixing = besticdata.mixing(1:length(chan2mne),:); %for each type of data it should be adjusted if other channels were used in ICA. it is gonna be either topo or mixing

% tlck.cov = eye(numel(data_ica2.label));
tlck.cov = eye(numel(chan2mne));

% topographies normalisation
for i = 1:size(mixing, 2)
    icscaling(i) = 0.01*max(abs(mixing(:, i)));
    mixing(:, i) = mixing(:, i)/icscaling(i);
end

% REALIGNMENT PLOTS

realfolder = fullfile(strrep(savefolder,'icloc',''), 'realign');
if ~isfolder(realfolder); mkdir (realfolder); end

if rc.eeg
    sc_plot_realign(headmodel, sourcemodel, tlck.sens, fullfile(realfolder, strcat('realignment_', dsname, '.fig')))
else
    sc_plot_realign(headmodel, sourcemodel, tlck.grad, fullfile(realfolder, strcat('realignment_', dsname, '.fig')))
end

% LEADFIELD

if ~isfield(sourcemodel, 'leadfield') || loc.force_lf  % check if leadfield calculation is required
    
    cfg = [];
    switch rc.dataFormat
        case {'bdf', 'eeglab'}
            cfg.elec           = tlck.sens;
            cfg.reducerank = 3;
        case {'itab', 'itab-sim', 'syn-sim'}
            cfg.grad           = tlck.grad;
            cfg.reducerank = 2;
        case 'ctf'
            cfg.grad           = tlck.grad;
            cfg.reducerank = 2;
    end

    if loc.depthWeight
        cfg.normalize     = 'column';
        cfg.normalizeparam = loc.depthWeight;
        disp('enabling depth-weighting MNE...');
    else
        cfg.normalize     = 'no';
    end

    cfg.headmodel      = headmodel;
    cfg.sourcemodel    = sourcemodel;
    sourcemodel  = ft_prepare_leadfield(cfg);
    
    if ~isempty(rc.mriRawFolder)   % individual realistic source/head models
        sourcemodel_indiv_acpc = sourcemodel;
        disp('saving leadfield...');
        save(fullfile(scpath, 'sourcemodel_indiv_acpc.mat'), 'sourcemodel_indiv_acpc');
        clear sourcemodel_indiv_acpc
    end
    
end

% LOCALIZATION; do MNE with different regularisation for each component

cfg               = [];
cfg.method        = loc.method;
cfg.sourcemodel   = sourcemodel;
cfg.headmodel     = headmodel;
cfg.mne.prewhiten = 'yes';
cfg.mne.scalesourcecov = 'yes';
cfg.channel       = chan2mne; % data_ica2.label;

cfg.mne.noisecov  = eye( numel(chan2mne) )*loc.noiseLev;
tlck.cov = cfg.mne.noisecov;

% if loc.deep_weight  % use WMNLS; 
%     lf = cat(2,sourcemodel.leadfield{sourcemodel.inside});   % copied from https://www.fieldtriptoolbox.org/development/project/testing_ft_vs_mne/ however it looks wrong
%     for k = 1:size(lf,2)
%         n(k,1) = norm(lf(:,k));
%     end
%     n = reshape(n,[3 numel(n)/3]);
%     n = sum(n.^2,1);
%     n2 = repmat(n,[3 1]);
%     n2 = n2(:);
%     cfg.mne.sourcecov = spdiags(n2.^-0.5, 0, numel(n2), numel(n2)); % this applies some depth weighting, the way it is described in the MNE manual
% end

if isfield(rc, 'lambdaScan')
if rc.lambdaScan  % lambda estimation mode. run sc_lambdaScan script instead of normal exp analysis
    warning('THIS ANALYSIS RUNS IN A DEV MODE TO ESTIMATE REGULARIZATION PARAMETER !!!')
    sc_lambda_est;
end
end

for i = 1 : size(mixing,2)
    tlck.avg = mixing(:,i);
    if strcmp(loc.norm, 'lambda')  %unitary lambda for all subjects
        cfg.mne.lambda  = loc.lambda;  %either lambda or snr
    end
    if strcmp(loc.norm, 'cov')      %indiv cov matrix
        % estimate noise lev of the current component
        cfg.mne.snr = sqrt( mean( (mixing(:,i) - mean( mixing(:,i) ) ).^2 ) )/loc.noiseLev;
        noisevec(i) = cfg.mne.snr;
    end
    sourceloc(i) = ft_sourceanalysis(cfg, tlck);
end

% add some relevant fields
for i = 1:size(mixing,2)   
    sourceloc(i).icscaling  = icscaling(i);
    sourceloc(i).time = i;
    if strcmp(loc.norm, 'cov')
        sourceloc(i).snr  = noisevec(i);
    end
    if isfield(sourceloc(i),'tri'),            sourceloc(i).tri            = sourceloc(i).tri;            end
    if isfield(sourceloc(i),'brainstructure'), sourceloc(i).brainstructure = sourceloc(i).brainstructure; end
    if isfield(sourceloc(i),'brainstructurelabel'), sourceloc(i).brainstructurelabel = sourceloc(i).brainstructurelabel; end   
end

% choosing only brain components
brain_IC = data_ica2.ICA.iter(data_ica2.ICA.best_iter.index).brain_ic;   %FIXME - cut nonbrain before calculations

data_icloc_tmp = sourceloc(brain_IC);
% data_icloc_tmp = rmfield(data_icloc_tmp,'cfg');
data_icloc = rmfield(data_icloc_tmp,'cfg');


disp(['DS: ' dsname ' - saving ICLOC data']);
if rc.saveCompress
    save( fullfile(savefolder, strcat(dsname, '_icloc.mat')), 'data_icloc');
else
    save( fullfile(savefolder, strcat(dsname, '_icloc.mat')), 'data_icloc', '-v7.3', '-nocompression');
end
end

