% reads sensors from the 1_PREPROCESSED directory, where sens.mat file is
% saved during preprocessing.
% usage:
% sc_readSensors(rc)
% sc_readSensors(rc, labels) - to trim sensors according to labels

function sens_origpos = sc_readSensors(rc, varargin)

if ~isempty(varargin); labels = varargin{1}; end

if ~isempty(rc.elecRealPos)  %digitized electrodes
    tmpdata = load(fullfile(rc.expFolder, rc.elecRealPos, strcat(mriname,'.mat')));
    sens_origpos = tmpdata.elec;
else  % no digitized electrodes
    if ~isfield(rc, 'sensMatFile')  % sensor description NOT provided in exernal file - use 10-20 standard
        if rc.usePrevFolder == 0   % we the current analysis folder
            tmpdata = load(fullfile(rc.analysisName, '1_PREPROCESSED/', 'sensors.mat'));
        else  % we are now forking, so use the previous folder
            tmpdata = load(fullfile(rc.prevFolder, '1_PREPROCESSED/', 'sensors.mat'));
        end
    else  % sensor description read from external file
        tmpdata = load(fullfile(rc.prevFolder, rc.sensMatFile));
    end
end
sens_origpos = tmpdata.sens;
if exist('labels')
    sens_origpos = sc_trim_sens(labels, sens_origpos);  %MNI coords
end

sens_origpos = ft_convert_units(sens_origpos,'mm'); % should be the same unit as MRI

end


