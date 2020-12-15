%% Script to produce graph showing CF for recursive feature sparse model result
% Runs from global output
% Andrew Hook April 2020

h=figure;
grid on
grid minor
hold on
xset=1:size(output.rOUTPUT,1)-1-2*output.rOUTPUT(1,end);
if output.rOUTPUT(1,end) == 0
    xset=size(output.rOUTPUT,1)-xset+2;
end
if output.rOUTPUT(1,end) == 1
yyaxis left
end
plot(xset,output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))
if output.rOUTPUT(1,end) == 1
    ylabel('Separation')
    yyaxis right
    plot(xset,output.rOUTPUT(end,size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+1:size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+size(xset,2)))
else
    if max(output.rOUTPUT(:,end))>1
        ylabel('Separation')
    else
        ylabel('Mean area fraction not overlapping')
    end
end

set(gca,'FontName','Calibri','FontSize',14);
xlabel('# variables')
if output.rOUTPUT(1,end) == 1
    ylabel('Mean area fraction not overlapping')
end