function output1 = RecursiveAddition(training,test,trainingSUB,testSUB,R1,R2,PCS,total)
%% Creation of sparse variable set for PCA
% Sequentially adds the number of X-variables within a dataset
% Recursive feature addition
% Optimisation based upon separation of different samples and training and test datasets
% Sample order for training and test sets must be the same
% Different samples in different rows
% Different variables in different columns
% Andrew Hook March 2020

%% Setup
global output temp xVALUES
% Change training and test to optimal variables
data1=[];
t=[];
datasets=size(training,1)/R1;
if R2>0
    for x1=0:datasets-1
        for x2=1:R1
            if output.sampleNUMBERS(1,x2+x1*R1)<=datasets*R1
                data1(end+1,:) = training(output.sampleNUMBERS(1,x2+x1*R1),:);
            else
                data1(end+1,:) = test(output.sampleNUMBERS(1,x2+x1*R1)-datasets*R1,:);
            end
        end
        for x2=1:R2
            if output.sampleNUMBERS(2,x2+x1*R2)>datasets*R1
                t(end+1,:) = test(output.sampleNUMBERS(2,x2+x1*R2)-datasets*R1,:);
            else
                t(end+1,:) = training(output.sampleNUMBERS(2,x2+x1*R2),:);
            end
        end
    end
else
    data1 = training;
end
training = data1;
test=t;

% Apply scaling
if output.variables(7)==1
    training=(data1-mean(data1,1))./std(data1-mean(data1,1),[],1);
    if R2>0
        test=(t-mean(data1,1))./std(data1-mean(data1,1),[],1);
    end
end

% Set initial conditions
if size(training,2)==size(trainingSUB,2)+sum(sum(training==0)==size(training,1))+sum(sum(isnan(training))==size(training,1))
    data1 = training(:,1:3);
    if R2>0
        t= test(:,1:3);
    end
else
    data1 = trainingSUB(4:end,:);
    if R2>0
        t=testSUB;
    end
end


S1 = floor(size(data1,1)/R1); % Number of different sample sets
output1=[];
log1=[];
if output.variables(9)==0 && R1 > 2
    CF = listdlg('PromptString','Select cost function','SelectionMode','single','ListString',{'Maximise Separation','Minimise Overlap','Alternate'}); % select cost function method
else
    CF = 1;
end
if size(CF,1)==0
    return
end
warning('off','stats:pca:ColRankDefX')
if CF == 3
    period = inputdlg('Runs per cycle?','Period');
    period=str2num(period{1});
else
    period=1;
end
if output.variables(9)==0 && CF ~=2
    scaling = questdlg('PCs equally weighted?','Space type','Mahalanobis','Euclidean','Euclidean');
else
    scaling = 'Euclidean';
end
if length(scaling)==0 % Cancel selection
    return
end
% Orbi-filter
if output.variables(11)==1
    fSET = []; % Variable with ranges of masses that need to be filtered
    for x1=1:size(temp.oFILTER,2)
        if temp.oFILTER{1,x1}.Value==1
            fSET(end+1,1)=temp.oFILTER{1,x1}.low;
            fSET(end,2)=temp.oFILTER{1,x1}.high;
        end
    end
    c1=0;
    for x1=1:size(training,2)
        c1 = c1+1;
        c2 = 0;
        for x2=1:size(fSET,1)
            if xVALUES(x1)>fSET(x2,1) && xVALUES(x1)<fSET(x2,2)
                c1=c1-1;
                c2=1;
                break
            end
        end
        if c2 == 0
            training(:,c1)=training(:,x1);
            if R2>0
                test(:,c1)=test(:,x1);
            end
        end
    end
    if x1>c1
        training(:,c1+1:end)=[];
        if R2>0
            test(:,c1+1:end)=[];
        end
        temp.oFILTER{2,1}=x1-c1;
    end
