function XYZ_out = sc_appyDeformation(defField, XYZ_in)
% APPLY_SPM_DEFORMATION_TO_COORDS
%
% Applies an SPM deformation field (y_*.nii) to point coordinates
% such as electrode positions.
%
% INPUTS:
%   defField : path to SPM deformation field (y_*.nii)
%   XYZ_in   : Nx3 matrix of coordinates [x y z] in mm
%
% OUTPUT:
%   XYZ_out  : Nx3 matrix of transformed coordinates
%
% Requires SPM12

    if size(XYZ_in,2) ~= 3
        error('XYZ_in must be an Nx3 matrix');
    end

    % Load deformation field
    def = nifti(defField);
    Y = def.dat(:,:,:,:,:);   % deformation field data

    % Load deformation field space
    M = def.mat;

    % Convert world (mm) coordinates to voxel coordinates
    XYZ_vox = (M \ [XYZ_in ones(size(XYZ_in,1),1)]')';
    XYZ_vox = XYZ_vox(:,1:3);

    % Interpolate deformation field at electrode locations
    defX = spm_sample_vol(Y(:,:,:,1), XYZ_vox(:,1), XYZ_vox(:,2), XYZ_vox(:,3), 1);
    defY = spm_sample_vol(Y(:,:,:,2), XYZ_vox(:,1), XYZ_vox(:,2), XYZ_vox(:,3), 1);
    defZ = spm_sample_vol(Y(:,:,:,3), XYZ_vox(:,1), XYZ_vox(:,2), XYZ_vox(:,3), 1);

    % Output coordinates
    XYZ_out = [defX defY defZ];
end
