function O1 = VariableOptimisation(training,test,R1,R2,PCS,output9,type)
%% Creation of sparse variable set for PCA
% Removes the number of X-variables within a dataset
% Recursive feature elimination
% Optimisation based upon separation of different samples and training and test datasets
% Sample order for training and test sets must be the same
% Different samples in different rows
% Different variables in different columns
% type = 0 User decides maximisation variable
% type = 1 minimise overlap
% Andrew Hook June 2019

%% Setup
global temp output
data1 = training;
t= test;
warning('off','stats:pca:ColRankDefX')
%R1 = 7; % Number of replicates within training set
%R2 = 3; % Number of replicates within test set
S1 = floor(size(data1,1)/R1); % Number of different sample sets
c1 = 1; % Coefficient for weighting of differences between samples
c2 = 1; % Coefficient for weighting of differences between test and training
%PCS = [1 2]; % Array of principal components of interest
O1=[];

if type == 1
    CF = 3;
elseif R1>2 && output9==0
    CF = listdlg('PromptString','Select cost function','SelectionMode','single','ListString',{'Maximise Separation','Minimise Overlap','Minimise % Overlap','Alternate','Minimise variance'}); % select cost function method
else
    CF = 1;
end
if CF == 4
    period = inputdlg('Runs per cycle?','Period');
    period=str2num(period{1});
else
    period=1;
end
if CF ~=2 && CF ~= 3 && output9==0 && type == 0
    scaling = questdlg('PCs equally weighted?','Space type','Mahalanobis','Euclidean','Euclidean');
else
    scaling = 'Euclidean';
end
PCSv=PCS;
if rem(size(PCS,2),2)==1
    PCSv(end+1)=PCSv(end)+1;
end
%% Calculate values for whole dataset
if output9 ==0
    [coeff,score,latent,tsquared,explained,mu] = pca(data1);
    if R2>0
        TestScores=(t-mu)*coeff;
    end
    % Apply scaling to normalise scores
    if strcmp(scaling,'Mahalanobis')==1
        if R2>0
            TestScores=TestScores-min(score);
            TestScores=TestScores./max(score);
        end
        score=score-min(score);
        score=score./max(score);
    end
    % Calculate average score for each sample for each PC
    data3(3,S1,size(PCS,2))=0;
    data3(:,:)=0;
    for x3 = 1:S1
        for x4 = 1:size(PCS,2)
            data3(1,x3,x4)=mean(score(1+R1*(x3-1):x3*R1,PCS(1,x4)));
        end
    end
    
    % Calculate average distance between samples
    data4=[];
    data4(1:S1,1:S1)=0;
    for x3 = 1:S1
        for x4 = 1:S1
            for x5 = 1:size(PCS,2)
                data4(x3,x4)=data4(x3,x4)+abs(data3(1,x3,x5)-data3(1,x4,x5));
            end
            %data4(x3,x4)=data4(x3,x4)^0.5;
        end
        data3(2,x3,1)=sum(data4(x3,:));
    end
    
    % Calculate average distance between training and test sets
    if R2>0
        data4 = [];
        data4(R2)=0;
        for x3 = 1:S1
            for x4 = 1:R2
                for x5 = 1:size(PCS,2)
                    data4(x4)=data4(x4)+abs(TestScores(x4+R2*(x3-1),x5)-data3(1,x3,x5));
                end
                %data4(x4)=data4(x4)^0.5;
            end
            data3(3,x3,1)=sum(data4);
            data4(:)=0;
        end
        dataX=data3(2:3,1:S1);
        
        % Calculate number of test datapoint outside 95% confidence limit
        data4 =[];data5=[];
        data4=score(:,PCS(1));
        data5=TestScores(:,PCS(1));
        for x3 = 2:size(PCS,2) % loop for different PCS
            data4(:,2)=score(:,PCS(1,x3));
            data5(:,2)=TestScores(:,PCS(1,x3));
            [M1,M2]=GetEllipses(data4,R1,output.variables(12),data5,R2);
            dataX(1+x3,1:S1)=transpose(R2-sum(M2,2)); % Add number of points outside confidence limit
        end
    end