end
%% Optimise 3 starting variables based upon PCs 1 and 2 if no initial data added
if size(training,2)==size(trainingSUB,2)+sum(sum(training==0)==size(training,1))+sum(sum(isnan(training))==size(training,1))
    total = total-3;
    if total < 0
        total = 0;
    end
    
    for x1=1:3
        for x2=3:size(training,2)
            data3=[];
            if size(find(log1==x2),2)==0 && size(find(training(:,x2)>0),1)>0
                if x2>3
                    data1(:,x1)=training(:,x2);
                    if R2>0
                        t(:,x1)=test(:,x2);
                    end
                end
                if output.variables(9)==0
                    [coeff,score,latent,tsquared,explained,mu] = pca(data1);
                    if R2>0
                        TestScores=(t-mu)*coeff;
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
                    
                    % Calculate average score for each sample for each PC
                    data3(3,S1,2)=0;
                    data3(:,:)=0;
                    for x3 = 1:S1
                        for x4 = 1:2
                            data3(1,x3,x4)=mean(score(1+R1*(x3-1):x3*R1,x4));
                        end
                    end
                    
                    % Calculate average distance between samples
                    data4=[];
                    data4(1:S1,1:S1)=0;
                    for x3 = 1:S1
                        for x4 = 1:S1
                            for x5 = 1:2
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
                                for x5 = 1:2
                                    data4(x4)=data4(x4)+abs(TestScores(x4+R2*(x3-1),x5)-data3(1,x3,x5));
                                end
                                %data4(x4)=data4(x4)^0.5;
                            end
                            data3(3,x3,1)=sum(data4);
                            data4(:)=0;
                        end
                        dataX=data3(2:3,1:S1);
                    end
                    % Calculate test score for optimisation
                    data4=[];
                    data4(1:S1,1:S1)=0;
                    if CF==2 % calculation based upon minimising ellipse overlap, if not true will fine average separation of means
                        for x3=1:floor(2/2)
                            data4=[];
                            data4(:,1)=score(:,1+(x3-1)*2);
                            data4(:,2)=score(:,2+(x3-1)*2);
                            Ellipse = GetEllipses(data4,R1); % find ellipses
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
                        end
                    else % measure average separation of means
                        for x3 = 1:S1
                            for x4 = 1:S1
                                for x5 = 1:2
                                    data4(x3,x4)=data4(x3,x4)+abs(data3(1,x3,x5)-data3(1,x4,x5));
                                end
                                %data4(x3,x4)=data4(x3,x4)^0.5;
                            end
                            data3(2,x3,1)=sum(data4(x3,:));
                        end
                    end
                    log2(x2)=sum(data3(2,:,1));
                else % PLS calculation
                    % Filter out Nan or Inf values
                    Ytrain=[];
                    Yt=[];
                    t1=[];
                    for x3=1:size(data1,1)
                        if isnan(temp.Ytraining(x3,1))==0 && isinf(temp.Ytraining(x3,1))==0 
                            Ytrain(end+1,1)=temp.Ytraining(x3,1);
                            data3(end+1,:)=data1(x3,:);
                        end
                    end
                    for x3=1:size(t,1)
                        if isnan(temp.Ytest(x3,1))==0 && isinf(temp.Ytest(x3,1))==0 
                            Yt(end+1,1)=temp.Ytest(x3,1);
                            t1(end+1,:)=t(x3,:);
                        end
                    end    
                    %Do PLS
                    [Xloadings,Yloadings,Xscores,Yscores,betaPLS] = plsregress(data3,Ytrain,1);
                    yfitPLS = [ones(size(data3,1),1) data3]*betaPLS;
                    log2(x2)=1-sum((yfitPLS-Ytrain).^2)/sum((yfitPLS-mean(yfitPLS)).^2);
                end
            end
        end
        % Implement selected ion to initial 3 samples
        data3=find(log2==max(log2(3:end)));
        data1(:,x1)=training(:,data3(1));
        if R2>0
            t(:,x1)=test(:,data3(1));
        end
        log1(end+1)=data3(1);

    end
else
    if output.variables(9)==0
        [coeff,score,latent,tsquared,explained,mu] = pca(data1);
        if R2>0
            TestScores=(t-mu)*coeff;
        end
    end
    log1=trainingSUB(1,:);
end
%% Find benchmark test datapoints

% Calculate number of test datapoint outside 95% confidence limit
if R2>0 && output.variables(9)==0
    data4 =[];data5=[];
    data4=score(:,1);
    data5=TestScores(:,1);
    for x3 = 2 % loop for different PCS
        data4(:,2)=score(:,2);
        data5(:,2)=TestScores(:,2);
        [M1,M2]=GetEllipses(data4,R1,data5,R2);
        dataX(1+x3,1:S1)=transpose(R2-sum(M2,2)); % Add number of points outside confidence limit
    end
