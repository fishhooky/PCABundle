function TT11

%% Change training and test datasets to 50:50
% Andrew Hook 2023
% Designed to change existing training test datasets to a 1:1 ratio
% To be run once data already open in PCA

global output test training Ytest Ytraining temp

test1=test;
training1=training;

trainingN = output.variables(1);
testN = output.variables(4);

Ndiff = floor((trainingN - testN)/2);

datasets = size(test,1)/testN;

for a = 1:datasets
    % Make room in test
    test1(a*(testN+Ndiff)+1:end+Ndiff,:)=test1(a*(testN+Ndiff)+1-Ndiff:end,:);
    % Transfer data from training
    test1(a*(testN+Ndiff)+1-Ndiff:a*(testN+Ndiff),:)=training1(a*(trainingN-Ndiff)+1:a*trainingN-(a-1)*Ndiff,:);
    % Remove samples from training
    training1(a*(trainingN-Ndiff)+1:end-Ndiff,:)=training1(a*trainingN-(a-1)*Ndiff+1:end,:);
    % Resize training
    training1(end-Ndiff+1:end,:)=[];
    
    output.testDATA(a*(testN+Ndiff)+1:end+Ndiff,:)=output.testDATA(a*(testN+Ndiff)+1-Ndiff:end,:);
    output.testDATA(a*(testN+Ndiff)+1-Ndiff:a*(testN+Ndiff),:)=output.trainingDATA(3+a*(trainingN-Ndiff)+1:3+a*trainingN-(a-1)*Ndiff,:);
    output.trainingDATA(3+a*(trainingN-Ndiff)+1:end-Ndiff,:)=output.trainingDATA(3+a*trainingN-(a-1)*Ndiff+1:end,:);
    output.trainingDATA(end-Ndiff+1:end,:)=[];
    
    if size(Ytest,1)>0
        Ytest(a*(testN+Ndiff)+1:end+Ndiff,:)=Ytest(a*(testN+Ndiff)+1-Ndiff:end,:);
        Ytest(a*(testN+Ndiff)+1-Ndiff:a*(testN+Ndiff),:)=Ytraining(a*(trainingN-Ndiff)+1:a*trainingN-(a-1)*Ndiff,:);
        Ytraining(a*(trainingN-Ndiff)+1:end-Ndiff,:)=Ytraining(a*trainingN-(a-1)*Ndiff+1:end,:);
        Ytraining(end-Ndiff+1:end,:)=[];
    end
end

test=test1;
training=training1;
output.variables(1)=trainingN-Ndiff;
output.variables(4)=testN+Ndiff;

end