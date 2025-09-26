%% Script wizard for PCA
% Requires training set with different samples in each row Different
% measurements for each column May also optionally contain a test set Will
% draw 95% confidence ellipse around replicate measurements 
% Andrew Hook May 2019 
% Includes Random Forest Update
% output contains all PCA number outputs output.trainingDATA row 1 =
% variable number, 2 = mean, 3 = std Add data to ExtraData that wish to be
% added to PCA plot
close all

addpath('PCA scripts')

% Create global variables
global training test output temp ExtraData SampleNames xVALUES Ytest Ytraining
output.variables=[1,1,2,0,0,0,0,0,0,0,0,95];
%[1-number of training replicates,2-X axis PC,3-Y axis PC,4-number of test
%replicates,5-toggle collective optimisation,6-toggle transparent
%BKG,7-toggle variance scaling,8-toggle SRM,9-toggle PCA/PLS,10-toggle
%log/log for PLS,11 orbi filter toggle,12 confidence limit,13-16 position
%of main fig]
output.log=[];
output.omit=[]; % option to turn off datasets from graphing. Dataset number added will cause dataset to not be plotted. If add number 2000 to omit will turn off legend.
ExtraData=[];
SampleNames=[];
SampleNames{1,1}='1';
xVALUES=[];
temp.ExtraData=ExtraData;
UISetup(0)
% Check if training data imported
if size(training,1)==0
    msgbox 'Please copy data into "training" variable with each row a different sample and each column a different measurement. If desired, add data to test and ExtraData'
else
    pcaDATASET
    pcaRUN
end

%% Micellaneous step
if 1 == 0
    UISetup(0)
end
%% Setup user interface
function UISetup(box)
global output temp
if size(output.variables,2)<12 % Alter variables to ensure old datasets are still compatible
    output.variables(1,12)=95;
end
Pix_SS = get(0,'screensize'); %Get screen dimensions
Height = floor(0.75*Pix_SS(4));
Width = floor(0.05*Pix_SS(4));
Elements = 27; %Increase to add more parts to Setup Box
Step = floor(Height/Elements);
fig = uifigure('units','pixels','Position',[0,Width,Pix_SS(1,3)/15+50,Height+6]);
output.variables(13:16) = get(fig,'Position');
boxHIDE = uicheckbox(fig,...
    'text','Square root mean',...
    'position',[25,Height-11*Step+6,Pix_SS(1,3)/15,Step-6],...
    'Value',output.variables(8),...
    'ValueChangedFcn',@(src,evt)scaleMS(evt));
boxSCALING = uicheckbox(fig,...
    'text','Scale By STDev','Value',box,...
    'position',[25,Height-12*Step+6,Pix_SS(1,3)/15,Step-6],...
    'Value',output.variables(7),...
    'ValueChangedFcn',@(src,evt)scaleSTD(evt));
boxTRANSPARENT = uicheckbox(fig,...
    'text','Transparent BKG','Value',box,...
    'position',[25,Height-4*Step+6,Pix_SS(1,3)/15,Step-6],...
    'Value',output.variables(6),...
    'ValueChangedFcn',@(src,evt)tBKG(evt));
boxFILTER = uicheckbox(fig,...
    'text','Orbi-filter','Value',box,...
    'position',[25,Height-19*Step+6+0.1*Step,Pix_SS(1,3)/15,Step-6],...
    'Value',output.variables(11),...
    'ValueChangedFcn',@(src,evt)oFILTER(evt));
btnPCA = uibutton(fig,'Text','Run PCA','Position',[25,Height-1*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnPCA,event) pcaRUN,'Backgroundcolor',[0.5,1,0.5]);
btnPLS = uibutton(fig,'Text','Run PLS','Position',[25,Height-2*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnPLS,event) plsRUN,'Backgroundcolor',[0.5,1,0.5]);
btnCLOSE = uibutton(fig,'Text','CLOSE','Position',[25,Height-15*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnCLOSE,event) CLS,'Backgroundcolor',[1,0.7,0.7]);
btnTRANSPOSE = uibutton(fig,'Text','Transpose Data','Position',[25,Height-9*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnTRANSPOSE,event) fctTRANSPOSE,'Backgroundcolor',[0.7,0.7,1]);
btnOPEN = uibutton(fig,'Text','OPEN','Position',[25,Height-13*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnOPEN,event) pcaOPEN,'Backgroundcolor',[1,0.7,0.7]);
btnSAVE = uibutton(fig,'Text','SAVE','Position',[25,Height-14*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnSAVE,event) pcaSAVE,'Backgroundcolor',[1,0.7,0.7]);
lbl1 = uilabel(fig,'Text','Training/Test replicates',...
    'Position',[25,Height-16*Step+6,Pix_SS(1,3)/15,Step-6]);
Replicates = uieditfield(fig,'numeric','Position',[25,Height-17*Step+6,Pix_SS(1,3)/30,Step-6],...
    'RoundFractionalValues','on','Value',output.variables(1),'ValueChangedFcn',@(Replicates,event) RepChange(Replicates,event));
TestReplicates = uieditfield(fig,'numeric','Position',[25,Height-18*Step+6,Pix_SS(1,3)/30,Step-6],...
    'RoundFractionalValues','on','Value',output.variables(4),'ValueChangedFcn',@(TestReplicates,event) TestRepChange(TestReplicates,event));
btnSplitReplicates = uibutton(fig,'Text',sprintf('Split/Comb \n dataset'),'Position',[25+Pix_SS(1,3)/30,Height-18*Step+6,Pix_SS(1,3)/30,2*Step-6],...
    'ButtonPushedFcn', @(btnSplitReplicates,event) split,'Backgroundcolor',[1,1,1]);
btnRESET = uibutton(fig,'Text','Re-set Data','Position',[25,Height-10*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnRESET,event) pcaRESET(boxSCALING),'Backgroundcolor',[0.7,0.7,1]);
btnAUTOREDUCE = uibutton(fig,'Text','RFE/RFA','Position',[25,Height-21*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnAUTOREDUCE,event) autoREDUCE,'Backgroundcolor',[0.7,0.7,1]);
btnOPTIMISE = uibutton(fig,'Text','Optimise test set','Position',[25,Height-23*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnOPTIMISE,event) optimiseTT,'Backgroundcolor',[0.7,0.7,1]);
btnREDUNDANT = uibutton(fig,'Text','Remove redundant','Position',[25,Height-22*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnREDUNDANT,event) reduceRED,'Backgroundcolor',[0.7,0.7,1]);
btnCLEARALL = uibutton(fig,'Text','CLEAR ALL','Position',[25,Height-27*Step+6,Pix_SS(1,3)/15,Step-6],...
    'ButtonPushedFcn', @(btnCLEARALL,event) clearALL,'Backgroundcolor',[0.5,0.5,0.5]);
% Options to load for PCA only
if output.variables(9)==0
    lbl2 = uilabel(fig,'Text','X-axis PC',...
        'Position',[25,Height-5*Step+6,Pix_SS(1,3)/15,Step-6]);
    PC1 = uieditfield(fig,'numeric','Position',[25,Height-6*Step+6,Pix_SS(1,3)/30,Step-6],...
        'RoundFractionalValues','on','Value',output.variables(2),'ValueChangedFcn',@(PC1,event) PC1Change(PC1,event));
    lbl3 = uilabel(fig,'Text','Y-axis PC',...
        'Position',[25,Height-7*Step+6,Pix_SS(1,3)/15,Step-6]);
    PC2 = uieditfield(fig,'numeric','Position',[25,Height-8*Step+6,Pix_SS(1,3)/30,Step-6],...
        'RoundFractionalValues','on','Value',output.variables(3),'ValueChangedFcn',@(PC2,event) PC2Change(PC2,event));
    btn3D = uibutton(fig,'Text','Create 3D plot','Position',[25,Height-26*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btn3D,event) plot3D,'Backgroundcolor',[0.5,1,0.8]);
    btnDEND = uibutton(fig,'Text','Clustering','Position',[25,Height-25*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btnSPCA,event) Dendrogram,'Backgroundcolor',[0.5,1,0.8]);
    btnGRAPH = uibutton(fig,'Text','Refresh Graphs','Position',[25,Height-3*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btnGRAPH,event) pcaGRAPH,'Backgroundcolor',[0.5,1,0.5]);
    lbl3 = uilabel(fig,'Text','Confidence limit',...
        'Position',[25,Height-24*Step+6,Pix_SS(1,3)/15,Step-6]);
    CFLimit = uieditfield(fig,'numeric','Position',[120,Height-24*Step+6,Pix_SS(1,3)/50,20],...
        'RoundFractionalValues','off','Value',output.variables(12),'ValueChangedFcn',@(CFLimit,event) CFChange(CFLimit,event));
    btnREDUCE = uibutton(fig,'Text','Manual Reduce','Position',[25,Height-20*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btnREDUCE,event) pcaREDUCE(boxSCALING),'Backgroundcolor',[0.7,0.7,1]);
