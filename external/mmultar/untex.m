function ustr=untex(str)

ustr=str;
ik=strfind(ustr,'_');
for i=length(ik):-1:1
    p=ik(i);
    ustr=[ustr(1:p-1) '\' ustr(p:end)];
end

ik=strfind(ustr,'^');
for i=length(ik):-1:1
    p=ik(i);
    ustr=[ustr(1:p-1) '\' ustr(p:end)];
end