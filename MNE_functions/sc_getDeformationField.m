%% Quick SPM Deformation Fields Extractor
% Returns forward (native->MNI) and inverse (MNI->native) deformation fields
% Author: DeepSeek AI
% Date: 2024

function [forward_def, inverse_def] = sc_getDeformationField(t1_file, varargin)

%% Setup
spm('Defaults', 'fMRI');
spm_jobman('initcfg');

% Default parameters
params.template = fullfile(spm('dir'), 'tpm', 'TPM.nii');
params.voxel_size = [1 1 1];
params.bb = [-90 -126 -72; 90 90 108];

% Parse optional parameters
if nargin > 2
    for i = 1:2:length(varargin)
        params.(varargin{i}) = varargin{i+1};
    end
end

%% Run Unified Segmentation (minimal batch)
fprintf('Running SPM segmentation for: %s\n', t1_file);

% Get filename without path and extension
[~, name, ~] = fileparts(t1_file);

% Create batch
clear matlabbatch;

% Segmentation
matlabbatch{1}.spm.spatial.preproc.channel.vols = {[t1_file ',1']};
matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0]; % No bias field save

% Tissue classes (only need first 3 for deformation)
for t = 1:6
    matlabbatch{1}.spm.spatial.preproc.tissue(t).tpm = {[params.template ',' num2str(t)]};
    matlabbatch{1}.spm.spatial.preproc.tissue(t).ngaus = t;
    matlabbatch{1}.spm.spatial.preproc.tissue(t).native = [0 0];
    matlabbatch{1}.spm.spatial.preproc.tissue(t).warped = [0 0];
end

% Only save deformation fields (no tissue maps)
matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1]; % [forward inverse]

% Run segmentation
try
    spm_jobman('run', matlabbatch);
    fprintf('✓ Segmentation complete\n');
catch ME
    error('SPM segmentation failed: %s', ME.message);
end

%% Get deformation field filenames
[filepath, filename] = fileparts(t1_file);

% Expected output files
forward_def = fullfile(filepath, ['y_' filename '.nii']);
inverse_def = fullfile(filepath, ['iy_' filename '.nii']);

% Check if files exist
if ~exist(forward_def, 'file')
    error('Forward deformation field not found: %s', forward_def);
end
if ~exist(inverse_def, 'file')
    error('Inverse deformation field not found: %s', inverse_def);
end

fprintf('✓ Forward deformation: %s\n', forward_def);
fprintf('✓ Inverse deformation: %s\n', inverse_def);

end