else
    lbl2 = uilabel(fig,'Text','#Latent variables',...
        'Position',[25,Height-5*Step+6,Pix_SS(1,3)/15,Step-6]);
    PC1 = uieditfield(fig,'numeric','Position',[25,Height-6*Step+6,Pix_SS(1,3)/30,Step-6],...
        'RoundFractionalValues','on','Value',output.variables(2),'ValueChangedFcn',@(PC1,event) PC1Change(PC1,event));
    lbl3 = uilabel(fig,'Text','Total LVs',...
        'Position',[25,Height-7*Step+6,Pix_SS(1,3)/15,Step-6]);
    PC2 = uieditfield(fig,'numeric','Position',[25,Height-8*Step+6,Pix_SS(1,3)/30,Step-6],...
        'RoundFractionalValues','on','Value',output.variables(3),'ValueChangedFcn',@(PC2,event) PC2Change(PC2,event));
    boxLOG = uicheckbox(fig,...
        'text','log Y data','Value',box,...
        'position',[25,Height-3*Step+6,Pix_SS(1,3)/15,Step-6],...
        'Value',output.variables(10),...
        'ValueChangedFcn',@(src,evt)logDATA(evt));
    btnLASSO = uibutton(fig,'Text','LASSO','Position',[25,Height-24*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btn3D,event) LASSO,'Backgroundcolor',[0.7,0.7,1]);
    btnVIP = uibutton(fig,'Text','VIP filter','Position',[25,Height-25*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btnVIP,event) VIP,'Backgroundcolor',[0.7,0.7,1]);
    btnSCORES = uibutton(fig,'Text','Scores plot','Position',[25,Height-26*Step+6,Pix_SS(1,3)/15,Step-6],...
        'ButtonPushedFcn', @(btnSCORES,event) PLSscores,'Backgroundcolor',[0.7,0.7,1]);
    if isfield(temp,'PLSlabel') == 1
        AxisLabel = uieditfield(fig,'Position',[25,Height-20*Step+6,Pix_SS(1,3)/15,Step-6],...
            'Value',temp.PLSlabel,'ValueChangedFcn',@(TestReplicates,event) PLSlabel(event));
    else
        AxisLabel = uieditfield(fig,'Position',[25,Height-20*Step+6,Pix_SS(1,3)/15,Step-6],...
            'ValueChangedFcn',@(TestReplicates,event) PLSlabel(event));
    end
    lbl4 = uilabel(fig,'Text','Axis label',...
        'Position',[ceil(Pix_SS(1,3)/15+50)/1.8,Height-20*Step+6+floor(Step/1.5),Pix_SS(1,3)/15,Step-6]);
end
clear Pix_SS
end
%% Functions called by user interface
% Transposes test and training sets
function fctTRANSPOSE

global training test xVALUES
training=transpose(training);
test=transpose(test);
if size(xVALUES,1)>1
    xVALUES=xVALUES';
end

end

% Function that calculates PCA. Also runs graphing function
function pcaRUN
% Runs from user inputted data
global training output test XVariableNumbers xVALUES

if output.variables(9)==1 % toggle between PCA and PLS
    output.variables(2)=1;
    output.variables(3)=2;
    output.variables(9)=0;
end
if size(training,1)>0
    if size(xVALUES,2)==0 || size(xVALUES,2)==size(training,2)
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
    else
        msgbox 'Please update xVALUES.'
    end
else
    msgbox 'Please copy data into "training" variable with each row a different sample and each column a different measurement.'
end
end

% Function that runs PLS
function plsRUN
global output Ytest Ytraining temp training XVariableNumbers xVALUES
if output.variables(9)==0 % toggle between PCA and PLS
    output.variables(2)=1;
    output.variables(3)=20;
    output.variables(9)=1;
end
if size(xVALUES,2)==0 || size(xVALUES,2)==size(training,2)
    % Check if log correctly applied
    if output.variables(10)==1 && isfield(temp,'Ytraining') == 1 && temp.Ytraining(1,1)==Ytraining(1,1)
        evt.Value = 1;
        logDATA(evt)
    elseif size(training,1)>0
        if size(XVariableNumbers,1)==0
            for a = 1:size(training,2)
                XVariableNumbers(1,a)=a;
            end
        end
        if isfield(output,'trainingDATA') == 0 || size(temp,1)==0
            % Transfer user inputted data to output file
            pcaDATASET
        end
        if isfield(temp,'Ytraining')==0
            temp.Ytraining=Ytraining;
            temp.Ytest=Ytest;
            output.variables(10)=0;
        end
        
%         if size(Ytraining,1)~=size(output.trainingDATA,1)-3
%             Ytraining=[];
%         end
        if isfield(temp,'Ytraining')==0 && size(Ytraining,1)>0
            temp.Ytraining=Ytraining;
            temp.Ytest=Ytest;
        end
        [residuals,RV,yfitPLS,TestfitPLS,r2,YTraining,YTest,PLSPctVar,Xloadings,Yloadings,VIPvalues,Xscores,Yscores,Testscores,stats]=PLS;
        close all force
        UISetup(0)
        output.PLS.residuals = residuals;
        output.PLS.RegressionVector=RV;
        output.PLS.predictTRAINING=yfitPLS;
        output.PLS.measuredTRAINING=YTraining;
        output.PLS.predictTEST=TestfitPLS;
        output.PLS.measuredTEST=YTest;
        output.PLS.r2_SE=r2;
        output.PLS.Loadings=Xloadings;
        output.PLS.YLoadings=Yloadings;
        output.PLS.Scores=Xscores;
        output.PLS.YScores=Yscores;
        output.PLS.TScores=Testscores;
        output.PLS.Variance=PLSPctVar;
        output.PLS.VIP = VIPvalues;
        output.PLS.Stats=stats;
        if size(Ytraining,1)>0
            plsGRAPH(residuals,RV,yfitPLS,YTraining,YTest,TestfitPLS,r2,PLSPctVar)
        end
    end
else
    msgbox 'Please update xVALUES.'
end
end

%% Graphing functions
% Produces graphs
function pcaGRAPH

close all force
UISetup(0)
Pix_SS = get(0,'screensize'); %Get screen dimensions


global training test output temp SampleNames ExtraData xVALUES Ytest Ytraining
if size(training,1)>0 % Check to make sure training dataset exists
    if output.variables(9)==0 %toggle PCA/PLS
        % Graph variance
        figure('Name','Variance explained','Position',[output.variables(13)+output.variables(15),output.variables(14)+180+(Pix_SS(1,3)-output.variables(15))/4,(Pix_SS(1,3)-output.variables(15))/4,(Pix_SS(1,3)-output.variables(15))/4-100]);
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
        figure('Name',text,'Position',[output.variables(13)+output.variables(15),output.variables(14)+180,(Pix_SS(1,3)-output.variables(15))/4,(Pix_SS(1,3)-output.variables(15))/4-100]);
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
        figure('Name',text,'Position',[output.variables(13)+output.variables(15)+(Pix_SS(1,3)-output.variables(15))/4,output.variables(14)+180,(Pix_SS(1,3)-output.variables(15))/4,(Pix_SS(1,3)-output.variables(15))/4-100]);
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
        figure('Name','Scores plot','Position',[output.variables(13)+output.variables(15)+(Pix_SS(1,3)-output.variables(15))/4,output.variables(14)+180+(Pix_SS(1,3)-output.variables(15))/4,(Pix_SS(1,3)-output.variables(15))/4,(Pix_SS(1,3)-output.variables(15))/4-100]);
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
            %x1=size(PlotScores,1); for a=1:x1
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
        if output.variables(1,4)>0
            reps = output.variables(1,4);
            output.PCA.TestScores=(output.testDATA-output.PCA.mu)*output.PCA.loadings;
            temp.TestScores = output.PCA.TestScores(:,output.variables(1,2));
            temp.TestScores(:,2)=output.PCA.TestScores(:,output.variables(1,3));
            % XDataSource/YDataSource must be separately defined to allow
            % linkdata
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
                if size(output.testDATA,2)==size(training,2)&&output.variables(1,4)>0
                    reps = output.variables(1,4);
                    temp.TestScores = output.PCA.TestScores(:,1+2*(b-1));
                    temp.TestScores(:,2)=output.PCA.TestScores(:,2*b);
                    % XDataSource/YDataSource must be separately defined to
                    % allow linkdata
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

% Produce dendrogram
function Dendrogram
global output ExtraData
if size(output.PCA.loadings,2)==0
    pcaDATASET
    pcaRUN
end
Pix_SS = get(0,'screensize'); %Get screen dimensions
fig1 = uifigure('units','pixels','Position',[Pix_SS(1,3)/4,Pix_SS(1,4)/3,190,410]);
if size(output.PCA.latent,1)<20
    b = size(output.PCA.latent,1);
