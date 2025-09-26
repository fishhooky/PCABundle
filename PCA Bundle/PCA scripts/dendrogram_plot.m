function dendrogram_plot(PCS,variables,scores,testscores,ExtraData,varargin)

% Script to create dendrogram of scores from PCA analysis
% Can use any data loaded as output.scores

% Order of data = training data:test data:Extra data

%% Input variables
% PCS = Output from checkbox figure indicating which scores to use
% variables =
%   1 = reps = number of replicates in training set
%   4 = testreps = number of replicates in test set
%   6 = transparency = toggle whether outputted figure is transparent
%   7/8 = scaling information for extra data
%   9 = MVA = toggle PCA/PLS
% scores = training scores
% testscores = test set scores
% ExtraData = global ExtraData variable
% If varargin is not empty only dendrogram outputs calculated

%% Output variables
% Z = linkage data for dendrogram
% c = dendrogram sample order
% Exports data to global output

%% Setup
MVA = variables(1,9);
global output

PCs=[];
for a=1:size(PCS,1)-5-MVA
    if PCS(size(PCS,1)+1-a).Value==1
        PCs(end+1)=a;
    end
end

values = [];
reps = variables(1,1);
testreps = variables(1,4);
if size(testscores,1)==0
    testreps=0;
end
datasets = floor(size(scores,1)/reps);
transparency = variables(1,6);
MVA = variables(1,9);
cs(1:datasets,3)=0;
for a =0: datasets-1
    cs(a+1,1:3)=colourcalc(a,datasets-1,'Rainbow');
end

if size(varargin,1)==0
    S1=0; % switch for turning off graphing
else
    S1=1;
end

%% Create values

for a = 1:size(PCs,2)
    values(1:datasets*reps,a)=scores(:,PCs(a));
    if testreps>0
        values(datasets*reps+1:datasets*(reps+testreps),a)=testscores(:,PCs(a));
    end
end

%% Add extra data
if PCS(1).Value == 1
    if size(ExtraData,2)>0
        %% Build ExtraData file with selected features
        % Check to ensure ExtraData size is correct
        if size(ExtraData,2)~=size(output.trainingDATA,2)
            for j1=1:size(output.trainingDATA,2)
                ExtraData(:,j1)=ExtraData(:,output.trainingDATA(1,j1));
            end
            ExtraData(:,j1+1:end)=[];
        end
        if variables(7)==1
            scale=output.trainingDATA(3,:);
            offset=output.trainingDATA(2,:);
            if variables(8)==1
                scale=scale.*output.trainingDATA(2,:).^0.5;
            end
        elseif variables(8)==1
            offset=0;
            scale=output.trainingDATA(2,:).^0.5;
        else
            scale=1;
            offset =0;
        end
        if MVA == 0
            Scores=((ExtraData-offset)./scale-output.PCA.mu)*output.PCA.loadings;
        else
            Scores=((ExtraData-offset)./scale-mean(output.trainingDATA(4:end,:),1))*output.PLS.Stats.W*pinv(output.PLS.Loadings'*output.PLS.Stats.W);
        end
        VE=size(values,1);
        for a = 1:size(PCs,2)
            values(VE+1:VE+size(Scores,1),a)=Scores(:,PCs(a));
        end
    end
end

%% Make graph
fig1 = figure;
Z=linkage(pdist(values));
output.dendrogram.linkage=Z;
[a,b,c]=dendrogram(Z,0,'ColorThreshold',0);
for j1 = 1:size(c,2)-1
    v1=c(1,j1);
    v2=c(1,j1+1);
    v3=find(Z(:,1)==v1);
    if size(v3,1)==0
        v3=find(Z(:,2)==v1);
    end
    v4=find(Z(:,1)==v2);
    if size(v4,1)==0
        v4=find(Z(:,2)==v2);
    end
    l1=[];
    l2=[];
    
    if v3==v4 % Calculate separation between all adjacent samples for output
        c(2,j1)=Z(v3,3);
    else
        while size(v3,1)>0
            l1(end+1)=v3;
            v3=find(Z(:,1)==l1(end)+b(end));
            if size(v3,1)==0
                v3=find(Z(:,2)==l1(end)+b(end));
            end
        end
        while size(v4,1)>0
            l2(end+1)=v4;
            v4=find(Z(:,1)==l2(end)+b(end));
            if size(v4,1)==0
                v4=find(Z(:,2)==l2(end)+b(end));
            end
        end
        for j2 = 1:size(l1,2)
            if size(find(l2==l1(j2)),2)>0
                break
            end
        end
        c(2,j1)=Z(l1(j2),3);
    end
    
end
output.dendrogram.order=c;
if S1>0
    close
else
    set(gca,'FontName','Calibri','FontSize',14,'XTick',[]);
    ylabel('Separation')
    for j1=1:size(Z,1) % Colour replicates in the same colour
        if ceil(Z(j1,2)/(reps+testreps)) <= datasets || ceil(Z(j1,1)/(reps+testreps)) <= datasets
            if Z(j1,1)> datasets*reps && Z(j1,1)<= datasets*(reps+testreps) % Selecting for test set data
                a(j1).Color=cs(ceil((Z(j1,1)-datasets*reps)/(testreps)),:);
            elseif Z(j1,2)> datasets*reps && Z(j1,2)<= datasets*(reps+testreps)
                a(j1).Color=cs(ceil((Z(j1,2)-datasets*reps)/(testreps)),:);
            else % Data is from training set
                a(j1).Color=cs(ceil((Z(j1,1))/(reps)),:);
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
            if c(1,j1)>reps*datasets && c(1,j1)<=(testreps+reps)*datasets % Identify test sets
                % Add asterix
                %text(j1-b2/520,b1,'*')
                % Test to see if in first or second column of pair
                rowZ=find(Z(:,1)==c(1,j1));
                if size(rowZ,1)==0
                    rowZ=find(Z(:,2)==c(1,j1));
                end
                % Change line to solid thick line for test data
                if Z(rowZ,1)==c(1,j1)
                    line(a(rowZ).XData(3:4),a(rowZ).YData(3:4),'LineWidth',2,'Color',cs(ceil((c(1,j1)-datasets*reps)/(testreps)),:));
                else
                    line(a(rowZ).XData(1:2),a(rowZ).YData(1:2),'LineWidth',2,'Color',cs(ceil((c(1,j1)-datasets*reps)/(testreps)),:));
                end
            end
        end
    end
    
    % Change position
    set(gcf,'Position',[77,615,1429,363])
    if transparency==1
        set(gcf, 'Color', 'None');
        set(gca, 'Color', 'None');
    end
    
    %% Make transparent
    %set(gcf, 'Color', 'None');
    %set(gca, 'Color', 'None');
end
end