function a = OutlierDetection(output,ReplicateNumbers,PC1,PC2)
%% Script to identify outliers in datasets
% Needs variable = ReplicateNumbers that species replicates for each sample


%% Outlier detection
a=[];
v1=0;
while v1==0
    v1=1;
    for x1 = 1:size(ReplicateNumbers,1)
        data=[];
        if x1 == 1
            data=output.PCA.ExtraDataScores(1:ReplicateNumbers(x1,1),PC1);
            data(:,2)=output.PCA.ExtraDataScores(1:ReplicateNumbers(x1,1),PC2);
        else
            data=output.PCA.ExtraDataScores(1+sum(ReplicateNumbers(1:x1-1,1)):sum(ReplicateNumbers(1:x1,1)),PC1);
            data(:,2)=output.PCA.ExtraDataScores(1+sum(ReplicateNumbers(1:x1-1,1)):sum(ReplicateNumbers(1:x1,1)),PC2);
        end
        % remove pre-identifed outliers
        c1 = 0;
        c2=0;
        if size(a,1)>=x1
            for x2 = 1:size(a,2)
                if a(x1,x2)>0
                    if a(x1,x2)-c2 == 1
                        data=data(2:end,:);
                    elseif a(x1,x2)-c2 == size(data,1)
                        data(end,:)=[];
                    else
                        data(a(x1,x2)-c2:end-1,:)=data(a(x1,x2)+1-c2:end,:);
                        data(end,:)=[];
                    end
                    c2 = c2+1;
                end
            end
        end
        % Cluster analysis
        %     Z=linkage(pdist(data));
        %     f1=figure;
        %     dendrogram(Z,0,'ColorThreshold',0);
        %     f2 = figure;
        %     scatter(data(:,1),data(:,2))
        %     uiwait(msgbox('Continue?'))
        %     close(f1)
        %     close(f2)
        % Outlier detection based upon outside 95% confidence ellipse
        
        for x2 = 1:ReplicateNumbers(x1,1)-c2
            test=data(x2-c1,:);
            if x2-c1 ==1
                training=data(2:end,:);
            elseif x2 ==ReplicateNumbers(x1,1)-c2
                training=data(1:end-1,:);
            else
                training=data(1:x2-1-c1,:);
                training(x2-c1:ReplicateNumbers(x1,1)-1-c1-c2,:)=data(x2+1-c1:end,:);
            end
            %x2
            [Coordinates,logicTEST]=GetEllipses(training,ReplicateNumbers(x1,1)-1-c1-c2,test,1);
            if logicTEST == 0
                v1=0;
                if x2 == 1
                    data=data(2:end,:);
                elseif x2 == ReplicateNumbers(x1,1)-c2
                    data(end,:)=[];
                else
                    data(x2-c1:end-1,:)=data(x2+1-c1:end,:);
                    data(end,:)=[];
                end
                c1=c1+1;
                if c2>0
                    v2 = x2+size(find(a(x1,1:size(find(a(x1,:)>0),2))<=x2),2)-c1+1; %Add in outliers already removed
                    v3 = size(find(a(x1,:)>v2),2); % number of outliers already detect bigger than new outlier
                    v4 = size(find(a(x1,:)<v2),2)-size(find(a(x1,:)==0),2);
                    a(x1,v4+2:v4+v3+1)=a(x1,v4+1:v4+v3);
                    a(x1,v4+1)=v2;
                else
                    a(x1,c1)=x2;
                end
            end
        end
    end
end