else
    b= 20;
end
for a =1:b
    uicheckbox(fig1,'Text',strcat('PC',num2str(a)),'Position',[10 410-20*a 102 15]);
end
if isfield(output.PCA,'TestScores')==1
    uibutton(fig1,'Text','Dendrogram','Position',[90,220,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) dendrogram_plot(fig1.Children,output.variables,output.PCA.scores,output.PCA.TestScores,...
        ExtraData));
    uibutton(fig1,'Text','HCA','Position',[90,160,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) dendrogramASSIGN(fig1.Children,output.variables,output.PCA.scores,output.PCA.TestScores)); %HCA = hierarchcial cluster analysis
    uibutton(fig1,'Text','Ellipse','Position',[90,130,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) ellipseASSIGN(fig1.Children,output.variables,output.PCA.scores,output.PCA.TestScores));
    uibutton(fig1,'Text','Random Forest','Position',[90,100,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) RandomForestSetup);
    uicheckbox(fig1,'Text','Include Extra Data?','Position',[60,190,200,25]); %Checkbox for Extra data, will be PCS 1
else
    uibutton(fig1,'Text','Dendrogram','Position',[90,220,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) dendrogram_plot(fig1.Children,output.variables,output.PCA.scores,[],...
        ExtraData));
    uibutton(fig1,'Text','HCA','Position',[90,160,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) dendrogramASSIGN(fig1.Children,output.variables,output.PCA.scores,[])); %HCA = hierarchcial cluster analysis
    uibutton(fig1,'Text','Ellipse','Position',[90,130,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) ellipseASSIGN(fig1.Children,output.variables,output.PCA.scores,[]));
    uibutton(fig1,'Text','Random Forest','Position',[90,100,70,25],'ButtonPushedFcn', ...
        @(btnPCA,event) RandomForestSetup);
    uicheckbox(fig1,'Text','Include Extra Data?','Position',[60,190,200,25]); %Checkbox for Extra data, will be PCS 1
end
end

% Random Forest Setup
function RandomForestSetup
global output
if isfield(output,'RF')==1 && isfield(output.RF,'errorLOG') ==1
    iReply = inputdlg({'Trees','Variables'},'If blank code will optimise', [1 60],{num2str(output.RF.trees) num2str(output.RF.variables)});
else
    iReply = inputdlg({'Trees','Variables'},'If blank code will optimise', [1 60]);
end
if isempty(iReply) == 0
    if size(iReply{1},2)>0 %What to do if trees and variables entered
        RandomForest(100,500,100,500,str2double(iReply{1}),str2double(iReply{2}))
    else
        iReply2 = inputdlg({'Min Trees','Max Trees','Min Variables','Max Variables'},'Enter limits', [1 30],{'20' '1000' num2str(ceil(sqrt(size(output.trainingDATA,2))/2)) num2str(ceil(size(output.trainingDATA,2)/2))});
        RandomForest(str2double(iReply2{1}),str2double(iReply2{2}),str2double(iReply2{3}),str2double(iReply2{4}))
    end
end
end


% Produce 3D plot
function plot3D
Pix_SS = get(0,'screensize'); %Get screen dimensions
fig1 = uifigure('units','pixels','Position',[Pix_SS(1,3)/4,Pix_SS(1,4)/3,50,410]);
for a =1:20
    uicheckbox(fig1,'Text',strcat('PC',num2str(a)),'Position',[10 410-20*a 102 15]);
end
uibutton(fig1,'Text','Accept','Position',[60,220,50,25],'ButtonPushedFcn', @(btnPCA,event) RUN(fig1.Children));

    function RUN(PCS)
        
        pcs=[];
        for x1=1:20
            if PCS(22-x1).Value==1
                pcs(end+1)=x1;
            end
        end
        if size(pcs,2)<3
            pcs(3)=pcs(2);
        end
        
        global training test output temp SampleNames ExtraData
        Pix_SS = get(0,'screensize'); %Get screen dimensions
        figure('Name','Scores plot','Position',[10+Pix_SS(1,3)/15+50+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,50+Pix_SS(1,4)/2,Pix_SS(1,4)/2.7+100,Pix_SS(1,4)/2.7]);
        hold on
        grid on
        if output.variables(1,6)==1
            set(gcf, 'Color', 'None');
            set(gca, 'Color', 'None');
        end
        set(gca,'FontName','Calibri','FontSize',14,'Position',[0.18,0.18,0.74*0.75,0.74]);
        % Find number of datasets
        reps = output.variables(1,1);
        datasets = floor(size(output.PCA.scores,1)/reps);
        
        % Use selected PCs
        
        data1(:,1)=output.PCA.scores(:,pcs(1));
        data1(:,2)=output.PCA.scores(:,pcs(2));
        data1(:,3)=output.PCA.scores(:,pcs(3));
        
        % Find different colours for different datasets
        cs(1:datasets,3)=0;
        for a =0: datasets-1
            cs(a+1,1:3)=colourcalc(a,datasets-1,'Rainbow');
        end
        if output.variables(1)==1
            mks={'o'};
        else
            mks = {'o','^','d'};
        end
        
        % Add data
        for a=1:datasets
            if isempty(find(output.omit==a))==1
                scatter3(data1(1+reps*(a-1):a*reps,1),data1(1+reps*(a-1):a*reps,2),...
                    data1(1+reps*(a-1):a*reps,3),...
                    9,cs(a,:),'filled',mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
            end
        end
        text = strcat('PC',num2str(pcs(1)),' (',num2str(round(output.PCA.explained(pcs(1),1),1)),'%)');
        xlabel(text)
        text = strcat('PC',num2str(pcs(2)),' (',num2str(round(output.PCA.explained(pcs(2),1),1)),'%)');
        ylabel(text)
        text = strcat('PC',num2str(pcs(3)),' (',num2str(round(output.PCA.explained(pcs(3),1),1)),'%)');
        zlabel(text)
        
        
        % Add extradata to graph
        if size(temp.ExtraData,2)==0 && size(ExtraData,2)>0
            temp.ExtraData=ExtraData;
        end
        if size(temp.ExtraData,2)>0
            PlotScores=(temp.ExtraData-output.PCA.mu)*output.PCA.loadings;
            scatter3(PlotScores(:,pcs(1)),PlotScores(:,pcs(2)),PlotScores(:,pcs(3)),...
                12,'k','x')
        end
        
        % Confidence Ellipses
        if reps>1
            for b=1:3
                if b==1
                    data2=data1(:,1:2);
                    data2(:,3)=data1(:,3);
                elseif b==2
                    data2=data1(:,2:3);
                    data2(:,3)=data1(:,1);
                else
                    data2(:,1)=data1(:,1);
                    data2(:,2)=data1(:,3);
                    data2(:,3)=data1(:,2);
                end
                Ellipse = GetEllipses(data2(:,1:2),reps,output.variables(12));
                for a=1:datasets
                    if isempty(find(output.omit==a))==1
                        if b==1
                            X=Ellipse(:,1+2*(a-1));
                            Y=Ellipse(:,2*a);
                            Z(1:100,1)=mean(data2(1+reps*(a-1):reps*a,3));
                        elseif b==2
                            Y=Ellipse(:,1+2*(a-1));
                            Z=Ellipse(:,2*a);
                            X(1:100,1)=mean(data2(1+reps*(a-1):reps*a,3));
                        else
                            X=Ellipse(:,1+2*(a-1));
                            Z=Ellipse(:,2*a);
                            Y(1:100,1)=mean(data2(1+reps*(a-1):reps*a,3));
                        end
                        plot3(X,Y,Z,':','Color',cs(a,:))
                    end
                end
            end
        end
        
        % Adding test dataset to graph
        if size(test,2)==size(training,2)&&output.variables(1,4)>0
            reps = output.variables(1,4);
            output.PCA.TestScores=(output.testDATA-output.PCA.mu)*output.PCA.loadings;
            temp.TestScores = output.PCA.TestScores(:,pcs(1));
            temp.TestScores(:,2)=output.PCA.TestScores(:,pcs(2));
            temp.TestScores(:,3)=output.PCA.TestScores(:,pcs(3));
            % XDataSource/YDataSource must be separately defined to allow
            % linkdata
            for a=1:datasets
                if isempty(find(output.omit==a))==1
                    scatter3(temp.TestScores(1+(a-1)*reps:reps*a,1),...
                        temp.TestScores(1+(a-1)*reps:reps*a,2),...
                        temp.TestScores(1+(a-1)*reps:reps*a,3),...
                        12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))},...
                        'XDataSource','temp.TestScores(1+(a-1)*reps:reps*a,1)',...
                        'YDataSource','temp.TestScores(1+(a-1)*reps:reps*a,2)')
                    %linkdata on
                end
            end
        end
        
        
        
        % Add legend
        if output.variables(1)>1 && isempty(find(output.omit==2000))==1
            if size(SampleNames,2)==0
                for a=1:size(training,1)/output.variables(1)
                    SampleNames{a}=num2str(a);
                end
            end
            Names=[];
            for a=1:datasets
                if isempty(find(output.omit==a))==1
                    Names{end+1}=SampleNames{a};
                end
            end
            if size(SampleNames,2)>datasets
                Names{end+1}=SampleNames{end};
            end
            if output.variables(1)>1
                legend(Names,'FontSize',10)
                a=get(legend,'Position');
                legend(Names,'FontSize',10,'Position',[0.75,a(2)+0.04,a(3),a(4)])
            end
        end
    end
