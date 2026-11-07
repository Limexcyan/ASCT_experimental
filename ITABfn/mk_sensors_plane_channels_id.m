   
function [loc_phys]=mk_sensors_plane_channels_id(sensors,lr,ud,ch_id);

   
   [ns,ndum]=size(sensors);
     s2d=sensor3d2sensor2d(sensors,lr,ud);   
   
%    figure;
%    for i=1:ns;
%        text(s2d(i,1),s2d(i,2),num2str(ch_id(i)));
%    end
%    axis([-.6 .6 -.6 .6]);  

   loc_phys=locphys2locphys_ch_id([[1:ns]',s2d],ch_id);
   return;