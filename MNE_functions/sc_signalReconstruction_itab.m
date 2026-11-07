


clear ROI_indiv

for i = 1 : size(ROI_MNI,2)
    
    ROI_indiv{i}.pos = ft_warp_apply( inv(normalise.initial), ft_warp_apply( normalise.params, [ROI_MNI{i}.pos], 'sn2individual' ) );
    ROI_indiv{i}.name = ROI_MNI{i}.name;
    
    %calculating closest point
    distance = [];

    t = 1; %all sources have the same coordinates but different activations | activation refers to activation of each dipole in the grid

%     for j = 1 : length( brain_source(t).pos ) %checking all points
%     distance(j) = sqrt( (brain_source(t).pos(j,1) - ROI_indiv{i}.pos(1,1)).^2 + (brain_source(t).pos(j,2) - ROI_indiv{i}.pos(1,2)).^2 + (brain_source(t).pos(j,3) - ROI_indiv{i}.pos(1,3)).^2 );
%     end
%     
    distance = sqrt( ( brain_source(t).pos(:,1) - ROI_indiv{i}.pos(1,1) ).^2 + ( brain_source(t).pos(:,2) - ROI_indiv{i}.pos(1,2) ).^2 + ( brain_source(t).pos(:,3) - ROI_indiv{i}.pos(1,3) ).^2 );
    
    dist = norm( (brain_source(t).pos - ROI_indiv{i}.pos ).^2 );


    [min_value ROI_indiv{i}.min_index] = min(distance);

    activ = 0;
    for j = 1:length(brain_source)
        
        activ = activ + brain_source(j).avg.mom{ROI_indiv{i}.min_index}';
        
    end
    
    ROI_indiv{i}.activation = activ;
    ROI_indiv{i}.pca = pca(ROI_indiv{i}.activation');  %it is better insted of power since pow is blind for one direction due to cortex deformation
    
end
