
function [power_distance] = sc_power_distance(x, r)
        
        sgm = r/3;
        power_distance =  1/(sgm * sqrt(2*pi)) * exp(-0.5/sgm^2 * x.^2); 
end


