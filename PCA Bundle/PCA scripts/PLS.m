function [residuals,RV,yfitPLS,TestfitPLS,r2,YTraining,YTest,PLSPctVar,Xloadings,Yloadings,Xscores,Yscores,betaPLS]=PLS
% PLS script by Andrew Hook 2016 v1.1
% Updated for PCA bundle August 2020

TestfitPLS=[];
residuals=[];
RV=[];
yfitPLS=[];
YTraining=[];
YTest=[];
r2=[];
PLSPctVar=[];
Xloadings=[];
Yloadings=[];
Xscores=[];
Yscores=[];
betaPLS=[];
%%
%Data input
global output temp
if size(temp.Ytraining,1)==0
    msgbox('Please add Y data to perform PLS')
else
    % Check to see if any infinite values
    XTraining=[];
    YTraining=[];
    for x1=1:size(temp.Ytraining,1)
        if isnan(temp.Ytraining(x1,1))==0 && isinf(temp.Ytraining(x1,1)) == 0
            XTraining(end+1,:) = output.trainingDATA(3+x1,:);
            YTraining(end+1,1) = temp.Ytraining(x1,1);
        end
    end
    n = size(XTraining,1);
    p = size(XTraining,2)-1;
    
    
    s=output.variables(3);
    if s>p-1 || s==0
        s=p;
        output.variables(3)=s;
    end
    if output.variables(2)>output.variables(3)
        output.variables(2)=output.variables(3);
    end
    if size(temp.Ytest,1)>0
        XTest=[];
        YTest=[];
        for x1=1:size(temp.Ytest,1)
            if isnan(temp.Ytest(x1,1))==0 && isinf(temp.Ytest(x1,1)) == 0
                XTest(end+1,:) = output.testDATA(x1,:);
                YTest(end+1,1) = temp.Ytest(x1,1);
            end
        end
        for a=1:s %Produce RMSECV curve
            
            
            [Xloadings,Yloadings,Xscores,Yscores,betaPLS,PLSPctVar] = plsregress(XTraining(:,:),YTraining(:,:),a);
            yfitPLS = [ones(n,1) XTraining(:,:)]*betaPLS;
            TestfitPLS = [ones(size(XTest(:,:),1),1) XTest(:,:)]*betaPLS;
            
            RV = betaPLS;
            residuals = YTraining(:,:)-yfitPLS;
            
            %Build stats file
            r2(a,1)=a;
            r2(a,2)=1-sum((yfitPLS-YTraining(:,:)).^2)/sum((yfitPLS-mean(yfitPLS)).^2);
            r2(a,3)=1-sum((TestfitPLS-YTest(:,:)).^2)/sum((TestfitPLS-mean(TestfitPLS)).^2);
            r2(a,4)=sqrt(sum((yfitPLS-YTraining(:,:)).^2)/size(YTraining(:,:),1));
            r2(a,5)=sqrt(sum((TestfitPLS-YTest(:,:)).^2)/size(YTest(:,:),1));
            
            
        end
        
        
        %%
        %Leave one out method
    else
        for b=1:s %Produce RMSECV curve
            for a=1:n %Produce RMSECV curve using leave one out method
                if a==1
                    XTraining1(1:n-1,1:p)=XTraining(2:n,1:p);
                    YTraining1(1:n-1,1)=YTraining(2:n,1);
                else
                    XTraining1(1:a-1,1:p)=XTraining(1:a-1,1:p);
                    XTraining1(a:n-1,1:p)=XTraining(a+1:n,1:p);
                    YTraining1(1:a-1,1)=YTraining(1:a-1,1);
                    YTraining1(a:n-1,1)=YTraining(a+1:n,1);
                end
                XTest(1,1:p)=XTraining(a,1:p);
                YTest(1,1)=YTraining(a,1);
               
                
                %LV = cell2mat(LV);
                %LV = str2double(LV);
                [Xloadings,Yloadings,Xscores,Yscores,betaPLS,PLSPctVar] = plsregress(XTraining1,YTraining1,b);
                yfitPLS = [ones(n-1,1) XTraining1]*betaPLS;
                TestfitPLS = [ones(size(XTest,1),1) XTest]*betaPLS;
                
                r2values(a,1)=1-sum((yfitPLS-YTraining1).^2)/sum((yfitPLS-mean(yfitPLS)).^2);
                RMSEbuild(1:n-1,a)=yfitPLS(1:n-1,1)-YTraining1(1:n-1,1);
                RMSECVbuild(a,1)=TestfitPLS-YTest;
                
                
            end
            YTest=[];
            %Build stats file
            r2(b,1)=b;
            r2(b,2)=mean(r2values(:,1));
            r2(b,4)=sqrt(sum(sum(RMSEbuild.^2))/numel(RMSEbuild));
            r2(b,5)=sqrt(sum(RMSECVbuild.^2)/numel(RMSECVbuild));
            
        end
    end
    
    %% PLS with user defined number of latent variables
    b=output.variables(2);
    if b>p
        b=p;
    end
    [Xloadings,Yloadings,Xscores,Yscores,betaPLS] = plsregress(XTraining,YTraining(:,:),b);
    yfitPLS = [ones(n,1) XTraining]*betaPLS;
    if size(temp.Ytest,1)>0
        TestfitPLS = [ones(size(XTest,1),1) XTest]*betaPLS;
    end
    
    RV = betaPLS;
    residuals = YTraining(:,:)-yfitPLS;
    
    
    
end