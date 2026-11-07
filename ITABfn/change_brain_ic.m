   function ICA_in = change_brain_ic(ICA_in,list_in,flag)
   

   id = ICA_in.best_iter.index;
   list_ic = ICA_in.iteration(id).brain_ic;
   
   if(strcmp(flag,'ADD'))
       list_new = [list_ic  list_in];
       list_new= sort(list_new);
       ICA_in.iteration(id).brain_ic = list_new;
       ICA_in.iteration(id).brain_ic_number = length(list_new);
   elseif(strcmp(flag,'REMOVE'))
       list_new = setdiff(list_ic,list_in);
       ICA_in.iteration(id).brain_ic = list_new;
       ICA_in.iteration(id).brain_ic_number = length(list_new);
   end
   
   
   