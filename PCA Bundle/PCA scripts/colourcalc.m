function y=colourcalc(var,max,colourscheme)
% Take variable and output RGB colour
% var and max should be single values
% colourscheme refers to field names in base variable ColourScheme
% colourscheme is a string, use ''
% By Andrew Hook 2018

%% Input colour scheme and find RGB
load('ColourScheme.mat');
if strcmp(colourscheme,'r') == 1
    colourscheme = 'BlackToRed';
elseif strcmp(colourscheme,'b') == 1
    colourscheme = 'BlackToBlue';
elseif strcmp(colourscheme,'g') == 1
    colourscheme = 'BlackToGreen';
elseif strcmp(colourscheme,'y') == 1
    colourscheme = 'BlackToYellow';
elseif strcmp(colourscheme,'m') == 1
    colourscheme = 'BlackToMagenta';
elseif strcmp(colourscheme,'c') == 1
    colourscheme = 'BlackToCyan';
elseif strcmp(colourscheme,'k') == 1 || strcmp(colourscheme,'w') == 1
    colourscheme = 'BlackToWhite';
end
C=getfield(ColourScheme,colourscheme);
y=[((cos(C(1)*pi*var/max+C(2)*pi)+1)/C(3))^C(4),((cos(C(5)*pi*var/max+C(6)*pi)+1)/C(7))^C(8),((cos(C(9)*pi*var/max+C(10)*pi)+1)/C(11))^C(12)];