end

% Scores plot for PLS
function PLSscores
global output SampleNames ExtraData
Pix_SS = get(0,'screensize'); %Get screen dimensions
fig1 = uifigure('units','pixels','Position',[Pix_SS(1,3)/4,Pix_SS(1,4)/3,150,410]);
for a =1:output.variables(2)
    uicheckbox(fig1,'Text',strcat('PC',num2str(a)),'Position',[10 410-20*a 102 15],'Value',1);
end
uibutton(fig1,'Text','Graph MD predict','Position',[60,250,90,25],'ButtonPushedFcn', @(btnPCA,event) plsSCORES(output.PLS.predictTRAINING,fig1.Children,SampleNames,1));
uibutton(fig1,'Text','Graph','Position',[60,220,50,25],'ButtonPushedFcn', @(btnPCA,event) plsSCORES(output.PLS.Scores,fig1.Children,SampleNames,2));
uibutton(fig1,'Text','Dendrogram','Position',[60,190,90,25],'ButtonPushedFcn', @(btnPCA,event)...
    dendrogram_plot(fig1.Children,output.variables,output.PLS.Scores,output.PLS.TScores,ExtraData));
uicheckbox(fig1,'Text','Extra Data?','Position',[60,160,200,25]); %Checkbox for Extra data, will be PCS 1
end
%% Miscellaneous functions
% Implements changes to replicate number, PCs to graph
function RepChange(Replicates,event)

global output
if output.variables(1,1)==1
    output.variables(1,1)=event.Value;
elseif length(fieldnames(output))>1
    if event.Value<size(output.trainingDATA,1)
        output.variables(1,1)=event.Value;
    else
        output.variables(1,1)=size(output.trainingDATA,1);
    end
else
    msgbox 'Check that the number of replicates does not exceed total number of samples'
    output.variables(1,1)=event.Value;
end
end

function TestRepChange(TestReplicates,event)

global output
if length(fieldnames(output))>1 && isfield(output,'testDATA')==1
    if event.Value<size(output.testDATA,1)
        output.variables(1,4)=event.Value;
    else
        output.variables(1,4)=size(output.testDATA,1);
    end
else
    msgbox 'Check that the number of replicates does not exceed total number of samples'
    output.variables(1,4)=event.Value;
end
end

function PC1Change(PC1,event)

global output
if output.variables(9)==1 || length(fieldnames(output))>1 && event.Value<=size(output.PCA.latent,1)
    output.variables(1,2)=event.Value;
    if output.variables(9)==1
        plsRUN
    end
else
    %output.variables(1,2)=event.Value;
    msgbox 'Error: PC number is more than the total number of PCs'
end
end

function PC2Change(PC2,event)

global output
if length(fieldnames(output))>1 && event.Value<=size(output.PCA.latent,1)|| output.variables(9)==1
    output.variables(1,3)=event.Value;
else
    %output.variables(1,3)=event.Value;
    msgbox 'Error: PC number is more than the total number of PCs'
end
end

function PLSlabel(event)
global temp
temp.PLSlabel=event.Value;
end

function CFChange(CF,event)

global output
output.variables(12)=CF.Value;

end

% Saves test, training and output variables into user defined file
function pcaSAVE
global training test output SampleNames ExtraData xVALUES Ytest Ytraining
% Find place to save data
[FileName, PathName] = uiputfile('PCA Output.mat');
if size(Ytraining,1)==0 % include PLS data if present
    clear global Ytraining Ytest
    save(strcat(PathName,FileName),'test','training','output','SampleNames','ExtraData','xVALUES')
else
    save(strcat(PathName,FileName),'test','training','output','SampleNames','ExtraData','xVALUES','Ytest','Ytraining')
end
end

% Open matlab file
function pcaOPEN
% Find place to open data
clear global temp
uiopen('*.mat')
global temp output
if size(output.variables,2)<11
    output.variables(11)=0;
end
if isfield(output,'trainingDATA')==1
    if output.variables(9)==1
        if isfield(output.PLS,'measuredTEST')==1
            temp.Ytest=output.PLS.measuredTEST;
        end
        temp.Ytraining=output.PLS.measuredTRAINING;
    end
    pcaGRAPH
end
end

% Hide test data
function scaleMS(evt)
global output
% Note that scaling also occurs in optimseTT
if evt.Value == 1
    output.variables(8)=1;
    output.trainingDATA(4:end,:)=output.trainingDATA(4:end,:)./output.trainingDATA(2,:).^0.5;
    if size(output.testDATA,1)>0
        output.testDATA=output.testDATA./output.trainingDATA(2,:).^0.5;
    end
else
    output.variables(8)=0;
    output.trainingDATA(4:end,:)=output.trainingDATA(4:end,:).*output.trainingDATA(2,:).^0.5;
    if size(output.testDATA,1)>0
        output.testDATA=(output.testDATA).*output.trainingDATA(2,:).^0.5;
    end
end
output.trainingDATA(isnan(output.trainingDATA))=0;
output.trainingDATA(isinf(output.trainingDATA))=0;
output.testDATA(isnan(output.testDATA))=0;
output.testDATA(isinf(output.testDATA))=0;
if output.variables(9)==0
    pcaRUN
else
    plsRUN
end
end

% Apply mean centring
function scaleSTD(evt)
global output
% Note that scaling also occurs in optimseTT
if evt.Value == 1
    output.variables(7)=1;
    output.trainingDATA(4:end,:)=(output.trainingDATA(4:end,:)-output.trainingDATA(2,:))./output.trainingDATA(3,:);
    if size(output.testDATA,1)>0
        output.testDATA=(output.testDATA-output.trainingDATA(2,:))./output.trainingDATA(3,:);
    end
else
    output.variables(7)=0;
    output.trainingDATA(4:end,:)=(output.trainingDATA(4:end,:)).*output.trainingDATA(3,:)+output.trainingDATA(2,:);
    if size(output.testDATA,1)>0
        output.testDATA=(output.testDATA).*output.trainingDATA(3,:)+output.trainingDATA(2,:);
    end
end
output.trainingDATA(isnan(output.trainingDATA))=0;
output.trainingDATA(isinf(output.trainingDATA))=0;
output.testDATA(isnan(output.testDATA))=0;
output.testDATA(isinf(output.testDATA))=0;
if output.variables(9)==0
    pcaRUN
else
    plsRUN
end
end

% Apply log/log for PLS
function logDATA(evt)
global output temp Ytest Ytraining
output.variables(10)=evt.Value;
if size(temp,1)==0 || isfield(temp,'Ytraining')==0
    pcaDATASET
end
if output.variables(10) == 1
    if size(temp.Ytest,1)>0
        temp.Ytest=log10(temp.Ytest);
    end
    temp.Ytraining=log10(temp.Ytraining);
else
    temp.Ytest=Ytest;
    temp.Ytraining=Ytraining;
end
plsRUN
end

% Functions to auto reduce X-variables
function autoREDUCE
global output temp XVariableNumbers ExtraData training test
temp.ExtraData=[];
x=0;
answer = questdlg('Generate new variable optimisation?', ...
    'Process','Yes','No','Yes');
if strcmp(answer,'')==1 % Cancel selection
    return
end
if strcmp(answer,'Yes')==1
    
    if output.variables(9)==1 % If PLS
        a1=questdlg('Select', ...
            'Recursive feature selection','Addition','Elimination','OPS','Addition');
        if strcmp(a1,'') == 1
            return
        elseif strcmp(a1,'Addition')==1
            RUN(1,1,0)
        elseif strcmp(a1,'Elimination')==1
            RUN(1,0,0)
        else
            output.PLS.OPS=OPS;
            plsRUN
        end
    else % If PCA
        Pix_SS = get(0,'screensize'); %Get screen dimensions
        fig1 = uifigure('units','pixels','Position',[Pix_SS(1,3)/4,Pix_SS(1,4)/3,150,410]);
        a1=20;
        if size(output.PCA.latent,1)<20
            a1=size(output.PCA.latent,1);
        end
        for a =1:a1
            uicheckbox(fig1,'Text',strcat('PC',num2str(a)),'Position',[10 410-20*a 102 15]);
        end
        uibutton(fig1,'Text','Addition','Position',[60,220,80,25],'ButtonPushedFcn', @(btnPCA,event) RUN(fig1.Children,1,a1));
        uibutton(fig1,'Text','Elimination','Position',[60,250,80,25],'ButtonPushedFcn', @(btnPCA,event) RUN(fig1.Children,0,a1));
        uibutton(fig1,'Text','A then E','Position',[60,190,80,25],'ButtonPushedFcn', @(btnPCA,event) RUN(fig1.Children,2,a1));
        uibutton(fig1,'Text','Looped','Position',[60,160,80,25],'ButtonPushedFcn', @(btnPCA,event) RUN(fig1.Children,3,a1));
    end
