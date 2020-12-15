function [minMSEModelPredictors,coefficients]=LASSOFeatureSelection(X,y,t)
%% LASSO FEATURE SELECTION 
% Developed by Grazziela P Figueredo
% Last modified 20/05/2019
% Adapted to run with PCA toolbar by Andrew Hook 28/08/2020

% Data layout is row 1 = x data names, row2:end for different samples.
% Columns 1:end-1 is X-data set and column end = y data set
% Data layout as an excel spreadsheet

% If you need to generate feature selection for multiple files for multiple
% descriptors, add their name here. These names need to match the excell
% sheet names
   
    % Add zero where there are no values for the descriptors, otherwise it
    % doesnt work. Or another alternative to remove NANs need to be
    % implemented here
    %data(isnan(data)) = 0;
    
%     X = data(2:end, 1:end-1);
%     y = data(2:end, end);
%     for x1=1:size(Main,2)-1
%         t{1,x1} = num2str(Main{1,x1});
%     end
    %Ensure no Nan on Inf values in y
    x2=0;
    for x1=1:size(y,1)
        if isnan(y(x1,1))==0 && isinf(y(x1,1)) == 0
            x2=x2+1;
            X(x2,:) = X(x1,:);
            y(x2,1) = y(x1,1);
        end
    end
    if x2<x1
        X(x2+1:end,:)=[];
        y(x2+1:end,:)=[];
    end
    y=y-min(y)+1;
    
    if isa(t,'double')==1
        t=sprintfc('%d',t);
    end
    % LASSO feature selection starts
    [B,FitInfo] = lassoglm(X,y,'gamma','CV',2, 'PredictorNames', t);
    
    % The features that provide the min square error are selected
    idxLambdaMinMSE = FitInfo.IndexMinDeviance;
    minMSEModelPredictors = FitInfo.PredictorNames(B(:,idxLambdaMinMSE)~=0);
    coefficients=[];
    for x1 = 1:size(B,1)
        if B(x1,idxLambdaMinMSE)~=0
            coefficients(end+1,1) = B(x1,idxLambdaMinMSE);
        end
    end
    
    idxLambda1SE = FitInfo.Index1SE;
    sparseModelPredictors = FitInfo.PredictorNames(B(:,idxLambda1SE)~=0);
    
    lassoPlot(B,FitInfo,'plottype','CV');
    legend('show')
    
