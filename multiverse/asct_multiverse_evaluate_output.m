function evaluation = asct_multiverse_evaluate_output(analysisFolder,conName,truth)
% Evaluate actual multar NDTF files against an EXPLICIT ROI-aligned truth.
% truth(target,source) must use the SAME ROI ordering as con.chanSel.
assert(islogical(truth) || isnumeric(truth),'ASCT:InvalidTruth','Truth must be an adjacency matrix');
assert(size(truth,1)==size(truth,2),'ASCT:InvalidTruth','Truth must be square');
base=fullfile(analysisFolder,'8_CONN',conName);
files=dir(fullfile(base,'**','*_mltout.mat'));
files=files(~contains({files.name},'_stat_')); % bootstrap-only files lack point NDTF
assert(~isempty(files),'ASCT:MissingMultarOutput','No multar output found in %s',base);
entry=repmat(struct('file','','f1',NaN,'precision',NaN,'recall',NaN, ...
    'falsePositiveRate',NaN,'hasBootstrap',false),numel(files),1);
for k=1:numel(files)
    f=fullfile(files(k).folder,files(k).name);
    d=load(f,'NDTF','NDTF_boot');
    assert(isfield(d,'NDTF') && size(d.NDTF,1)==size(truth,1) && ...
        size(d.NDTF,2)==size(truth,2),'ASCT:InvalidMultarOutput', ...
        'Missing NDTF or incompatible truth ROI mapping: %s',f);
    estimate=d.NDTF;
    if ndims(estimate)>3
        estimate=mean(estimate,4); % explicitly average sliding windows
    end
    score=asct_multiverse_score(estimate,truth);
    entry(k).file=f;
    entry(k).f1=score.f1;
    entry(k).precision=score.precision;
    entry(k).recall=score.recall;
    entry(k).falsePositiveRate=score.falsePositiveRate;
    entry(k).hasBootstrap=isfield(d,'NDTF_boot');
end
evaluation.files=entry;
evaluation.meanF1=mean([entry.f1]);
evaluation.meanPrecision=mean([entry.precision]);
evaluation.meanRecall=mean([entry.recall]);
end
