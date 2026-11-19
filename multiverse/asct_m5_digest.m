function hex = asct_m5_digest(value)
% SHA-256 over a file or stable JSON representation of a MATLAB struct.
% Requires sha256sum (Linux) or shasum (macOS), no Java runtime dependency.
if isstruct(value)
    encoded=jsonencode(canonical(value));
    p=[tempname '.json'];
    f=fopen(p,'w');
    assert(f>0,'ASCT:M5:WriteFailed','Cannot create temporary fingerprint file');
    c=onCleanup(@() deleteIfExists(p));
    n=fwrite(f,unicode2native(encoded,'UTF-8'),'uint8');
    fclose(f);
    assert(n==numel(unicode2native(encoded,'UTF-8')),'ASCT:M5:WriteFailed','Incomplete fingerprint input');
elseif ischar(value) || (isstring(value) && isscalar(value))
    p=char(value);
    assert(isfile(p),'ASCT:M5:MissingFile','File not found: %s',p);
else
    error('ASCT:M5:BadDigestInput','Hash input must be a struct or a filename');
end
if isfile('/usr/bin/sha256sum') || ~isunix
    command=['sha256sum ' shellQuote(p)];
else
    command=['shasum -a 256 ' shellQuote(p)];
end
[status,msg]=system(command);
assert(status==0,'ASCT:M5:HashFailed','Cannot hash %s: %s',p,msg);
tok=regexp(strtrim(msg),'^[0-9a-fA-F]{64}','match','once');
assert(~isempty(tok),'ASCT:M5:HashFailed','Hash output did not contain SHA-256');
hex=lower(tok);
end
function s=canonical(s)
if isstruct(s)
    s=orderfields(s);
    fields=fieldnames(s);
    for i=1:numel(s)
        for k=1:numel(fields)
            key=fields{k}; s(i).(key)=canonical(s(i).(key));
        end
    end
elseif iscell(s)
    for i=1:numel(s), s{i}=canonical(s{i}); end
end
end
function q=shellQuote(s)
% Use single quotes, escaping any embedded quote.
q=[char(39) strrep(s,char(39),[char(39) char(34) char(39) char(34) char(39)]) char(39)];
end
function deleteIfExists(p)
if isfile(p), delete(p); end
end
