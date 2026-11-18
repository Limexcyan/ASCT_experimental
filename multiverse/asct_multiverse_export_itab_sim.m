function path = asct_multiverse_export_itab_sim(sensors,outputDir,baseName)
% Export a synthetic sensor matrix in the `sim` form read by sc_preproc_meg_itab.
% This is a software adapter ONLY; no physical leadfield is implied.
assert(isnumeric(sensors) && ndims(sensors)<=3 && all(isfinite(sensors(:))), ...
    'ASCT:InvalidSignal','Expected finite sensors x samples x trials');
assert(ischar(baseName) && ~isempty(regexp(baseName,'^[a-zA-Z0-9_-]+$','once')), ...
    'ASCT:InvalidName','Use a simple filesystem-safe base name');
if ~isfolder(outputDir), mkdir(outputDir); end
sim=reshape(sensors,size(sensors,1),[]); %#ok<NASGU>
path=fullfile(outputDir,[baseName '_sim.mat']);
save(path,'sim');
end
