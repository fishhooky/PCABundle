function log1 = LoopRFA_RFE(pcs,total,minVAR,loops)
%% Repeat RFA/RFE loops
% Runs repeat loops of RFA/RFE, selecting max separation each time
% Optimises test set between loops
% Number PC = number of principal components to include in optimistion
% total = total number of features to add in each loop for RFA
% minVAR = minimum number of features a model can be reduced to
% loops = total number of optimisation loops
% Andrew Hook April 2024

global output training test
%NumberPC = 2;
% pcs=[];
% for x1=1:NumberPC
%     pcs(end+1)=x1;
% end
log1=[];
%total = 20;
%minVAR = 10;
%loops = 20;

for a = 1:loops
    log1(a,1)=size(output.trainingDATA,2);
    output.rOUTPUT=RecursiveAddition(training,test,output.trainingDATA,output.testDATA,output.variables(1,1),output.variables(1,4),pcs,total,2);
    output.rOUTPUT(2:end+1,:)=output.rOUTPUT;
    output.rOUTPUT(1,1:end-1)=1:size(output.rOUTPUT,2)-1;
    
    % Apply RCA outputs
    autoREDUCE_Implement(total)
    output.trainingDATA(isnan(output.trainingDATA)==1)=0;
    output.testDATA(isnan(output.testDATA)==1)=0;
    
    pcaRUN
    % RFE
    output.rOUTPUT=VariableOptimisation(output.trainingDATA(4:end,:),output.testDATA,output.variables(1,1),output.variables(1,4),pcs,output.variables(9),1);
    output.rOUTPUT(1,end)=0;
    output.rOUTPUT(2:end+1,:)=output.rOUTPUT;
    output.rOUTPUT(1,1:end-1)=output.trainingDATA(1,:);
    
    
    %output.trainingDATA=temp.modifier;
    %output.testDATA=temp.test;
    xset=1:size(output.rOUTPUT,1)-1-2*output.rOUTPUT(1,end);
    xset=size(output.rOUTPUT,1)-xset+2;
    yset=output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)';
    p=polyfit(xset(2:end),yset(2:end),2);
    % Set value is maximum of minimised overlap curve
    x = xset(find(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)==max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))));
    % Set value is from apex of quadratic fit
    %x = floor(-p(2)/2/p(1));
    try
    if x < xset(find(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)==max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)))) || x > size(output.rOUTPUT,1)-1 % Change x if x selected is out of range
        x = xset(find(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)==max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))));
    end
    catch
        x=x;
    end
    
    % Apply minimum variable amount
    if x < minVAR
        x = minVAR;
    end
    autoREDUCE_Implement(x)
    
    log1(a,3)=xset(find(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)==max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))));
    log1(a,4)=max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end));
    log1(a,5)=x;
    log1(a,6)=p(1)*x^2+p(2)*x+p(3);
    log1(a,7:6+size(output.trainingDATA,2))=output.trainingDATA(1,:);
    output.trainingDATA(isnan(output.trainingDATA)==1)=0;
    output.testDATA(isnan(output.testDATA)==1)=0;
    
    pcaRUN
    
    optimiseTT
    log1(a,2)=size(output.trainingDATA,2);
end

