% Recursive feature selection using k-means clustering
% Using recursive feature elimination
% Selects data from output.trainingDATA

global output
%% initial setup
N = output.variables(1);
n = (size(output.trainingDATA,1)-3)/N;

X=output.trainingDATA(4:end,:);
logKM=[];
logKM(1:size(X,2),1:2)=0;
    
%% Iterative k-means analysis
for a3 = 1:50 %size(X,2)
a3
Xa = X;
for a2 = 1:size(X,2)
    if size(find(X(:,a2)==0),1)<size(X,1)
        Xa(:,a2)=0;
        KMstart = [];
        for a1=1:n
            KMstart(a1,:)=mean(X(1+N*(a1-1):N*n,:));
        end
        % Do k-means clustering
        
        [idx, C] = kmeans(Xa,n,'MaxIter',100,'Start',KMstart);
        
        % Analysis of clustering
        x1 = 0;
        for a1=1:n
            x1=x1+size(find(idx(1+N*(a1-1):N*a1,1)==mode(idx(1+N*(a1-1):N*a1,1))),1);
        end
        kmOUT(a3,a2)=x1;
        Xa(:,a2)=X(:,a2);
    end
end
    
%% Implement iterative analysis outcome
X(:,find(kmOUT(a3,:)==max(kmOUT(a3,:)),1))=0;
logKM(a3,1)=find(kmOUT(a3,:)==max(kmOUT(a3,:)),1);
logKM(a3,2)=max(kmOUT(a3,:));
end

%% Rebuild X

X=output.trainingDATA(4:end,:);
kmOUT=[];
kmOUT(1,1:100)=0;
for a3=1:max(find(logKM(:,2)==max(logKM(:,2))))
    X(:,logKM(a3,1))=0;
end
 for a3 = 1:100
[idx, C] = kmeans(X,n,'MaxIter',100);
        % Analysis of clustering
        x1 = 0;
        for a1=1:n
            x1=x1+size(find(idx(1+N*(a1-1):N*a1,1)==mode(idx(1+N*(a1-1):N*a1,1))),1);
        end
        kmOUT(a3)=x1;
        if x1 == 96
            X=X;
        end
 end
 plot(kmOUT)