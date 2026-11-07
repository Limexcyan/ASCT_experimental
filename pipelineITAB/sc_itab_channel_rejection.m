cfg = [];
cfg.dataset = filename; %filename is passed to the function in each loop
hdr = ft_read_header( filename_hdr ); %reading master header file of the subject
% hdr = ft_read_header( 'ccrmhl93_0209.raw.mhd' ); %reading master header file of the subject

bad_channel = find( [hdr.orig.ch.flag]==1 ); %reading bad channels spotted by chieti team
good_channel = setdiff( find([hdr.orig.ch.type]==2), bad_channel); %rading good channels
cfg.channel = [hdr.label(good_channel)]; 
cfg.continuous = 'yes'; 
data = ft_preprocessing(cfg);

cfg             = [];
cfg.hpfilter    = 'yes';     % enables high-pass filtering
cfg.HPfreq      = 1;       % sets up the frequency for high-pass filter        
cfg.lpfilter    = 'yes';     % enables low-pass filtering
cfg.LPfreq      = 150;        % sets up the frequency for low-pass filter
cfg.plotfiltresp  = 'no';
      
data_meg  = ft_preprocessing(cfg, data); %preprcesses the data

% rejection of channels which exceed the given z_value threshold
var_g = [];
var_g = var( data_meg.trial{1,1}, 0, 2 ); %variance along second dimension which is time

s_g =[];
s_g = std(var_g); %calculates standard deviation from variations of each gradiometer

z_val_g = []; %here standarised values (z_values) of each gradiometer will be kept
z_val_g = var_g./s_g;

ch_rej = []; %an array that keep gradiometers which z_value exceeds given threshold

ch_rej = find( [z_val_g] >= ar.ch_z_value_th ); %finds all gradiometers which z_val is higher than ch_z_balue_th  






if 1   %plot ch variances
z_val_g_sorted = sort( z_val_g, 1 ,'descend' );
    figure('NumberTitle', 'on', 'Name', ['grad variance sorted - DS: ' , num2str(ds) ]);
        hold on;
        plot(z_val_g_sorted(:,ds));
        legend('original', 'EOG-corrected');

end

% cfg = [];
% cfg.channel = 'MAG_054';  %channel 100 = MAG_099
% figure; ft_singleplotER(cfg,data_meg);

