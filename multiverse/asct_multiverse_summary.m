function summary = asct_multiverse_summary(results,filename)
% Flat reproducible manifest, one row per specification, for post-hoc checks.
n=numel(results);
row=cell(n,1); scenario=zeros(n,1); analysis=zeros(n,1);
seed=zeros(n,1); status=cell(n,1); message=cell(n,1);
for i=1:n
    row{i}=results(i).id;
    scenario(i)=results(i).config.simulationIndex;
    analysis(i)=results(i).config.analysisIndex;
    seed(i)=results(i).config.simSeed;
    if isfield(results,'status')
        status{i}=results(i).status;
        message{i}=results(i).error;
    else
        status{i}='benchmark';
        message{i}='';
    end
end
summary=table(row,scenario,analysis,seed,status,message, ...
    'VariableNames',{'configuration','simulationIndex','analysisIndex','simSeed','status','error'});
if nargin>=2 && ~isempty(filename)
    writetable(summary,filename);
end
end
