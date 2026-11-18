function [mltin,mv] = asct_multiverse_prepare_mltin(mltin,mv)
% Optional per-run ERP removal and automatic MVAR-order selection for multar.
% Called AFTER ASCT has set mv.recl / mv.chans and mv time range.
if ~isfield(mv,'removeERP'), mv.removeERP=false; end
if mv.removeERP
    mltin = asct_remove_erp(mltin,mv.recl);
end
if isfield(mv,'orderSelection') && strcmp(mv.orderSelection,'aic')
    assert(isfield(mv,'maxMvarOrder'),'ASCT:MissingMaxOrder','maxMvarOrder is required for AIC');
    chans=getrange(mv.chansel,size(mltin,1));
    assert(~isempty(chans) && all(chans>=1) && all(chans<=size(mltin,1)), ...
        'ASCT:InvalidROI','Selected ROIs outside signal range');
    samples=reshape(mltin(chans,:),numel(chans),mv.recl,[]);
    if isfield(mv,'userange') && mv.userange
        assert(mv.timerangestart>=1 && mv.timerangeend<=mv.recl && ...
            mv.timerangeend>mv.timerangestart,'ASCT:InvalidTimeRange', 'Invalid MVAR range');
        samples=samples(:,mv.timerangestart:mv.timerangeend,:);
    end
    if isfield(mv,'norm0') && mv.norm0
        samples=bsxfun(@minus,samples,mean(samples,2));
    end
    if isfield(mv,'norm1') && mv.norm1
        scale=std(samples,0,2);
        assert(all(scale(:)>0),'ASCT:ZeroVariance','Cannot normalize constant ROI');
        samples=bsxfun(@rdivide,samples,scale);
    end
    mv.pord=asct_mvar_aic(samples,mv.maxMvarOrder);
end
end