else % Calculate initial PLS values
    % Filter out Nan or Inf values
    Ytrain=[];
    Yt=[];
    t=[];
    data1=[];
    for x3=1:size(training,1)
        if isnan(temp.Ytraining(x3,1))==0 && isinf(temp.Ytraining(x3,1))==0
            Ytrain(end+1,1)=temp.Ytraining(x3,1);
            data1(end+1,:)=training(x3,:);
        end
    end
    for x3=1:size(test,1)
        if isnan(temp.Ytest(x3,1))==0 && isinf(temp.Ytest(x3,1))==0
            Yt(end+1,1)=temp.Ytest(x3,1);
            t(end+1,:)=test(x3,:);
        end
    end
    
    LVs = output.variables(2);
    % Combine training and test for assessment
    data1(end+1:end+size(t,1),:)=t;
    Ytrain(end+1:end+size(Yt,1),:)=Yt;
    
    %     %Do PLS
    %     [Xloadings,Yloadings,Xscores,Yscores,betaPLS] = plsregress(data1,Ytrain,LVs);
    %     yfitPLS = [ones(size(data1,1),1) data1]*betaPLS;
    %     r2=1-sum((yfitPLS-Ytrain).^2)/sum((yfitPLS-mean(yfitPLS)).^2);
end
M2=[];data5=[];
%% Loop for removing variables
for x1 = 1:size(training,2)-3
    
    if size(find(data1(end,:)~=0),2)>3
        for x2 = 1:size(data1,2)
            data3=[];
            if size(find(data1(:,x2)==0),1)~=size(data1,1) % Selection to end analysis early if everything has been nulled
                % Sequentially select dataset with one less variable
                if x2==1
                    data2 = data1(:,2:end);
                    if R2>0
                        t1=t(:,2:end);
                    end
                elseif x2 == size(data1,2)
                    data2 = data1(:,1:end-1);
                    if R2>0
                        t1=t(:,1:end-1);
                    end
                else
                    data2=data1(:,1:x2-1);
                    if R2>0
                        t1=t(:,1:x2-1);
                    end
                    data2(:,x2:size(data1,2)-1)=data1(:,x2+1:end);
                    if R2>0
                        t1(:,x2:size(data1,2)-1)=t(:,x2+1:end);
                    end
                end
                
                if output9 == 0
                    %Run PCA
                    [coeff,score,latent,tsquared,explained,mu] = pca(data2,'NumComponents',max(PCS)+1);
                    %Apply to test dataset
                    if R2>0
                        TestScores=(t1-mu)*coeff;
                    end
                    % Apply scaling to normalise scores
                    if strcmp(scaling,'Mahalanobis')==1
                        if R2>0
                            TestScores=TestScores-min(score);
                        end
                        score=score-min(score);
                        if R2>0
                            TestScores=TestScores./max(score);
                        end
                        score=score./max(score);
                    end
                    % Determine if test set within 95% confidence of training set
                    if R2>0
                        data5=score(:,PCS(1));
                        data6=TestScores(:,PCS(1));
                        M2=[];
                        for x3=2:size(PCS,2)
                            data5(:,2)=score(:,PCS(x3));
                            data6(:,2)=TestScores(:,PCS(x3));
                            [M1,M2(1:S1,1+(x3-2)*R2:R2*(x3-1))]=GetEllipses(data5,R1,output.variables(12),data6,R2);
                        end
                        
                        % Count number of test datapoints outside confidence limit
                        for x3=1:size(PCS,2)-1
                            M2(:,x3)=R2-sum(M2(:,1+R2*(x3-1):R2*x3),2);
                        end
                        M2(:,x3+1:end)=[];
                        M2=transpose(M2); % Transform M2 to allow comparison with dataX
                    end
                    % Calculate average score for each sample for each PC
                    data3(3,S1,size(PCS,2))=0;
                    data3(:,:)=0;
                    for x3 = 1:S1
                        for x4 = 1:size(PCS,2)
                            data3(1,x3,x4)=mean(score(1+R1*(x3-1):x3*R1,PCS(1,x4)));
                        end
                    end
                    
                    % Calculate test score for optimisation
                    
                    if CF > 1 && CF < 4 && size(PCS,2)>1 || CF ==4 && size(PCS,2)>1 && oddeven(ceil(x1/period))==1% calculation based upon minimising ellipse overlap, if not true will fine average separation of means
                        if size(PCS,2) == 3
                            Eloop = 3;
                        else
                            Eloop = ceil(size(PCS,2)/2);
                        end
                        for x3=1:Eloop
                            data4=[];
                            if size(PCS,2) == 3
                                d1=ceil(x3/2);
                                d2=floor(x3/2)+2;
                                data4(:,1)=score(:,PCSv(d1));
                                data4(:,2)=score(:,PCSv(d2));
                            else
                                data4(:,1)=score(:,PCSv(1+(x3-1)*2));
                                data4(:,2)=score(:,PCSv(2+(x3-1)*2));
                            end
                            Ellipse = GetEllipses(data4,R1,output.variables(12)); % find ellipses
                            data5=[];
                            for x4=1:S1 %find max and min coordinates
                                data5(1,x4)=max(Ellipse(:,1+(x4-1)*2)); %max X
                                data5(2,x4)=max(Ellipse(:,x4*2));% max Y
                                data5(3,x4)=min(Ellipse(:,1+(x4-1)*2)); %min X
                                data5(4,x4)=min(Ellipse(:,x4*2)); %min y
                            end
                            maxX=max(data5(1,:));minX=min(data5(3,:));
                            maxY=max(data5(2,:));minY=min(data5(4,:));
                            for x4=1:S1 % transpose data onto range 1 to 100
                                Ellipse(:,1+2*(x4-1))=round((Ellipse(:,1+2*(x4-1))-minX)/(maxX-minX)*99)+1;
                                Ellipse(:,2*x4)=round((Ellipse(:,2*x4)-minY)/(maxY-minY)*99)+1;
                            end
                            data5=zeros(100,100);
                            areas=zeros(S1,2);
                            %                     f1=figure;hold on
                            %                     f2=figure;
                            for x4=1:S1 % mark pixels associated with each ellipse
                                %                         figure(f1);hold on
                                %                         plot(Ellipse(:,1+2*(x4-1)),Ellipse(:,2*x4))
                                Ellipse(:,2*x4)=101-Ellipse(:,2*x4);
                                
                                for x5=min(Ellipse(:,2*x4)):max(Ellipse(:,2*x4))
                                    data6=find(Ellipse(:,2*x4)==x5);
                                    minY=min(Ellipse(data6,1+(x4-1)*2));
                                    maxY=max(Ellipse(data6,1+(x4-1)*2));
                                    if x5 ~= min(Ellipse(:,2*x4)) && x5 ~= max(Ellipse(:,2*x4))
                                        if size(data6,1)==0  %modify if cannot find maxY and minY points
                                            minY=temp1(1);
                                            maxY=temp1(2);
                                        elseif minY==maxY
                                            if abs(minY-temp1(1))>abs(minY-temp1(2))
                                                minY=temp1(1);
                                            else
                                                maxY=temp1(2);
                                            end
                                            
                                        end
                                    end
                                    data5(x5,minY:maxY)=data5(x5,minY:maxY)+1;
                                    % log area of each ellipse
                                    areas(x4,1)=areas(x4,1)+1+maxY-minY;
                                    
                                    temp1(1)=minY;
                                    temp1(2)=maxY;
                                    
                                end
                                %                         figure(f2);imshow(data5)
                            end
                            if CF == 3
                                for x4=1:S1 % mark pixel areas that overlap
                                    for x5=min(Ellipse(:,2*x4)):max(Ellipse(:,2*x4))
                                        data6=find(Ellipse(:,2*x4)==x5);
                                        minY=min(Ellipse(data6,1+(x4-1)*2));
                                        maxY=max(Ellipse(data6,1+(x4-1)*2));
                                        if x5 ~= min(Ellipse(:,2*x4)) && x5 ~= max(Ellipse(:,2*x4))
                                            if size(data6,1)==0  %modify if cannot find maxY and minY points
                                                minY=temp1(1);
                                                maxY=temp1(2);
                                            elseif minY==maxY
                                                if abs(minY-temp1(1))>abs(minY-temp1(2))
                                                    minY=temp1(1);
                                                else
                                                    maxY=temp1(2);
                                                end
                                                
                                            end
                                        end
                                        areas(x4,2)=areas(x4,2)+size(find(data5(x5,minY:maxY)==1),2);
                                        temp1(1)=minY;
                                        temp1(2)=maxY;
                                    end
                                end
                                %                     areas(10,2)=areas(10,2)*5;% Bias sample 10
                                %                     areas(1:3,2)=areas(1:3,2)*3;
                                %                     areas(5,2)=areas(5,2)*3;
                                %                     areas(7,2)=areas(7,2)*3;
                                %data3(2,x3,1)=size(find(data5==1),1)/size(find(data5>1),1); % criteria minimise overlap of ellipses
                                data3(2,x3,1)=mean(areas(:,2)./areas(:,1));% criteria minimise average % overlap of ellipses
                                %                     close(f1)
                                %                     close(f2)
                            else
                                data5=data5.^2;
                                data3(2,x3,1)=1-(sum(data5(data5>1))).^0.5/sum(areas(:,1));
                            end
                        end
                    elseif CF == 5
                        for x3 = 1:S1
                            for x4 = 1:size(PCS,2)
                                data4(x3,x4)=std(score(1+R1*(x3-1):R1*x3,PCS(x4)));
                            end
                        end
                        data3(2,1,1)=1/sum(sum(data4)); % need to invert so can maximise selection
                    else % measure average separation of means
                        data4=[];
                        data4(1:S1,1:S1)=0;
                        for x3 = 1:S1
                            for x4 = 1:S1
                                for x5 = 1:size(PCS,2)
                                    data4(x3,x4)=data4(x3,x4)+abs(data3(1,x3,x5)-data3(1,x4,x5));
                                end
                                %data4(x3,x4)=data4(x3,x4)^0.5;
                            end
                            data3(2,x3,1)=sum(data4(x3,:));
                        end
                    end
                    
                    % Calculate average distance between training and test sets
                    if R2>0
                        data4 = [];
                        data4(R2)=0;
                        for x3 = 1:S1
                            for x4 = 1:R2
                                for x5 = 1:size(PCS,2)
                                    data4(x4)=data4(x4)+abs(TestScores(x4+R2*(x3-1),PCS(x5))-data3(1,x3,x5));
                                end
                                %data4(x4)=data4(x4)^0.5;
                            end
                            data3(3,x3,1)=sum(data4);
                            data4(:)=0;
                        end
                    end
                    
                    % Calculation to make decision on
                    % Value based upon absolute values
                    % Criteria for checking to make sure model is still robust
                    %             for x3=1:size(M2,1)
                    %                 if sum(M2(x3,:))<size(M2,2)-1*(size(PCS,2)-1) %Change number here to small substractions to make more robust selection
                    %                     data3(2,:,1)=0;
                    %                 end
                    %             end
                    if R2>0 && size(PCS,2)>1 && sum(sum(M2>dataX(3:end,:)))>ceil(size(dataX,2)*size(PCS,2)/2) % Checks to see if new model has more test points outside confidence limit than original
                        data3(2,:,1)=0;
                    end
                    O1(x1,x2)=sum(data3(2,:,1))/size(find(data3(2,:,1)>0),2);
                    % Value based upon % change
                    %O1(x1,x2)=sum(sum((data3(2:3,:,1)-dataX)./dataX,2).*[-1;1]);
                else % PLS

                    %Do PLS
                    [Xloadings,Yloadings,Xscores,Yscores,betaPLS] = plsregress(data2,Ytrain,output.variables(2));
                    yfitPLS = [ones(size(data2,1),1) data2]*betaPLS;
                    O1(x1,x2)=1-sum((yfitPLS-Ytrain).^2)/sum((yfitPLS-mean(yfitPLS)).^2);
                end
            else
                O1(x1,x2)=NaN;
            end
        end
        % Make and implement decision
        x1
        if size(find(O1(x1,:)==max(O1(x1,:))),2)>1 % what to do if mulitple variables produce same cost
            data1(:,max(find(O1(x1,:)==max(O1(x1,:)))))=0;
        else
            data1(:,find(O1(x1,:)==max(O1(x1,:))))=0;
        end
    end
end

%% Review
warning('on','stats:pca:ColRankDefX')
O1(:,end+1)=max(O1,[],2);



