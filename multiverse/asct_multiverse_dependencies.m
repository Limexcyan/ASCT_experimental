function [startStep,graph] = asct_multiverse_dependencies(changes)
%ASCT_MULTIVERSE_DEPENDENCIES Map factor changes to earliest ASCT stage.
% Stage graph follows sc_initAnalysis: 0 -> 8 -> 9 -> 10 -> 11.
% It is deliberately conservative: unknown factors are rejected upstream.
% A change in con.lc affects source reconstruction (STEP9), not only STEP10.
assert(isstruct(changes) && isscalar(changes), ...
    'ASCT:Multiverse:InvalidChanges','changes must be a scalar struct');
graph=struct('stages',[0 8 9 10 11], ...
    'edges',[0 8;8 9;9 10;10 11], ...
    'outputs',{{'6_ICA2','7_SOURCEACT/icloc','7_SOURCEACT/DC*','8_CONN','9_STAT'}});
startStep=10;
if isfield(changes,'filter') && ~isempty(fieldnames(changes.filter))
    startStep=0;
elseif isfield(changes,'loc') && ~isempty(fieldnames(changes.loc))
    startStep=8;
elseif isfield(changes,'con')
    names=fieldnames(changes.con);
    if any(ismember(names,{'decimate','lc','unc'}))
        startStep=9;
    end
end
end
