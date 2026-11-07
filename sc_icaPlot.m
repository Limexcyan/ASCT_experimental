function sc_icaPlot(Moving_Average_2,sig,F,spectr,sig_corr,probab,eye_peaks,component,ncond,seg,chan,event,ica_par,avg_factor,i,nIC,trim_folder)
    %%%  A plot that draws IC component with their Topolot, Timecourse, PSD and ERPs
    % Inputs that are absoluteluy necessery for it to function
    % - Moving_Average_2 - is a slice of ERP average for a given component
    % - sig              - is a signal of IC component 
    % - F                - is a Frequency timecourse for PSD of IC
    % - spectr           - is a PSD for a given IC
    % - sig_corr         - is a signal correlation with ELC channel for current IC
    % - probab           - is a brain signal probability for current IC estimated by model 
    % - eye_peaks        - is a number of peaks in IC signal 
    % - component        - is a Mixing matrix of a current IC
    % - ncond            - number of conditions
    % - seg              - is standard ASCT structure for Segmentation parameters
    % - chan             - standad ASCT structure for Channel parameters
    % - event            - standad ASCT structure for Event parameters
    % - ica_par          - standad ASCT structure for ICA parameters
    % - avg_factor       - factor on which Signal is averaged to form ERP
    % - i                - current component number
    % - nIC              - number of All IC 
    % - trim_folder       - Folder in which we can find ch_trimmed.elc


    % ~ MD 
    subplot(2,2,4),  %ERP/ERF (only for RS 
    if ~strcmp(seg.studyType , 'RS')
        plot(linspace(event(1).t_pre/1000,event(1).t_post/1000,length(Moving_Average_2/ncond)),movmean(Moving_Average_2/ncond,avg_factor));
        xline(0,'color','#D95319','LineWidth', 2)
        axis( [event(1).t_pre/1000 event(1).t_post/1000 1.1*min(min(Moving_Average_2/ncond)) 1.1*max(max(Moving_Average_2/ncond)) ]);
        title('ERP/ERF','FontSize',10); xlabel('ms');
    end

    subplot(2,5,1:3),   %timecourse
    [tp, sp] = sc_minmaxDecimate(ica_par.time_ica, sig, 4000);
    plot(tp, sp);
    axis tight; title('time course','FontSize',10); xlabel('s');

    
    subplot(2,2,3),   %power
    plot(F,spectr,'r');
    axis([ 0  min(100,ica_par.filter.freq_high) 0 1.1*max(spectr) ]); 
    title('power spectrum','FontSize',10); xlabel('Hz');

    subplot(2,5,4:5)
    axis off  % text only, no axes
    cla reset;

    text(-0.5,-0.6,strcat('ELC correlation:  ',{'     '}, num2str(sig_corr,'%4.2f')),'FontSize', 10,'fontweight','bold'),
    text(-0.5,-0.7,strcat('Brain Sign prob:  ',{'     '}, num2str(probab,'%4.2f')),'FontSize', 10,'fontweight','bold'),
    text(-0.5,-0.8,strcat('Peaks per minute: ',{'  '}, num2str(eye_peaks,'%4.2f')),'FontSize', 10,'fontweight','bold'),
    topoplot(component, fullfile(char(trim_folder),'ch_trimmed.elc'), 'nosedir', chan.ori,'verbose','off','style' , 'map','headrad' ,0, 'electrodes', 'labels');
    title(strcat({'IC'},num2str(i),' [/',num2str(nIC),']'),'FontSize',10);


      function [td, yd] = sc_minmaxDecimate(t, y, nOut)
          y = y(:)'; t = t(:)';  L = numel(y);  nb = floor(nOut/2);
          if L <= nOut, td = t; yd = y; return; end
          k = floor(L/nb);  n = k*nb;
          Y = reshape(y(1:n), k, nb);  Tm = reshape(t(1:n), k, nb);
          [mn, imn] = min(Y, [], 1);  [mx, imx] = max(Y, [], 1);
          sw = imn > imx;                                   % keep time order inside each bin
          v = [mn; mx];  v(:,sw) = [mx(sw); mn(sw)];
          r = [imn; imx]; r(:,sw) = [imx(sw); imn(sw)];
          tt = Tm(sub2ind(size(Tm), r, repmat(1:nb, 2, 1)));
          yd = [v(:)' y(n+1:end)];  td = [tt(:)' t(n+1:end)];
      end
    

end