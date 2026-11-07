%indiv = ft_warp_apply(inv(normalise.cfg.final), template_grid_MNI.pos); %works fairly well MNI->indiv

ROI_MNI = [20,10,90];

ROI_MNI = template_grid_MNI.pos(:,:);
ROI_indiv = ft_warp_apply(inv(normalise.cfg.final), [ROI_MNI]);

ROI_indiv = ft_warp_apply(inv(normalise.initial), ft_warp_apply(normalise.params, [ROI_MNI], 'sn2individual'));

distance = [];

t =1;

for i = 1 : length(source(t).pos)
    
    distance(i) = sqrt( (source(t).pos(i,1) - ROI_indiv(1,1)).^2 + (source(t).pos(i,2) - ROI_indiv(1,2)).^2 + (source(t).pos(i,3) - ROI_indiv(1,3)).^2 );
    
end

dist = norm( (source(t).pos - ROI_indiv) .^ 2)

[min_value ROI_index] = min(distance);


