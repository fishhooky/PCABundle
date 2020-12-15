function y = oddeven(x)
% identifes whether number is odd or even
% accepts integers. If non-integer is added will round
% outputs 0 = even, 1 = odd

x=round(x,0);
y=rem(x,2);