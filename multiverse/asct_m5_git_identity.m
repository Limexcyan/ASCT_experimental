function identity = asct_m5_git_identity(repoRoot)
% Read the exact code revision and dirty state before an M5 run.
root=char(string(repoRoot));
assert(isfolder(root),'ASCT:M5:Repository','Git repository folder does not exist');
q=[char(39) strrep(root,char(39),[char(39) char(34) char(39) char(34) char(39)]) char(39)];
[a,revision]=system(['git -C ' q ' rev-parse HEAD']);
assert(a==0,'ASCT:M5:Repository','Cannot determine Git revision');
[b,dirty]=system(['git -C ' q ' status --porcelain']);
assert(b==0,'ASCT:M5:Repository','Cannot check Git working tree');
identity=struct('gitRevision',strtrim(revision),'gitDirty',~isempty(strtrim(dirty)));
end
