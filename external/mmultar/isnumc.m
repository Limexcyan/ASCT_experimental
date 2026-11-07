function lv=isnumc(c)
% true if argument is a decimal number character
% (C) Maciej Kaminski 2012 (GPLv3 http://www.gnu.org/licenses/gpl-3.0.txt)

lv=ischar(c) & (c>='0') & (c<='9');