else
    RUN([],1)
end
XVariableNumbers = output.trainingDATA(1,:);
    function RUN(PCS,Type,PCmax)
        
        if strcmp(answer,'Yes')==1
            pcs=[];
            for x1=1:PCmax
                if PCS(PCmax+5-x1).Value==1
                    pcs(end+1)=x1;
                end
            end
            if Type==0 % RFE
                output.rOUTPUT=VariableOptimisation(output.trainingDATA(4:end,:),output.testDATA,output.variables(1,1),output.variables(1,4),pcs,output.variables(9),0);
                output.rOUTPUT(2:end+1,:)=output.rOUTPUT;
                output.rOUTPUT(1,1:end-1)=output.trainingDATA(1,:);
            elseif Type == 1 % RFA
                total = inputdlg('How many total variables do you wish to assess?');
                if size(total,1)==0 % what happens with cancel
                    return
                end
                total=str2num(total{1});
                output.rOUTPUT=RecursiveAddition(training,test,output.trainingDATA,output.testDATA,output.variables(1,1),output.variables(1,4),pcs,total,0);
                output.rOUTPUT(2:end+1,:)=output.rOUTPUT;
                output.rOUTPUT(1,1:end-1)=1:size(output.rOUTPUT,2)-1;
            elseif Type == 2 % Addition then Elimination
                total = inputdlg('How many total variables do you wish to assess?');
                if size(total,1)==0 % what happens with cancel
                    return
                end
                total=str2num(total{1});
                output.rOUTPUT=RecursiveAddition(training,test,output.trainingDATA,output.testDATA,output.variables(1,1),output.variables(1,4),pcs,total,1);
                output.rOUTPUT(2:end+1,:)=output.rOUTPUT;
                output.rOUTPUT(1,1:end-1)=1:size(output.rOUTPUT,2)-1;
                
                % Apply RCA outputs
                autoREDUCE_Implement(total)
                if size(ExtraData,2)>0
                    temp.ExtraData=[];
                    for x2=1:size(output.trainingDATA,2)
                        temp.ExtraData(:,x2)=ExtraData(:,output.trainingDATA(1,x2));
                    end
                end
                output.trainingDATA(isnan(output.trainingDATA)==1)=0;
                output.testDATA(isnan(output.testDATA)==1)=0;
                if output.variables(9)==0
                    pcaRUN
                else
                    plsRUN
                end
                % RFE
                output.rOUTPUT=VariableOptimisation(output.trainingDATA(4:end,:),output.testDATA,output.variables(1,1),output.variables(1,4),pcs,output.variables(9),1);
                output.rOUTPUT(2:end+1,:)=output.rOUTPUT;
                output.rOUTPUT(1,1:end-1)=output.trainingDATA(1,:);
            elseif Type == 3 % Addition then Elimination looped
                prompt = {'Features to add','Minimum features','Loops'};
                title = 'Input Loop Variables';
                dims = [1 40];
                definput = {'20','10','20'}; % default inputs
                dims = inputdlg_track(prompt,title,dims,definput);
                if size(dims,1)==0
                    return
                end
                output.log=LoopRFA_RFE(pcs,str2num(dims{1}),str2num(dims{2}),str2num(dims{3}));
            end
            if size(output.rOUTPUT,2)==0 % error management
                return
            end
            if Type == 2
                output.rOUTPUT(1,end)=0;
            else
                output.rOUTPUT(1,end)=Type;
            end
            if output.variables(9)==0 && Type < 2
                close(fig1)
            end
        end
        
        temp.modifier = output.trainingDATA;
        temp.test = output.testDATA;
        x3=1;
        while x3 == 1 && Type ~= 3
            output.trainingDATA=temp.modifier;
            output.testDATA=temp.test;
            %pcaDATASET m.Value=1; scaleSTD(m)
            x3=2;
            h=figure;
            grid on
            grid minor
            hold on
            xset=1:size(output.rOUTPUT,1)-1-2*output.rOUTPUT(1,end);
            if output.rOUTPUT(1,end) == 0
                xset=size(output.rOUTPUT,1)-xset+2;
            end
            %yyaxis left
            plot(xset,output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))
            if output.variables(9)==0 % Check it is PCA
                ylabel('Separation') % Will always show separation
                
                if output.rOUTPUT(1,end) == 0 && max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))<1
                    %yyaxis right
                    %plot(xset,output.rOUTPUT(end,1:size(xset,2)))
                    ylabel('Mean area fraction not overlapping')
                elseif output.rOUTPUT(1,end) == 1
                    yyaxis right
                    plot(xset,output.rOUTPUT(end,size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+1:size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+size(xset,2)))
                    ylabel('Mean area fraction not overlapping')
                end
                
            else
                ylabel('Coefficient of determination')
            end
            set(gca,'FontName','Calibri','FontSize',14);
            xlabel('# variables')
            
            %ylabel('Separation')
            if output.variables(9)==0 && output.rOUTPUT(1,end) == 1
                maxVAL = strcat('How many variables do you wish to select? Overlap Max=',...
                    num2str(xset(find(output.rOUTPUT(end,size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+1:size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+size(xset,2))==max(output.rOUTPUT(end,size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+1:size(find(output.rOUTPUT(end-1,:)>0),2)-size(find(output.rOUTPUT(end,:)>0),2)+size(xset,2)))))),...
                    ':Separation Max=',num2str(xset(find(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)==max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))))));
            else
                maxVAL = strcat('How many variables do you wish to select? Max=',...
                    num2str(xset(find(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end)==max(output.rOUTPUT(2:end-2*output.rOUTPUT(1,end),end))))));
            end
            x = inputdlg(maxVAL);
            if size(x,1)==0 % what happens with cancel
                return
            end
            x=str2num(x{1});
            close(h)
            autoREDUCE_Implement(x)
            if size(ExtraData,2)>0
                temp.ExtraData=[];
                for x2=1:size(output.trainingDATA,2)
                    temp.ExtraData(:,x2)=ExtraData(:,output.trainingDATA(1,x2));
                end
            end
            output.trainingDATA(isnan(output.trainingDATA)==1)=0;
            output.testDATA(isnan(output.testDATA)==1)=0;
            if output.variables(9)==0
                pcaRUN
            else
                plsRUN
            end
            answer = questdlg('Accept number of variables?');
            if strcmp(answer,'No')==1
                x3=1;
            end
        end
        
        pcaGRAPH
    end
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

% Do LASSO for PLS
function LASSO
close all
% The features that provide the min square error are selected
global output temp
[a,b]=LASSOFeatureSelection(output.trainingDATA(4:end,:),temp.Ytraining,output.trainingDATA(1,:));
% implement LASSO sparse dataset
for x1=1:size(a,2)
    a1=find(output.trainingDATA(1,:)==str2double(a{1,x1}));
    output.trainingDATA(:,x1)=output.trainingDATA(:,a1);
    if size(output.testDATA,1)>0
        output.testDATA(:,x1)=output.testDATA(:,a1);
    end
end
output.trainingDATA(:,x1+1:end)=[];
if size(output.testDATA,1)>0
    output.testDATA(:,x1+1:end)=[];
end
% Plot LASSO regression
output.PLS.RegressionVector=b;
output.PLS.measuredTRAINING=temp.Ytraining;
if size(output.testDATA,1)>0
    output.PLS.measuredTEST=temp.Ytest;
end
output.PLS.predictTRAINING=output.trainingDATA(4:end,:)*b;
if size(output.testDATA,1)>0
    output.PLS.predictTEST=output.testDATA*b;
end
%plot of measured versus predicted
Pix_SS = get(0,'screensize'); %Get screen dimensions
figure('Name','LASSO regression','Position',[10+Pix_SS(1,3)/15+50,50+Pix_SS(1,4)/2,Pix_SS(1,4)/2.7,Pix_SS(1,4)/2.7]);
if size(output.PLS.measuredTEST,1)>0
    plot(output.PLS.measuredTRAINING,output.PLS.predictTRAINING,'ko',output.PLS.measuredTEST,output.PLS.predictTEST,'r^');
else
    plot(output.PLS.measuredTRAINING,output.PLS.predictTRAINING,'ko');
end
xlabel('Measured');
ylabel('Predicted');
set(gca,'FontName','Calibri','FontSize',16);
pos=get(gcf,'Position');
pos(3)=pos(4);
set(gcf,'Position',pos);
box off
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end
% Follow with PLS
%plsRUN
end

