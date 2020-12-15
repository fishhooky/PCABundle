function [Coordinates,logicTEST]=GetEllipses(data1,replicates,test,test_replicates)

%% Use to generate PCA confidence ellipses
% By Andrew Hook 2016
% Requires set of XY coordinates as data1 double array, all replicates
% grouped together
% Outputs Output array with XY coordinates of ellipses, staggered every two columns
% data1 = training set data
% replicates = number of replicates grouped together within data1
% (replicates in different rows)
% test = test set data
% test_replicates = number of grouped replicates within test
% Will run error_ellipse script
% logicTEST will output 1 for every test datapoint that is within the 95%
% confidence limit and 0 if outside. Different row for each sample set.

if nargin <3
    test1=[];
    test_replicates = 0;
    logicTEST=[];
end

Loops = size(data1,1)/replicates;

for m=1:Loops
    %clearvars -except data1 Output Loops m replicates
    data = data1((m-1)*replicates+1:(m-1)*replicates+replicates,1:2);
    if nargin >2
        test1=test((m-1)*test_replicates+1:m*test_replicates,1:2);
    end
    [r_ellipse,lTEST]=error_ellipse(data,test1);    
    Coordinates(1:100,1+(m-1)*2)=r_ellipse(1:100,1);
    Coordinates(1:100,2+(m-1)*2)=r_ellipse(1:100,2);
    if size(lTEST,1)>0
        logicTEST(m,1:size(lTEST,2))=lTEST;
    end
end
% close all
% clearvars -except data1 Output