%just a fragment of the script 


A = ICA.iteration(ICA.best_iter.index).mixing;
    g_ic = ICA.iteration(ICA.best_iter.index).brain_ic;
    Nc = ICA.iteration(ICA.best_iter.index).total_ic_number;
    Fs = header.smpfq;
   
    dec = ica_par.dec_fact;
    Fsnew = Fs/dec;
    IC2 = ICA.best_iter.IC;
    ntptdata=header.ntpdata;

...
%remove the artifact components

for i=1:roi_num  %Dx Dy Dz are the maps in the source space

            sigx=Dx(index(i),:)*IC2;
            sigy=Dy(index(i),:)*IC2;
            sigz=Dz(index(i),:)*IC2;
end