% Do Sparse PCA
function runSPCA
global output temp
x1=1;
temp.modifier = output.trainingDATA;
temp.test = output.testDATA;
while x1 == 1
    x1=0;
    output.trainingDATA=temp.modifier;
    output.testDATA=temp.test;
    x = inputdlg({'How many variables do you wish to reduce to?','How many PCs to consider?'},...
        'sPCA Selection');
    addpath('C:\Users\pazalh\OneDrive - The University of Nottingham\Documents\MATLAB\Stats\SpaSM')
    SL = spca(output.trainingDATA(4:end,:),[],str2double(x{2}),Inf,-str2double(x{1}),10000);
    for a =1:size(output.trainingDATA,2)
        if sum(SL(a,:))==0
            output.trainingDATA(2:end,a)=0;
            if size(output.testDATA,1)>0
                output.testDATA(:,a)=0;
            end
        end
    end
    pcaRUN
    nnz(output.trainingDATA(4,:))
    answer = questdlg('Accept number of variables?');
    if strcmp(answer,'No')==1
        x1=1;
    end
end
end

% Filter X variables based upon VIP value in PLS
function VIP
global output
c2=0;
for c1 = 1:size(output.trainingDATA,2)
    if output.PLS.VIP(c1)>=1
        c2=c2+1;
        output.trainingDATA(:,c2)=output.trainingDATA(:,c1);
        output.testDATA(:,c2)=output.testDATA(:,c1);
    end
end
if c2 < c1
    output.trainingDATA(:,c2+1:end)=[];
    output.testDATA(:,c2+1:end)=[];
end
plsRUN
end

% Optimise the training and test sets
function optimiseTT
global output temp training
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
        if output.variables(9)==0
            pcaRUN
        else
            plsRUN
        end
    end
end
end

% Turn on/off collective optimisation
function oPT(evt)
global output
output.variables(1,5)=evt.Value;
end

% Turn on/off transparent background for Scores plot
function tBKG(evt)
global output
output.variables(1,6)=evt.Value;
pcaGRAPH
end

% Split data into training/test
function split(varargin)
% Script to split or combine training and test sets Andrew Hook August 2024
% Can use varargin to input new training and test set number


%%SETUP
global training test output temp Ytraining Ytest
trainingN = output.variables(1);
testN = output.variables(4);
answer = 1;
if testN == 0
    splitYN = 1;
    if length(varargin) ==0
        prompt = {'New training size:','New test size:'};
        dlgtitle = 'Input';
        fieldsize = [1 45; 1 45];
        definput = {num2str(ceil(trainingN/2)),num2str(floor(trainingN/2))};
        answer = inputdlg(prompt,dlgtitle,fieldsize,definput);
        if size(answer,1)>0
            trainingN=str2double(answer{1});
            testN=str2double(answer{2});
        end
    else
        trainingN=varargin{1};
        testN=varargin{2};
    end
else
    splitYN = 0;
end
totalREPS = trainingN + testN;


%% Readout variables
temp1=temp;
training1=training;
output1 = output;
test1=test;
Ytraining1=Ytraining;
Ytest1=Ytest;

if size(answer,1)>0 % Manage cancel
    reps = (size(output1.trainingDATA,1)-3)/totalREPS;
    %% Run split
    if splitYN == 1 % split training set into training and test
        
        % Split x data test
        for a1= 1:reps
            % whole set
            test1(1+(a1-1)*testN:a1*testN,:)=training1(1+a1*totalREPS-testN:a1*totalREPS,:);
            % spare set
            output1.testDATA(1+(a1-1)*testN:a1*testN,:)=output1.trainingDATA(3+1+a1*totalREPS-testN:3+a1*totalREPS,:);
            % sample numbers
            output1.sampleNUMBERS(2,1+(a1-1)*testN:a1*testN)=output1.sampleNUMBERS(1,1+a1*totalREPS-testN:a1*totalREPS);
        end
        % training
        for a1= 1:reps
            % whole set
            training1(1+(a1-1)*trainingN:trainingN*a1,:)=training1(1+(a1-1)*totalREPS:totalREPS*a1-testN,:);
            % spare set
            output1.trainingDATA(3+1+(a1-1)*trainingN:3+trainingN*a1,:)=output1.trainingDATA(3+1+(a1-1)*totalREPS:3+totalREPS*a1-testN,:);
            % sample numbers
            output1.sampleNUMBERS(1,1+(a1-1)*trainingN:trainingN*a1)=output1.sampleNUMBERS(1,1+(a1-1)*totalREPS:totalREPS*a1-testN);
        end
        training1(reps*trainingN+1:end,:)=[];
        output1.trainingDATA(3+reps*trainingN+1:end,:)=[];
        output1.sampleNUMBERS(:,max(testN,trainingN)*reps+1:end)=[];
        % Split y data
        if size(Ytraining1,1)>0
            count1 = 0;
            % test
            for a1= 1:reps
                % whole set
                Ytest1(1+(a1-1)*testN:a1*testN,:)=Ytraining1(1+a1*totalREPS-testN:a1*totalREPS,:);
                % spare set
                try
                    temp1.Ytest(1+(a1-1)*testN:a1*testN,:)=temp1.Ytraining(1+a1*totalREPS-testN:a1*totalREPS,:);
                catch
                    count1 = count1 +1;
                end
            end
            % training
            for a1= 1:reps
                % whole set
                Ytraining1(1+(a1-1)*trainingN:trainingN*a1,:)=Ytraining1(1+(a1-1)*totalREPS:totalREPS*a1-testN,:);
                % spare set
                try
                    temp1.Ytraining(1+(a1-1)*trainingN:trainingN*a1,:)=temp1.Ytraining(1+(a1-1)*totalREPS:totalREPS*a1-testN,:);
                catch
                end
            end
            Ytraining1(reps*trainingN+1:end,:)=[];
            temp1.Ytraining((reps-count1)*trainingN+1:end,:)=[];
        end
        output1.variables(1)=trainingN;
        output1.variables(4)=testN;
    else % integrate test set into training set        
        reps = (size(output1.trainingDATA,1)-3)/trainingN;
        hold1=training1;
        hold2=output1.trainingDATA;
        hold3=output1.sampleNUMBERS;
        % Split x data training
        for a1= 1:reps
            % whole set
            training1(1+(a1-1)*totalREPS:totalREPS*a1-testN,:)=hold1(1+(a1-1)*trainingN:trainingN*a1,:);
            % spare set
            output1.trainingDATA(3+1+(a1-1)*totalREPS:3+totalREPS*a1-testN,:)=hold2(3+1+(a1-1)*trainingN:3+trainingN*a1,:);
            % sample numbers
            output1.sampleNUMBERS(1,1+(a1-1)*totalREPS:totalREPS*a1-testN,:)=hold3(1,1+(a1-1)*trainingN:trainingN*a1,:);
        end
        % test
        for a1= 1:reps
            % whole set
            training1(a1*totalREPS-testN+1:a1*totalREPS,:)=test1(1+(a1-1)*testN:a1*testN,:);
            % spare set
            output1.trainingDATA(3+a1*totalREPS-testN+1:3+a1*totalREPS,:)=output1.testDATA(1+(a1-1)*testN:a1*testN,:);
            % sample numbers
            output1.sampleNUMBERS(1,a1*totalREPS-testN+1:a1*totalREPS,:)=output1.sampleNUMBERS(2,1+(a1-1)*testN:a1*testN,:);
        end
        test1=[];
        output1.testDATA=[];
        output1.sampleNUMBERS(2,:)=0;
        % Split y data
        if size(Ytraining1,1)>0
            hold1=Ytraining1;
            if isfield(temp1,'Ytraining') == 1
                hold2=temp1.Ytraining;
            else
                hold2=Ytraining1;
                temp1.Ytest=Ytest;
            end
            % Split x data training
            for a1= 1:reps
                % whole set
                Ytraining1(1+(a1-1)*totalREPS:totalREPS*a1-testN,:)=hold1(1+(a1-1)*trainingN:trainingN*a1,:);
                % spare set
                try
                    temp1.Ytraining(1+(a1-1)*totalREPS:totalREPS*a1-testN,:)=hold2(1+(a1-1)*trainingN:trainingN*a1,:);
                catch
                end
            end
            % test
            for a1= 1:reps
                % whole set
                Ytraining1(a1*totalREPS-testN+1:a1*totalREPS,:)=Ytest1(1+(a1-1)*testN:a1*testN,:);
                % spare set
                try
                    temp1.Ytraining(a1*totalREPS-testN+1:a1*totalREPS,:)=temp1.Ytest(1+(a1-1)*testN:a1*testN,:);
                catch
                end
            end
            Ytest1=[];
            temp1.Ytest=[];
        end
        output1.variables(1)=totalREPS;
        output1.variables(4)=0;
    end
    
    %% Readin variables
    temp=temp1;
    training=training1;
    output = output1;
    test=test1;
    Ytraining=Ytraining1;
    Ytest=Ytest1;
    
    %% Run PCA/PLS
    
    if output.variables(9) ==0
        pcaRUN
    else
        if size(temp.Ytest,1)>0 % Don't run automatically if requires LOO method of cross-validation
            plsRUN
        end
    end
    
    
    
