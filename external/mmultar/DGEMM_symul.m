function res=DGEMM_symul(transa,transb,m,n,k,alpha,a,lda,b,ldb,beta,c,ldc)
% routine simulating BLAS routine DGEMM
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

a=squeeze(a);
b=squeeze(b);
c=squeeze(c);
%disp(size(a))
%disp(a(:,[1,2,3,end-2:end]))
%disp(size(b))
%disp(b(:,[1,2,3,end-2:end]))
if upper(transa)=='N'
    if upper(transb)=='N'
        res = alpha*a(1:m,1:k)*b(1:k,1:n);
    else
        res = alpha*a(1:m,1:k)*b(1:n,1:k)';
    end
else
    if upper(transb)=='N'
        res = alpha*a(1:k,1:m)'*b(1:k,1:n);
    else
        res = alpha*a(1:k,1:m)'*b(1:n,1:k)';
    end
end

if beta~=0
    res = res+beta*c;
end