msgbox('Mission accomplished')
end
function autoREDUCE_Implement(x)
global output training test
% Change to make sure selected number of variables is within limits
var=size(output.rOUTPUT,2)-1;
if output.rOUTPUT(1,end)==0 % action if used recursive feature elimination
    if x<sum(sum(isnan(output.rOUTPUT),2)==size(output.rOUTPUT,2))+3 %Ensure value not below minimum
        x=sum(sum(isnan(output.rOUTPUT),2)==size(output.rOUTPUT,2))+3;
    elseif x>var
        x=var;
    end
    row=size(output.rOUTPUT,1)-x+3;
    if size(output.trainingDATA,2)~=var % what to do if auto reduce is first past
        % Build t1 and t2
        datasets=size(training,1)/output.variables(1);
        R1 = output.variables(1);
        R2 = output.variables(4);
        t1=[];
        t2=[];
        for x1=0:datasets-1
            for x3=1:size(output.rOUTPUT,2)-1
                for x2=1:R1
                    if output.sampleNUMBERS(1,x2+x1*R1)<=datasets*R1
                        t1(x2+R1*x1,x3) = training(output.sampleNUMBERS(1,x2+x1*R1),output.rOUTPUT(1,x3));
                    else
                        t1(x2+R1*x1,x3) = test(output.sampleNUMBERS(1,x2+x1*R1)-datasets*R1,output.rOUTPUT(1,x3));
                    end
                end
                for x2=1:R2
                    if output.sampleNUMBERS(2,x2+x1*R2)>datasets*R1
                        t2(x2+R2*x1,x3) = test(output.sampleNUMBERS(2,x2+x1*R2)-datasets*R1,output.rOUTPUT(1,x3));
                    else
                        t2(x2+R2*x1,x3) = training(output.sampleNUMBERS(2,x2+x1*R2),output.rOUTPUT(1,x3));
                    end
                end
            end
        end
        t1(4:end+3,:)=t1;
        t1(1,:)=output.rOUTPUT(1,1:end-1);
        t1(2,:)=mean(t1(4:end,:),1);
        t1(3,:)=std(t1(4:end,:)-t1(2,:),[],1);
        if output.variables(7)==1 % apply variance scaling
            t1(4:end,:)=(t1(4:end,:)-t1(2,:))./t1(3,:);
            if size(output.testDATA,1)>0
                t2=(t2-t1(2,:))./t1(3,:);
            end
        end
        if output.variables(8)==1 % apply square mean scaling
            t1(4:end,:)=t1(4:end,:)./t1(2,:).^0.5;
            if size(output.testDATA,1)>0
                t2=t2./t1(2,:).^0.5;
            end
        end
    else
        t1=output.trainingDATA;
        t2=output.testDATA;
    end
    output.trainingDATA=[];
    output.testDATA=[];
    for a =1:var
        if isnan(output.rOUTPUT(row+1,a))==0
            output.trainingDATA(:,end+1)=t1(:,a);
            if size(test,1)>0
                output.testDATA(:,end+1)=t2(:,a);
            end
        end
    end
    
else % action if used recursive feature addition
    if x>size(find(output.rOUTPUT(end,:)~=0),2) %Ensure value within limits
        x=size(find(output.rOUTPUT(end,:)>0),2);
    end
    
    % Build t1 and t2
    datasets=size(training,1)/output.variables(1);
    R1 = output.variables(1);
    R2 = output.variables(4);
    t1=[];
    t2=[];
    for x1=0:datasets-1
        for x2=1:R1
            if output.sampleNUMBERS(1,x2+x1*R1)<=datasets*R1
                t1(end+1,:) = training(output.sampleNUMBERS(1,x2+x1*R1),:);
            else
                t1(end+1,:) = test(output.sampleNUMBERS(1,x2+x1*R1)-datasets*R1,:);
            end
        end
        for x2=1:R2
            if output.sampleNUMBERS(2,x2+x1*R2)>datasets*R1
                t2(end+1,:) = test(output.sampleNUMBERS(2,x2+x1*R2)-datasets*R1,:);
            else
                t2(end+1,:) = training(output.sampleNUMBERS(2,x2+x1*R2),:);
            end
        end
    end
    t1(4:end+3,:)=t1;
    t1(1,:)=1:size(t1,2);
    t1(2,:)=mean(t1(4:end,:),1);
    t1(3,:)=std(t1(4:end,:)-t1(2,:),[],1);
    if output.variables(7)==1 % apply variance scaling
        t1(4:end,:)=(t1(4:end,:)-t1(2,:))./t1(3,:);
        if size(output.testDATA,1)>0
            t2=(t2-t1(2,:))./t1(3,:);
        end
    end
    if output.variables(8)==1 % apply square mean scaling
        t1(4:end,:)=t1(4:end,:)./t1(2,:).^0.5;
        if size(output.testDATA,1)>0
            t2=t2./t1(2,:).^0.5;
        end
    end
    
    output.trainingDATA=[];
    output.testDATA=[];
    for a =1:x+size(find(output.rOUTPUT(end-1,:)~=0),2)-size(find(output.rOUTPUT(end,:)~=0),2)
        output.trainingDATA(:,end+1)=t1(:,output.rOUTPUT(end-1,a));
        if R2>0
            output.testDATA(:,end+1)=t2(:,output.rOUTPUT(end-1,a));
        end
    end
    