end
end

%% Functions for reducing X-variables
% function setup figure to reduce x-measurements
function pcaREDUCE(boxSCALING)
warning off
global training test output temp
% Create temp file selecting which PCs are on/off
temp.PCS=[];
temp.PCS(1:size(output.PCA.loadings,2),1)=0;
temp.modifier=[];
temp.modifier(1:size(output.trainingDATA,2),1)=1;
temp.test=[];
temp.test(1:size(output.trainingDATA,2),1)=0;

% Select which PC to reduce data by
Pix_SS = get(0,'screensize');
pcS = size(output.PCA.loadings,2);
height = round(Pix_SS(1,4)/2.7,0);
WD=ceil((25*pcS)/(height-25));
X1 = floor((height-25)/25);
fig1 = uifigure('units','pixels','Position',...
    [20+Pix_SS(1,3)/15+50,Pix_SS(1,4)/2,70*(WD)+140,height]);

% Setup Check boxes
for i = 1:pcS
    j=ceil(i/X1)-1; % Box offset in x
    k=rem(i,X1); % Box offset in y
    if k == 0
        k=X1;
    end
    box(i,1) = uicheckbox(fig1,...
        'text',strcat('PC',num2str(i)),...
        'position',[20+70*j height-k*25 50 20],...
        'ValueChangedFcn',@(src,evt)mycb(src,evt,i));
end
% Setup scroll bars
uilabel(fig1,'Text','Loadings Filter',...
    'position',[20+70*(j+1),height/2+110,100,30]);
uilabel(fig1,'Text','Value   Variables',...
    'position',[20+70*(j+1),height/2+90,100,30]);
numVar = uilabel(fig1,'Text',num2str(size(output.trainingDATA,2)),...
    'position',[20+70*(j+1)+40,height/2+70,100,30]);
slidValue = uilabel(fig1,'Text','0',...
    'position',[20+70*(j+1)+5,height/2+70,100,30]);
uilabel(fig1,'Text','Peak Height Filter',...
    'position',[20+70*(j+1),height/2,100,30]);
uilabel(fig1,'Text','Min',...
    'position',[20+70*(j+1),height/2-20,100,30]);
uilabel(fig1,'Text','Max',...
    'position',[20+70*(j+1),height/2-80,100,30]);
numMIN = uilabel(fig1,'Text','0',...
    'position',[20+70*(j+1)+40,height/2-20,100,30]);
numMAX = uilabel(fig1,'Text','100',...
    'position',[20+70*(j+1)+40,height/2-80,100,30]);
slidPCS = uislider(fig1,...
    'position',[20+70*(j+1),height/2+65,100,30],...
    'ValueChangedFcn',@(sld,event)updateSLIDER(1,event,slidValue,numVar,numMIN,numMAX));
slidMIN = uislider(fig1,...
    'position',[20+70*(j+1),height/2-25,100,30],...
    'ValueChangedFcn',@(sld,event)updateSLIDER(2,event,slidValue,numVar,numMIN,numMAX));
slidMAX = uislider(fig1,...
    'position',[20+70*(j+1),height/2-85,100,30],...
    'Value',100,'ValueChangedFcn',@(sld,event)updateSLIDER(3,event,slidValue,numVar,numMIN,numMAX));

% Setup Apply button
btnAPPLY = uibutton(fig1,'Text','Apply',...
    'Position',[20+70*(j+1),20,50,30],...
    'ButtonPushedFcn', @(btnAPPLY,event) apply(boxSCALING.Value));
warning on
end

% Function to log PC selection
function mycb(src,evt,i)
global temp output
if temp.PCS(i,1)==0
    temp.PCS(i,1)=1;
else
    temp.PCS(i,1)=0;
end
temp.test=abs(output.PCA.loadings)*temp.PCS;
end

% Function to apply scroll bar to data selection
function updateSLIDER(type,event,slidValue,numVar,numMIN,numMAX)
% Update from event to correct variable
if type == 1
    slidValue.Text=num2str(event.Value);
elseif type == 2
    numMIN.Text=num2str(event.Value);
elseif type == 3
    numMAX.Text=num2str(event.Value);
end

global temp output
threshold1 = str2double(slidValue.Text)*max(temp.test)/100;
threshold2 = str2double(numMIN.Text)*max(output.trainingDATA(2,:))/100;
threshold3 = str2double(numMAX.Text)*max(output.trainingDATA(2,:))/100;
temp.modifier=[];
temp.modifier(1:size(temp.test,1),1)=1;

for a =1 :size(temp.test,1)
    if temp.test(a,1)<threshold1 || output.trainingDATA(2,a)<=threshold2 || output.trainingDATA(2,a)>threshold3
        temp.modifier(a,1)=0;
    end
end
temp.PC1=output.PCA.loadings(:,output.variables(1,2)).*temp.modifier;
temp.PC2=output.PCA.loadings(:,output.variables(1,3)).*temp.modifier;
numVar.Text=strcat(num2str(sum(temp.modifier)),...
    ' (',num2str(round(sum(temp.modifier)/size(output.trainingDATA,2)*100)),'%)');
end

% Functions to remove X-variables associated with Orbi noise
function oFILTER(evt)
global temp output training xVALUES
%Create temp file
if evt.Value == 1
    if size(xVALUES,2)==size(training,2)
        output.variables(11)=1;
        % Get user input Select which PC to reduce data by
        %Peak ranges. Add more ranges, will automatically update
        % To add new range copy and paste the line from below to insert in
        % or at the end of the list and update with new values
        i=1;
        temp.oFILTER{1,i}.PeakRange='78.054 to 78.123';i=i+1;
        temp.oFILTER{1,i}.PeakRange='86.967 to 87.046';i=i+1;
        temp.oFILTER{1,i}.PeakRange='97.490 to 97.590';i=i+1;
        temp.oFILTER{1,i}.PeakRange='110.068 to 110.162';i=i+1;
        temp.oFILTER{1,i}.PeakRange='125.230 to 125.343';i=i+1;
        temp.oFILTER{1,i}.PeakRange='134.022 to 134.132*';i=i+1;
        temp.oFILTER{1,i}.PeakRange='143.770 to 143.885';i=i+1;
        temp.oFILTER{1,i}.PeakRange='166.760 to 166.872';i=i+1;
        temp.oFILTER{1,i}.PeakRange='195.670 to 195.841';i=i+1;
        temp.oFILTER{1,i}.PeakRange='232.070 to 232.310';i=i+1;
        temp.oFILTER{1,i}.PeakRange='232.960 to 233.067';i=i+1;
        temp.oFILTER{1,i}.PeakRange='281.770 to 282.020';i=i+1;
        temp.oFILTER{1,i}.PeakRange='347.970 to 348.160';i=i+1;
        
        Pix_SS = get(0,'screensize');
        pcS = size(temp.oFILTER,2);
        height = pcS*30+50;
        WD=150;
        X1 = floor((height-25)/25);
        fig1 = uifigure('units','pixels','Position',...
            [20+Pix_SS(1,3)/15+50,Pix_SS(1,4)/10,WD,height]);
        % Setup Check boxes
        if length(fieldnames(temp.oFILTER{1,1}))<2 || size(output.trainingDATA,2)==size(training,2)
            temp.oFILTER{2,1}=0;
        end
        for i = 1:pcS
            % Add values for boxes if first time
            if length(fieldnames(temp.oFILTER{1,i}))<2
                temp.oFILTER{1,i}.Value=0;
            end
            
            % Extract mass data for each range
            temp.oFILTER{1,i}.low=str2num(strrep(extractBefore(temp.oFILTER{1,i}.PeakRange,strfind(temp.oFILTER{1,i}.PeakRange,'to')-1),'*',''));
            temp.oFILTER{1,i}.high=str2num(strrep(extractAfter(temp.oFILTER{1,i}.PeakRange,strfind(temp.oFILTER{1,i}.PeakRange,'to')+2),'*',''));
            
            j=ceil(i/X1)-1; % Box offset in x
            k=rem(i,X1); % Box offset in y
            if k == 0
                k=X1;
            end
            box(i,1) = uicheckbox(fig1,...
                'text',temp.oFILTER{1,i}.PeakRange,...
                'position',[20+70*j height-k*25 200 20],...
                'Value',temp.oFILTER{1,i}.Value,...
                'ValueChangedFcn',@(src,evt)boxCHANGE(src,evt,i));
        end
        uilabel(fig1,'Text','*Noise intermitent',...
            'position',[20,75,100,30]);
        % Setup select all buttons
        btnSELECT = uibutton(fig1,'Text','Select All',...
            'Position',[5,45,70,30],...
            'ButtonPushedFcn', @(btnSELECT,event) select(pcS,box));
        btnCLEAR = uibutton(fig1,'Text','Clear All',...
            'Position',[75,45,70,30],...
            'ButtonPushedFcn', @(btnCLEAR,event) clear(pcS,box));
        % Setup Apply button
        btnAPPLY = uibutton(fig1,'Text','Apply',...
            'Position',[5,10,70,30],...
            'ButtonPushedFcn', @(btnAPPLY,event) applyFILTER(pcS));
    else
        msgbox 'Add m/z data to xVALUES variable'
    end
