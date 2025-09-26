function split1(varargin)
% Script to split or combine training and test sets
% Andrew Hook August 2024
% Can use varargin to input new training and test set number


%%SETUP
global training test output temp Ytraining Ytest
trainingN = output.variables(1);
testN = output.variables(4);
answer = 1;
if testN == 0
    split = 1;
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
    split = 0;
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
    if split == 1 % split training set into training and test
        
        % Split x data
        % test
        for a1= 1:reps
            % whole set
            test1(1+(a1-1)*testN:a1*testN,:)=training1(1+a1*totalREPS-testN:a1*totalREPS,:);
            % spare set
            output1.testDATA(1+(a1-1)*testN:a1*testN,:)=output1.trainingDATA(3+1+a1*totalREPS-testN:3+a1*totalREPS,:);
        end
        % training
        for a1= 1:reps
            % whole set
            training1(1+(a1-1)*trainingN:trainingN*a1,:)=training1(1+(a1-1)*totalREPS:totalREPS*a1-testN,:);
            % spare set
            output1.trainingDATA(3+1+(a1-1)*trainingN:3+trainingN*a1,:)=output1.trainingDATA(3+1+(a1-1)*totalREPS:3+totalREPS*a1-testN,:);
        end
        training1(reps*trainingN+1:end,:)=[];
        output1.trainingDATA(3+reps*trainingN+1:end,:)=[];
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
        % Split x data
        % training
        for a1= 1:reps
            % whole set
            training1(1+(a1-1)*totalREPS:totalREPS*a1-testN,:)=hold1(1+(a1-1)*trainingN:trainingN*a1,:);
            % spare set
            output1.trainingDATA(3+1+(a1-1)*totalREPS:3+totalREPS*a1-testN,:)=hold2(3+1+(a1-1)*trainingN:3+trainingN*a1,:);
        end
        % test
        for a1= 1:reps
            % whole set
            %training1(a1*totalREPS-testN+1:a1*totalREPS,:)=test1(1+(a1-1)*testN:a1*testN,:);
            % spare set
            output1.trainingDATA(3+a1*totalREPS-testN+1:3+a1*totalREPS,:)=output1.testDATA(1+(a1-1)*testN:a1*testN,:);
        end
        test1=[];
        output1.testDATA=[];
        % Split y data
        if size(Ytraining1,1)>0
            hold1=Ytraining1;
            if isfield(temp1,'Ytraining') == 1
                hold2=temp1.Ytraining;
            else
                hold2=Ytraining1;
            end
            % Split x data
            % training
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
                %Ytraining1(a1*totalREPS-testN+1:a1*totalREPS,:)=Ytest1(1+(a1-1)*testN:a1*testN,:);
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
    %training=training1;
    output = output1;
    %test=test1;
    %Ytraining=Ytraining1;
    %Ytest=Ytest1;
    
    %% Run PCA/PLS
    
    %if output.variables(9) ==0
        %pcaRUN
    %else
        %plsRUN
    %end
    
    
    
end