end
end

function optimiseTT
global output training
if size(output.trainingDATA,2)<size(training,2) && output.variables(9)==2 % Warning if wish to optimise using PLS readout. Currently turned off as optimisation is through PCA
    c1=questdlg('Optimising training set after generating a sparse dataset may result in overfitting. Continue?',...
        'Over-fitting query',...
        'Yes','Cancel','Cancel');
    if strcmp(c1,'Yes')==1
        c1=1;
    else
        c1=0;
    end
else
    c1=1;
end
if c1==1
    R1 = output.variables(1); % training set replicates
    R2 = output.variables(4); % test set replicates
    PC1 = output.variables(2); % PC of interest
    PC2 = output.variables(3); % PC of interest
    if output.variables(9)==1
        PC1=1;
        PC2=2;
    end
    if size(output.testDATA,1)==0 || R2==0 && output.variables(9)==0
        msgbox('Add test data and number of test replicates')
    else
        if isfield(output,'sampleNUMBERS')==0 % produce reference numbers so that the different samples being used can be tracked
            output.sampleNUMBERS=1:size(output.trainingDATA,1)-3;
            output.sampleNUMBERS(2,1:size(output.testDATA,1))=size(output.trainingDATA,1)-3+1:size(output.trainingDATA,1)-3+size(output.testDATA,1);
        end
        
        datasets = floor((size(output.trainingDATA,1)-3)/R1);
        CO=output.variables(5); % Collective optimisation
        looper = 1;
        testC1 = 0; % target number of test points outside ellipse
        C2 = 0; % count of number of loops
        % Extract training and test sets
        
        trainingDATA=output.trainingDATA(4:end,:);
        testDATA=output.testDATA;
        while looper == 1 % loop for collective optimisation
            C1 = 0; % count number of test points outside ellipse
            C2 = C2 + 1;
            for x1=1:datasets
                %x1
                % Run PCA
                [coeff,score,latent,tsquared,explained,mu] = pca(trainingDATA);
                TestScores=(testDATA-mu)*coeff;
                
                % Identify test points that need exchanging
                [M1,M2]=GetEllipses([score(1+R1*(x1-1):R1*x1,PC1),score(1+R1*(x1-1):R1*x1,PC2)],...
                    R1,output.variables(12),[TestScores(1+R2*(x1-1):R2*x1,PC1),TestScores(1+R2*(x1-1):R2*x1,PC2)],R2);
                
                % Randomly shuffle training and test sets
                if size(find(M2==0),2)>0
                    C1 = C1 + size(find(M2==0),2);
                    out = find(M2==0);
                    if size(out,2)>R1/2
                        out1 = randperm(size(out,2));
                        out1=out1(1:R1/2)';
                        out1=sortrows(out1)';
                        for x3 = 1:R1/2
                            out(x3)=out(out1(x3));
                        end
                        out(R1/2+1:end)=[];
                    end
                    out1 = randperm(R1);
                    for x3 = 1:size(out,2)%factorial(R1+R2)/(factorial(R1)*factorial(R2)) % Select other samples for test set
                        %x3
                        newtest=trainingDATA(out1(x3)+R1*(x1-1),:);
                        trainingDATA(out1(x3)+R1*(x1-1),:)=testDATA(out(x3)+R2*(x1-1),:);
                        testDATA(out(x3)+R2*(x1-1),:)=newtest;
                        newtest=output.sampleNUMBERS(1,R1*(x1-1)+out1(x3));
                        output.sampleNUMBERS(1,R1*(x1-1)+out1(x3))=output.sampleNUMBERS(2,R2*(x1-1)+out(x3));
                        output.sampleNUMBERS(2,R2*(x1-1)+out(x3))=newtest;
                    end
                end
            end
            
            % Conditions to stop collective optimisation loop
            if CO == 0 || C1 == testC1
                looper = 0;
            end
            testC1 = C1;
            if mod(C2,100)==0
                answer = questdlg('Optimal test set not yet found. Continue?', ...
                    'Circuit breaker');
                if strcmp(answer,'Yes')==0
                    looper = 0;
                end
            end
        end
        
        % Apply new training and test sets
        output.trainingDATA(4:end,:)=trainingDATA;
        output.testDATA=testDATA;
        
        pcaRUN
    end