else
    output.variables(11)=0;
    
end
% functions to implement box ticking
    function select(pcS,box)
        for l = 1:pcS
            box(l,1).Value = 1;
            temp.oFILTER{1,l}.Value=1;
        end
    end
    function clear(pcS,box)
        for l = 1:pcS
            box(l,1).Value = 0;
            temp.oFILTER{1,l}.Value=0;
        end
    end
    function boxCHANGE(src,evt,i)
        temp.oFILTER{1,i}.Value=evt.Value;
    end
end

function applyFILTER(pcS)
global output temp xVALUES test
c1=0;
for x1 = 1:size(output.trainingDATA,2)
    c1 = c1+1;
    c2 = 0;
    v1=xVALUES(x1);
    for x2 = 1:pcS
        if temp.oFILTER{1,x2}.Value == 1 && v1>temp.oFILTER{1,x2}.low && v1<temp.oFILTER{1,x2}.high
            c1=c1-1;
            c2=1;
            break
        end
    end
    if c2 == 0
        output.trainingDATA(:,c1)=output.trainingDATA(:,x1);
        if size(test,1)>0
            output.testDATA(:,c1)=output.testDATA(:,x1);
        end
    end
end
if x1>c1
    output.trainingDATA(:,c1+1:end)=[];
    if size(test,1)>0
        output.testDATA(:,c1+1:end)=[];
    end
    temp.oFILTER{2,1}=temp.oFILTER{2,1}+x1-c1;
end
if output.variables(9)==0
    pcaRUN
else
    plsRUN
end
end

% Function to Apply PC data selection
function apply(box)
% Close reduce function
close all force
UISetup(box)

% Apply value and remove PCs
global output temp
x1=output.trainingDATA;
x2=output.testDATA;
x3=temp.test;
output.trainingDATA=[];
output.testDATA=[];
temp.test=[];
for a =1:size(temp.modifier,1)
    if temp.modifier(a,1)==1
        output.trainingDATA(:,end+1)=x1(:,a);
        output.testDATA(:,end+1)=x2(:,a);
        temp.test(end+1,1)=x3(a,1);
    end
end

output.log(end+1,1:size(output.trainingDATA,2))=output.trainingDATA(1,:);
% Re-runs PCA
pcaRUN
end

function reduceRED
% function to sequentially remove most redundant variables from PCA x =
% inputdlg('How many PCs do you wish to measure redundancy for?');
% x=str2num(x{1});
global output temp
% loop to measure redundancy of each
a1=redundant(output.trainingDATA(4:end,:));
logbook=max(a1);
% for x1=1:size(output.PCA.loadings,1)
%     logbook(x1,2)=max(max(a1)); if logbook(x1,2)==0
%         break
%     end logbook(x1,1)=find(max(a1)==logbook(x1,2));
% 	a1(:,logbook(x1,1))=0; %logbook(x1,1:2)=a1; %[output.PCA.loadings] =
% 	pca(output.trainingDATA(4:end,:));
% end
h=figure;
bar(logbook)
x = inputdlg('What maximum coefficient of determination do you want to allow (0-1)?');
x=str2num(x{1});
while x < 0 || x>1
    x = inputdlg('Select a maximum coefficient of determination between 0 and 1)?');
    x=str2num(x{1});
end
close(h)
output.rOUTPUT=logbook;
% Rebuild output.trainingDATA

% Implement variable selection
if x>0
    training=[];
    test=[];
    Extra=[];
    for x1=1:size(output.trainingDATA,2)
        if logbook(1,x1)<=x
            training(:,end+1)=output.trainingDATA(:,x1);
            if size(output.testDATA,1)>0
                test(:,end+1)=output.testDATA(:,x1);
            end
            if size(temp.ExtraData,1)>0
                Extra(:,end+1)=temp.ExtraData(:,x1);
            end
        end
    end
    output.trainingDATA=training;
    if size(output.testDATA,1)>0
        output.testDATA=test;
    end
    if size(temp.ExtraData,1)>0
        temp.ExtraData=Extra;
    end
    if output.variables(9)==0
        pcaRUN
    else
        plsRUN
    end
end
    function y = redundant(variables)
        % function to identify most redundant variables variables should be
        % in different columns will output r values comparing all variables
        % to all other variables
        for x2=1:size(variables,2)-1
            for x3=x2+1:size(variables,2)
                r1=corrcoef(variables(:,x2),variables(:,x3));
                y(x2,x3)=r1(2,1);
            end
        end
        
        %r2(r2==1)=0; p1=max(r2); y(1,1)=find(p1==max(p1)); y(1,2)=max(p1);
    end
end

%% Data administration
% Reset to data saved in output
function pcaRESET(boxSCALING)
global temp output ExtraData
temp.test=[];
boxSCALING.Value=0;
output.trainingDATA=[];
output.testDATA=[];
output.PCA.loadings=[];
output.PCA.scores=[];
output.PCA.latent=[];
output.PCA.tsquared=[];
output.PCA.explained=[];
output.PCA.mu=[];
output.PCA.ConfidenceEllipses=[];
output.PCA.TestScores=[];
temp.ExtraData=ExtraData;
output.variables(10)=0;
output.variables(11)=0;

pcaDATASET
% Check if any Nan values in XData
a2=0;
for a1=1:size(output.trainingDATA,2)
    
    if size(output.testDATA,1)==0 && sum(isnan(output.trainingDATA(:,a1)))==0 || sum(isnan(output.trainingDATA(:,a1)))==0 && sum(isnan(output.testDATA(:,a1)))==0
        a2=a2+1;
        output.trainingDATA(:,a2)=output.trainingDATA(:,a1);
        if size(output.testDATA,1)>0
            output.testDATA(:,a2)=output.testDATA(:,a1);
        end
    else
        a2 = a2;
    end
end
if a2<a1
    output.trainingDATA(:,a2+1:end)=[];
    output.testDATA(:,a2+1:end)=[];
end
% Apply scalings
if output.variables(7)==1 || output.variables(8)==1 || output.variables(10)==1 && output.variables(9)==1
    if output.variables(7)==1
        evt.Value=1;
        scaleSTD(evt)
    end
    if output.variables(8)==1
        evt.Value=1;
        scaleMS(evt)
    end
    if output.variables(10)==1
        evt.Value=1;
        logDATA(evt)
    end
else
    if output.variables(9)==0
        pcaRUN
    else
        plsRUN
    end
end
end

function pcaDATASET
global training test output XVariableNumbers Ytraining Ytest temp
XVariableNumbers=[];
training(isnan(training(:,:))==1)=0.001;
test(isnan(test(:,:))==1)=0.001;
for x1=1:size(training,2)
    XVariableNumbers(x1)=x1;
end
output.trainingDATA=XVariableNumbers;
output.trainingDATA(4:size(training,1)+3,1:size(training,2))=training;
output.trainingDATA(2,:)=mean(output.trainingDATA(4:end,:),1);
output.trainingDATA(3,:)=std(output.trainingDATA(4:end,:)-output.trainingDATA(2,:),[],1);
output.testDATA=test;
output.sampleNUMBERS=1:size(output.trainingDATA,1)-3;
output.sampleNUMBERS(2,1:size(output.testDATA,1))=size(output.trainingDATA,1)-3+1:size(output.trainingDATA,1)-3+size(output.testDATA,1);
if isfield(temp,'Ytraining')==1
    temp.Ytraining=Ytraining;
    temp.Ytest=Ytest;
end

end

function clearALL
c1=questdlg('Clear all will delete all entered data. Continue?',...
    'Confirm',...
    'Yes','Cancel','Cancel');
if strcmp(c1,'Yes')==1
    global training test output temp ExtraData SampleNames xVALUES Ytest Ytraining
    output=[];
    temp=[];
    output.variables=[1,1,2,0,0,0,0,0,0,0];
    output.log=[];
    output.omit=[]; % option to turn off datasets from graphing. Dataset number added will cause dataset to not be plotted. If add number 2000 to omit will turn off legend.
    ExtraData=[];
    SampleNames=[];
    SampleNames{1,1}='1';
    xVALUES=[];
    temp.ExtraData=ExtraData;
    test=[];
    training=[];
    Ytest=[];
    Ytraining=[];
end
close all
end