end

M2=[];data5=[];
log1(2,1)=0;
%% Loop for removing variables
if size(training,2)==size(trainingSUB,2)+sum(sum(training==0)==size(training,1))+sum(sum(isnan(training))==size(training,1))
    if total>size(training,2)
        total=size(training,2)-3;
    end
else
    if total>size(training,2)-size(trainingSUB,2)
        total=size(training,2)-size(trainingSUB,2);
    end
end
start=size(data1,2);
for x1 = 1:total
    x1
    for x2 = 1:size(training,2)
        if size(find(log1(1,:)==x2),2)==0 && size(find(training(:,x2)>0),1)>0
            data3=[];
            
            % Sequentially select dataset with one more variable
            data1(:,start+x1)=training(:,x2);
            if R2>0
                t(:,start+x1)=test(:,x2);
            end
            
            if output.variables(9)==1
                %Run PLS
                LV=output.variables(2);
                if LV>size(data1,2)
                    LV=size(data1,2)-3;
                end
                % Filter inf and nan
                Ytrain=[];
                Yt=[];
                t1=[];
                for x3=1:size(data1,1)
                    if isnan(temp.Ytraining(x3,1))==0 && isinf(temp.Ytraining(x3,1))==0
                        Ytrain(end+1,1)=temp.Ytraining(x3,1);
                        data3(end+1,:)=data1(x3,:);
                    end
                end
                for x3=1:size(t,1)
                    if isnan(temp.Ytest(x3,1))==0 && isinf(temp.Ytest(x3,1))==0
                        Yt(end+1,1)=temp.Ytest(x3,1);
                        t1(end+1,:)=t(x3,:);
                    end
                end
                %   Combine training and test sets for optimisation
                data3(end+1:end+size(t1,1),:)=t1;
                Ytrain(end+1:end+size(Yt,1),:)=Yt;
                
                % Run PLS
                [Xloadings,Yloadings,Xscores,Yscores,betaPLS] = plsregress(data3,Ytrain,LV);
                yfitPLS = [ones(size(data3,1),1) data3(:,:)]*betaPLS;
                output1(x1,x2)=1-sum((yfitPLS-Ytrain).^2)/sum((yfitPLS-mean(yfitPLS)).^2);
            else
                %Run PCA
                maxPC = max(PCS);
                if maxPC > size(data1,2)-1
                    maxPC = size(data1,2)-1;
                end
                [coeff,score,latent,tsquared,explained,mu] = pca(data1,'NumComponents',maxPC+1);
                %Apply to test dataset
                if R2>0
                    TestScores=(t-mu)*coeff;
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
                PCloop = size(PCS,2);
                if size(score,2)<PCloop
                    PCloop = size(score,2);
                end
                
                % Determine if test set within 95% confidence of training set
                if R2>0
                    data5=score(:,PCS(1));
                    data6=TestScores(:,PCS(1));
                    for x3=2:PCloop
                        data5(:,2)=score(:,PCS(x3));
                        data6(:,2)=TestScores(:,PCS(x3));
                        [M1,M2(1:S1,1+(x3-2)*R2:R2*(x3-1))]=GetEllipses(data5,R1,data6,R2);
                    end
                    
                    % Count number of test datapoints outside confidence limit
                    for x3=1:PCloop-1
                        M2(:,x3)=R2-sum(M2(:,1+R2*(x3-1):R2*x3),2);
                    end
                    M2(:,x3+1:end)=[];
                    M2=transpose(M2); % Transform M2 to allow comparison with dataX
                end
                % Calculate average score for each sample for each PC
                data3(3,S1,PCloop)=0;
                data3(:,:)=0;
                for x3 = 1:S1
                    for x4 = 1:PCloop
                        data3(1,x3,x4)=mean(score(1+R1*(x3-1):x3*R1,PCS(1,x4)));
                    end
                end
                
                % Calculate test score for optimisation
                data4=[];
                data4(1:S1,1:S1)=0;
                if CF == 2 && PCloop>1 && log1(2,end)~=1 || CF ==3 && PCloop>1 && oddeven(ceil(x1/period))==1% calculation based upon minimising ellipse overlap, if not true will fine average separation of means
                    for x3=1:floor(PCloop/2)
                        data4=[];
                        data4(:,1)=score(:,1+(x3-1)*2);
                        data4(:,2)=score(:,2+(x3-1)*2);
                        Ellipse = GetEllipses(data4,R1); % find ellipses
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
                    end
                else % measure average separation of means
                    for x3 = 1:S1
                        for x4 = 1:S1
                            for x5 = 1:PCloop
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
                            for x5 = 1:PCloop
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
                %                 if sum(M2(x3,:))<size(M2,2)-1*(PCloop-1) %Change number here to small substractions to make more robust selection
                %                     data3(2,:,1)=0;
                %                 end
                %             end
                %if sum(sum(M2>dataX(3:end,:)))>PCloop % Checks to see if new model has more test points outside confidence limit than original
                %data3(2,:,1)=0;
                %end
                output1(x1,x2)=sum(data3(2,:,1))/size(find(data3(2,:,1)>0),2);
                % Value based upon % change
                %output1(x1,x2)=sum(sum((data3(2:3,:,1)-dataX)./dataX,2).*[-1;1]);
            end
        end
    end
    % Make and implement decision
    if output.variables(9)==1
        output1(output1==0)=NaN;
    end
    data3=find(output1(x1,:)==max(output1(x1,:)));
    data1(:,end)=training(:,data3(1));
    if R2>0
        t(:,end)=test(:,data3(1));
    end
    log1(1,end+1)=data3(1);
    
    % Log maximum value, maximum separation in output1 right column,
    % minimise overlap in 2nd row of log
    if CF == 2 && PCloop>1 && log1(2,end-1)~=1 || CF ==3 && PCloop>1 && oddeven(ceil(x1/period))==1 || output.variables(9)==1% calculation based upon minimising ellipse overlap, if not true will fine average separation of means
        log1(2,end)=max(output1(x1,:));
    else
        if x1==1
            output1(x1,end+1)=max(output1(x1,:));
        else
            output1(x1,end)=max(output1(x1,:));
        end
    end
    if output.variables(9)==1
        if x1==1
            output1(x1,end+1)=max(output1(x1,:));
        else
            output1(x1,end)=max(output1(x1,:));
        end
    end
    
    %% Find minimise overlap cost function for review only
    
    data3=[];
    
    if R1>2 && output.variables(9)==0
        %Run PCA
        [coeff,score,latent,tsquared,explained,mu] = pca(data1,'NumComponents',maxPC+1);
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
        % Calculate average score for each sample for each PC
        data3(3,S1,PCloop)=0;
        data3(:,:)=0;
        for x3 = 1:S1
            for x4 = 1:PCloop
                data3(1,x3,x4)=mean(score(1+R1*(x3-1):x3*R1,PCS(1,x4)));
            end
        end
        
        % Calculate test score for optimisation
        data4=[];
        data4(1:S1,1:S1)=0;
        if CF == 2 && log1(2,end-1)~=1 || CF == 3 && oddeven(ceil(x1/period))==1
            for x3 = 1:S1
                for x4 = 1:S1
                    for x5 = 1:PCloop
                        data4(x3,x4)=data4(x3,x4)+abs(data3(1,x3,x5)-data3(1,x4,x5));
                    end
                    %data4(x3,x4)=data4(x3,x4)^0.5;
                end
                data3(2,x3,1)=sum(data4(x3,:));
            end
            if x1==1
                output1(x1,end+1)=sum(data3(2,:,1));
            else
                output1(x1,end)=sum(data3(2,:,1));
            end
        else
            if PCloop == 1
                PCloop1=2;
            else
                PCloop1=PCloop;
            end
            for x3=1:floor(PCloop1/2)
                data4=[];
                data4(:,1)=score(:,1+(x3-1)*2);
                data4(:,2)=score(:,2+(x3-1)*2);
                Ellipse = GetEllipses(data4,R1); % find ellipses
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
            end
            log1(2,end)=sum(data3(2,:,1))/size(find(data3(2,:,1)>0),2);
        end
    end
end

%% Review

%output1(:,end+1)=max(output1,[],2);
output1(end+1:end+2,1:size(log1,2))=log1;
warning('on','stats:pca:ColRankDefX')