end
end

function pcaRUN
% Runs from user inputted data
global training output test XVariableNumbers xVALUES

if output.variables(9)==1 % toggle between PCA and PLS
    output.variables(2)=1;
    output.variables(3)=2;
    output.variables(9)=0;
end


if size(XVariableNumbers,1)==0
    for a = 1:size(training,2)
        XVariableNumbers(1,a)=a;
    end
end
if isfield(output,'trainingDATA') == 0
    % Transfer user inputted data to output file
    pcaDATASET
end

[coeff,score,latent,tsquared,explained,mu] = pca(output.trainingDATA(4:end,:));

output.PCA.loadings=coeff;
output.PCA.scores=score;
output.PCA.latent=latent;
output.PCA.tsquared=tsquared;
output.PCA.explained=explained;
output.PCA.mu=mu;

pcaGRAPH

end

function pcaGRAPH

close all

Pix_SS = get(0,'screensize'); %Get screen dimensions


global training test output temp SampleNames ExtraData xVALUES Ytest Ytraining
if size(training,1)>0 % Check to make sure training dataset exists
    if output.variables(9)==0 %toggle PCA/PLS
        % Graph variance
        figure('Name','Variance explained','Position',[10+Pix_SS(1,3)/15+50,50+Pix_SS(1,4)/2,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
        hold on
        set(gca,'FontName','Calibri','FontSize',12);
        ScreeLimit = size(output.PCA.explained,1);
        if ScreeLimit > 20
            ScreeLimit = 20;
        end
        bar(output.PCA.explained(1:ScreeLimit,1))
        cumulative = output.PCA.explained;
        cumulative(1,2)=cumulative(1,1);
        cumulative(1,1)=1;
        for a = 2:ScreeLimit
            cumulative(a,2)=cumulative(a-1,2)+cumulative(a,1);
            cumulative(a,1)=a;
        end
        plot(cumulative(1:ScreeLimit,1),cumulative(1:ScreeLimit,2),'-*')
        xlabel('# of latent variable')
        ylabel('Variance explained (%)')
        if output.variables(1,6)==1
            set(gcf, 'Color', 'None');
            set(gca, 'Color', 'None');
        end
        
        % Graph PC loadings 1
        text=strcat('Loadings for PC',num2str(output.variables(1,2)));
        figure('Name',text,'Position',[10+Pix_SS(1,3)/15+50,50,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
        temp.PC1 = output.PCA.loadings(:,output.variables(1,2));
        if size(xVALUES,2)>0 && size(xVALUES,2)~=size(training,2) % Check if xVALUES arranged correctly
            xVALUES=transpose(xVALUES);
        end
        if size(xVALUES,2) == size(training,2)
            temp.xVALUES=[];
            for a=1:size(output.trainingDATA,2)
                temp.xVALUES(1,a)=xVALUES(1,output.trainingDATA(1,a));
                if temp.PC1(a,1)>0
                    temp.xVALUES(2,a)=0;
                    temp.xVALUES(3,a)=abs(temp.PC1(a,1));
                else
                    temp.xVALUES(3,a)=0;
                    temp.xVALUES(2,a)=abs(temp.PC1(a,1));
                end
            end
            errorbar(temp.xVALUES(1,:),temp.PC1,temp.xVALUES(3,:),temp.xVALUES(2,:),'o','CapSize',0,'MarkerSize',0.01,'LineWidth',0.5)
            xlabel('m/z')
            set(gca,'FontName','Calibri','FontSize',16);
            pos=get(get(gca,'xlabel'),'position');
            set(gca,'XAxisLocation','origin')
            set(get(gca,'xlabel'),'position',pos);
        else
            bar(temp.PC1,'YDataSource','temp.PC1')
            xlabel('Variable number')
            set(gca,'FontName','Calibri','FontSize',16);
        end
        ylabel(strcat('PC',num2str(output.variables(1,2)),' Loading'))
        box off
        linkdata on
        if output.variables(1,6)==1
            set(gcf, 'Color', 'None');
            set(gca, 'Color', 'None');
        end
        
        % Graph PC loadings 2
        text=strcat('Loadings for PC',num2str(output.variables(1,3)));
        figure('Name',text,'Position',[10+Pix_SS(1,3)/15+50+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,50,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
        temp.PC2 = output.PCA.loadings(:,output.variables(1,3));
        if size(xVALUES,2)==size(training,2)
            for a=1:size(output.trainingDATA,2)
                if temp.PC2(a,1)>0
                    temp.xVALUES(2,a)=0;
                    temp.xVALUES(3,a)=abs(temp.PC2(a,1));
                else
                    temp.xVALUES(3,a)=0;
                    temp.xVALUES(2,a)=abs(temp.PC2(a,1));
                end
            end
            errorbar(temp.xVALUES(1,:),temp.PC2,temp.xVALUES(3,:),temp.xVALUES(2,:),'o','CapSize',0,'MarkerSize',0.01,'LineWidth',1)
            xlabel('m/z')
            set(gca,'FontName','Calibri','FontSize',16);
            pos=get(get(gca,'xlabel'),'position');
            set(gca,'XAxisLocation','origin')
            set(get(gca,'xlabel'),'position',pos);
        else
            bar(temp.PC2,'YDataSource','temp.PC1')
            xlabel('Variable number')
            set(gca,'FontName','Calibri','FontSize',16);
        end
        ylabel(strcat('PC',num2str(output.variables(1,3)),' Loading'))
        box off
        %linkdata on
        if output.variables(1,6)==1
            set(gcf, 'Color', 'None');
            set(gca, 'Color', 'None');
        end
        
        %% Scores plot
        figure('Name','Scores plot','Position',[10+Pix_SS(1,3)/15+50+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,50+Pix_SS(1,4)/2,Pix_SS(1,4)/2.7+100,Pix_SS(1,4)/2.7]);
        hold on
        if output.variables(1,6)==1
            set(gcf, 'Color', 'None');
            set(gca, 'Color', 'None');
        end
        set(gca,'FontName','Calibri','FontSize',16,'Position',[0.18,0.18,0.74*0.75,0.74]);
        % Find number of datasets
        reps = output.variables(1,1);
        datasets = floor(size(output.PCA.scores,1)/reps);
        data1(:,1)=output.PCA.scores(:,output.variables(1,2));
        data1(:,2)=output.PCA.scores(:,output.variables(1,3));
        
        % Find different colours for different datasets
        cs(1:datasets,3)=0;
        if datasets == 1
            cs(1,1:3)=0;
        else
            for a =0: datasets-1
                cs(a+1,1:3)=colourcalc(a,datasets-1,'Rainbow');
            end
        end
        if output.variables(1)==0
            mks={'o'};
        else
            mks = {'o','^','d'};
        end
        
        % Add data
        for a=1:datasets
            if isempty(find(output.omit==a))==1
                scatter(output.PCA.scores(1+reps*(a-1):a*reps,output.variables(1,2)),...
                    output.PCA.scores(1+reps*(a-1):a*reps,output.variables(1,3)),...
                    9,cs(a,:),'filled',mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
            end
        end
        text = strcat('PC',num2str(output.variables(1,2)),' (',num2str(round(output.PCA.explained(output.variables(1,2),1),1)),'%)');
        xlabel(text)
        text = strcat('PC',num2str(output.variables(1,3)),' (',num2str(round(output.PCA.explained(output.variables(1,3),1),1)),'%)');
        ylabel(text)
        
        % Add extradata to graph
        if isfield(temp,'ExtraData')==1 && size(temp.ExtraData,2)==0 && size(ExtraData,2)>0 || size(ExtraData,2)>0 && isfield(temp,'ExtraData')==0
            temp.ExtraData=ExtraData;
        end
        if isfield(temp,'ExtraData')==1 && size(temp.ExtraData,2)>0
            % Check to ensure ExtraData size is correct
            %if size(temp.ExtraData,2)~=size(output.trainingDATA,2)
            temp.ExtraData=[];
            for a=1:size(output.trainingDATA,2)
                temp.ExtraData(:,a)=ExtraData(:,output.trainingDATA(1,a));
            end
            %end
            if output.variables(7)==1
                scale=output.trainingDATA(3,:);
                offset=output.trainingDATA(2,:);
                if output.variables(8)==1
                    scale=scale.*output.trainingDATA(2,:).^0.5;
                end
            elseif output.variables(8)==1
                offset=0;
                scale=output.trainingDATA(2,:).^0.5;
            else
                scale=1;
                offset =0;
            end
            PlotScores=((temp.ExtraData-offset)./scale-output.PCA.mu)*output.PCA.loadings;
            output.PCA.ExtraDataScores=PlotScores;
            %x1=size(PlotScores,1);
            %for a=1:x1
            scatter(PlotScores(:,output.variables(1,2)),PlotScores(:,output.variables(1,3)),...
                12,[0,0,0],'x')%[1-a/x1,1-a/x1,1-a/x1],'x')
            %end
        end
        
        % Confidence Ellipses
        if reps>1
            [Ellipse,~,output.variables(12)] = GetEllipses(data1,reps,output.variables(12));
            output.PCA.ConfidenceEllipses = Ellipse;
            for a=1:datasets
                if isempty(find(output.omit==a))==1
                    plot(Ellipse(:,1+2*(a-1)),Ellipse(:,2*a),...
                        'Color',cs(a,:))
                end
            end
        end
        
        % Adding test dataset to graph
        if size(test,2)==size(training,2)&&output.variables(1,4)>0
            reps = output.variables(1,4);
            output.PCA.TestScores=(output.testDATA-output.PCA.mu)*output.PCA.loadings;
            temp.TestScores = output.PCA.TestScores(:,output.variables(1,2));
            temp.TestScores(:,2)=output.PCA.TestScores(:,output.variables(1,3));
            % XDataSource/YDataSource must be separately defined to allow linkdata
            for a=1:datasets
                if isempty(find(output.omit==a))==1
                    scatter(temp.TestScores(1+(a-1)*reps:reps*a,1),...
                        temp.TestScores(1+(a-1)*reps:reps*a,2),...
                        12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))},...
                        'XDataSource','temp.TestScores(1+(a-1)*reps:reps*a,1)',...
                        'YDataSource','temp.TestScores(1+(a-1)*reps:reps*a,2)')
                    %linkdata on
                end
            end
        end
        
        
        
        % Add legend
        if 1<datasets && isempty(find(output.omit==2000))==1
            % Ensure sample names is in correct orientation
            if size(SampleNames,2)<size(SampleNames,1)
                SampleNames=transpose(SampleNames);
            end
            % Ensure there are enough sample names for number of datasets
            while size(SampleNames,2)<datasets
                SampleNames{end+1}=num2str(size(SampleNames,2)+1);
            end
            Names=[];
            for a=1:datasets
                if isempty(find(output.omit==a))==1
                    Names{end+1}=SampleNames{a};
                end
            end
            
            legend(Names,'FontSize',10)
            a=get(legend,'Position');
            legend(Names,'FontSize',10,'Position',[0.75,a(2)+0.04,a(3),a(4)])
            
        end
        
        % Create small scores plot
        
        for b = 1:4
            if size(output.PCA.scores,2)>= b*2
                reps = output.variables(1,1);
                p1=10+Pix_SS(1,3)/15+50+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3;
                if b == 2 || b ==4
                    p1=p1+Pix_SS(1,4)/4;
                end
                p2=50+Pix_SS(1,4)/2;
                if b>2; p2 = p2 - Pix_SS(1,4)/4-100;end
                figure('Name',strcat('Scores plot ',num2str(b)),'Position',[p1,p2,Pix_SS(1,4)/4,Pix_SS(1,4)/4]);
                hold on
                if output.variables(1,6)==1
                    set(gcf, 'Color', 'None');
                    set(gca, 'Color', 'None');
                end
                set(gca,'FontName','Calibri','FontSize',8,'Position',[0.18,0.18,0.74,0.74]);
                
                % Add data
                data1(:,1)=output.PCA.scores(:,1+2*(b-1));
                data1(:,2)=output.PCA.scores(:,2*b);
                
                for a=1:datasets
                    
                    scatter(data1(1+reps*(a-1):a*reps,1),...
                        data1(1+reps*(a-1):a*reps,2),...
                        6,cs(a,:),'filled',mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
                    
                end
                text = strcat('PC',num2str(1+2*(b-1)),' (',num2str(round(output.PCA.explained(1+2*(b-1),1),1)),'%)');
                xlabel(text)
                text = strcat('PC',num2str(2*b),' (',num2str(round(output.PCA.explained(2*b,1),1)),'%)');
                ylabel(text)
                
                % Confidence Ellipses
                if reps>1
                    Ellipse = GetEllipses(data1,reps,output.variables(12));
                    for a=1:datasets
                        
                        plot(Ellipse(:,1+2*(a-1)),Ellipse(:,2*a),...
                            'Color',cs(a,:))
                        
                    end
                end
                
                % Adding test dataset to graph
                if size(test,2)==size(training,2)&&output.variables(1,4)>0
                    reps = output.variables(1,4);
                    temp.TestScores = output.PCA.TestScores(:,1+2*(b-1));
                    temp.TestScores(:,2)=output.PCA.TestScores(:,2*b);
                    % XDataSource/YDataSource must be separately defined to allow linkdata
                    for a=1:datasets
                        
                        scatter(temp.TestScores(1+(a-1)*reps:reps*a,1),...
                            temp.TestScores(1+(a-1)*reps:reps*a,2),...
                            12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))},...
                            'XDataSource','temp.TestScores(1+(a-1)*reps:reps*a,1)',...
                            'YDataSource','temp.TestScores(1+(a-1)*reps:reps*a,2)')
                        %linkdata on
                    end
                    
                end
                
            end
        end
    else % Graph PLS
        YTraining=[];
        YTest=[];
        for a=1:size(temp.Ytraining,1)
            if isnan(temp.Ytraining(a,1))==0 && isinf(temp.Ytraining(a,1))==0
                YTraining(end+1,1)=temp.Ytraining(a,1);
            end
        end
        for a=1:size(temp.Ytest,1)
            if isnan(temp.Ytest(a,1))==0 && isinf(temp.Ytest(a,1))==0
                YTest(end+1,1)=temp.Ytest(a,1);
            end
        end
        plsGRAPH(output.PLS.residuals,output.PLS.RegressionVector,output.PLS.predictTRAINING,YTraining,YTest,output.PLS.predictTEST,output.PLS.r2_SE,output.PLS.Variance)
    end
else
    msgbox 'Please copy data into "training" variable with each row a different sample and each column a different measurement.'
end
end

