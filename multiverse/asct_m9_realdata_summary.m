function summary = asct_m9_realdata_summary(multiverseRoot)
%ASCT_M9_REALDATA_SUMMARY Read-only descriptive summary of STEP10 outputs.
% Existing variants are NOT independent bootstrap replicates. Real EEG has
% no known directed ground truth: F1, ROC, true-positive and lag error are
% deliberately NOT calculated. Failed/incomplete variants are excluded
% by asct_m8_conn_audit; inspect the original manifest separately.
report=asct_m8_conn_audit(multiverseRoot);
columns={'configId','analysisName','nROIs','varNorm'};
[firstRow,~,rowIndex]=asct_m9_group_rows(report,columns);
n=numel(firstRow);
summary=report(firstRow,columns);
summary.nFiles=zeros(n,1);
summary.nStable=zeros(n,1);
summary.fractionStable=NaN(n,1);
summary.nLabelsVerified=zeros(n,1);
summary.maxSpectralRadius=NaN(n,1);
summary.minResidualCovEigenvalue=NaN(n,1);
for k=1:n
    ix=rowIndex{k};
    summary.nFiles(k)=numel(ix);
    summary.nStable(k)=nnz(report.stableVAR(ix));
    summary.fractionStable(k)=mean(report.stableVAR(ix));
    summary.nLabelsVerified(k)=nnz(report.labelsVerified(ix));
    summary.maxSpectralRadius(k)=max(report.spectralRadius(ix));
    summary.minResidualCovEigenvalue(k)=min(report.minCovEigenvalue(ix));
end
end
