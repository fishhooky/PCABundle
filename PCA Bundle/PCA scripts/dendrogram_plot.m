% Script to create dendrogram of scores from PCA analysis
% Can use any data loaded as output.scores

% PCf = inputdlg({'First','Last'},'Enter PC range', [1 40; 1 40]);
% PCi=str2double(PCf{1});
% PCf=str2double(PCf{2}); % Number of principal components to consider
% PCs = PCf-PCi+1;
Pix_SS = get(0,'screensize'); %Get screen dimensions
fig1 = uifigure('units','pixels','Position',[Pix_SS(1,3)/4,Pix_SS(1,4)/3,50,410]);
global output
if size(output.PCA.latent,1)<20
    b = size(output.PCA.latent,1);
else
    b= 20;
end
for a =1:b
    uicheckbox(fig1,'Text',strcat('PC',num2str(a)),'Position',[10 410-20*a 102 15]);
end
uibutton(fig1,'Text','Graph','Position',[60,220,50,25],'ButtonPushedFcn', @(btnPCA,event) RUN(fig1.Children));
%close(fig1)
function RUN (PCS)
global output

PCs=[];
for a=1:size(PCS,1)-1
    if PCS(size(PCS,1)+1-a).Value==1
        PCs(end+1)=a;
    end
end

values = [];
reps = output.variables(1,1);
testreps = output.variables(1,4);
datasets = floor(size(output.PCA.scores,1)/reps);
cs(1:datasets,3)=0;
for a =0: datasets-1
    cs(a+1,1:3)=colourcalc(a,datasets-1,'Rainbow');
end

%% Create values
for a = 0:datasets-1
    for b=1:size(PCs,2)
        values((reps+testreps)*a+1:(reps+testreps)*a+reps,b)=output.PCA.scores(reps*a+1:reps*a+reps,PCs(b));
        if testreps>0
            values((reps+testreps)*a+reps+1:(reps+testreps)*a+(reps+testreps),b)=output.PCA.TestScores(testreps*a+1:testreps*a+testreps,PCs(b));
        end
    end
end

%% Make graph
figure
Z=linkage(pdist(values));
[a,b,c]=dendrogram(Z,0,'ColorThreshold',0);
set(gca,'FontName','Calibri','FontSize',14,'XTick',[]);
ylabel('Separation')
for j1=1:size(Z,1)
    if ceil(Z(j1,2)/(reps+testreps)) <= datasets || ceil(Z(j1,1)/(reps+testreps)) <= datasets
        if ceil(Z(j1,1)/(reps+testreps))<= datasets
            a(j1).Color=cs(ceil(Z(j1,1)/(reps+testreps)),:);
        else
            a(j1).Color=cs(ceil(Z(j1,2)/(reps+testreps)),:);
        end
        a(j1).LineStyle='-.';
        a(j1).LineWidth=0.5;
    else
        a(j1).Color='k';
    end
end
b2=xlim;
b2=b2(2)-b2(1);
b1 = ylim;
b1=b1(1)-(b1(2)-b1(1))/50;
if testreps>0
    for j1=1:size(c,2) % highlight test data
        if rem(c(1,j1),(reps+testreps))>reps || rem(c(1,j1),(reps+testreps)) == 0 % Identify test sets
            % Add asterix
            %text(j1-b2/520,b1,'*')
            % Test to see if in first or second column of pair
            rowZ=find(Z(:,1)==c(1,j1));
            if size(rowZ,1)==0
                rowZ=find(Z(:,2)==c(1,j1));
            end
            % Change line to solid thick line for test data
            if Z(rowZ,2)==c(1,j1) || Z(rowZ,2) > datasets*(reps+testreps)
                line(a(rowZ).XData(3:4),a(rowZ).YData(3:4),'LineWidth',2,'Color',cs(ceil(c(1,j1)/(reps+testreps)),:));
            else
                line(a(rowZ).XData(1:2),a(rowZ).YData(1:2),'LineWidth',2,'Color',cs(ceil(c(1,j1)/(reps+testreps)),:));
            end
        end
    end
end

% Change position
set(gcf,'Position',[77,615,1429,363])
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end

%% Make transparent
%set(gcf, 'Color', 'None');
%set(gca, 'Color', 'None');

end