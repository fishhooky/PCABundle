function log = OPS
%% Function to run ordered predictors selector to create a sparse dataset
% Runs as a part of the PCA bundle

%% Setup initial conditions
global training test output Ytest Ytraining

[residuals,RV,yfitPLS,TestfitPLS,r2]=PLS;

refRV(:,1)=abs(RV);
refRV(:,2)=transpose(output.trainingDATA(1,:));
refRV=sortrows(refRV,'descend');
refTrain = output.trainingDATA;
refTest = output.testDATA;
refLV = output.variables(3);

%% Iterate PLS
output.trainingDATA=[];
output.testDATA=[];
% Build base set
for x1=1:output.variables(2)
    output.trainingDATA(:,x1)=refTrain(:,find(refTrain(1,:)==refRV(x1,2)));
    if size(refTest,1)>0
        output.testDATA(:,x1)=refTest(:,find(refTrain(1,:)==refRV(x1,2)));
    end
end
total = inputdlg('How many variables do you wish to assess?','Total features',[1 25],{num2str(size(refRV,1)-1)});
if size(total,1)==0 % what happens with cancel
    return
end
total=str2double(total{1});
if total > size(refRV,1)-1
    total = size(refRV,1)-1;
end
for x1 = output.variables(2)+1:total
    strcat(num2str(x1),' of ',num2str(total))
    output.trainingDATA(:,x1)=refTrain(:,find(refTrain(1,:)==refRV(x1,2)));
    if size(refTest,1)>0
        output.testDATA(:,x1)=refTest(:,find(refTrain(1,:)==refRV(x1,2)));
    end
    [residuals,RV,yfitPLS,TestfitPLS,r2]=PLS;
    % log the RMSECV score
    log(x1,1)=r2(output.variables(2),5);
end
%% Select number of features
figure;
plot(log);
grid minor
ylabel('RMSECV')
xlabel('Features')
total = inputdlg('How many variables do you wish to select?');
if size(total,1)==0 % what happens with cancel
    return
end
total=str2double(total{1});
%% Finalise and clean up
output.trainingDATA=[];
output.testDATA=[];
for x1=1:total
    output.trainingDATA(:,x1)=refTrain(:,find(refTrain(1,:)==refRV(x1,2)));
    if size(refTest,1)>0
        output.testDATA(:,x1)=refTest(:,find(refTrain(1,:)==refRV(x1,2)));
    end
end
output.variables(3) = refLV;
