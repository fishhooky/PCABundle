function RandomForest(TN,TX,VN,VX,varargin)
% Function to produce random forest model
% Written by Andrew Hook August 2024
% Categorises data into sets based upon number of replicates
% Will first find number of variables that are required to minimise error
% Then finds number of trees required for reproducible predictions
% Error calculation based upon matching to different category
% Calculates variable cost, sum of occurence of variable in succesful model
% Subtract occurence of variable in unsuccessful model
% Can use varargin to specify trees and variables, avoiding optimisation
% DOE based optimisation that runs iteratively until best fit found

%% Setup
global output ExtraData

splitref=0;
if output.variables(4)>0
    pep1=output.variables(1);
    pep2=output.variables(4);
    split1
    splitref=1;
end

output.RF.Model = [];
ErrorLOG=[];
variableCOST = [];
optimise =1 ;

count = 0;
RF = [];
trigger1 = 0; % trigger for trees being optimised
trigger2 = 0; % trigger for variables being optimised
trigger0 = 1; % trigger for both being optimised

reps=output.variables(1);
Xsize = size(output.trainingDATA);
Xsize(1)=Xsize(1)-3;
variableCOST(Xsize(2))=0;
DATA = output.trainingDATA;
outputFORM=0;

if isempty(varargin) == 1 || isnan(varargin{1}) == 1
    trees = TN;
    variables = VN;
else
    trees = varargin{1};
    variables = varargin{2};
    optimise = 0;
    if variables>Xsize(2)
        variables=Xsize(2);
    end
    if size(varargin,2)>2
        
        if varargin{3}==1
            outputFORM=1;
            global form
        end
    end
end
% Initial tree and variable limits
% TN = 20;
% TX = 1000;
% VN = ceil(sqrt(size(output.trainingDATA,2))/2);
% VX = ceil(Xsize(2)/2);

if optimise == 1
    disp('Initial optimisation')
end
while trigger0 > 0
    
    %% Build model datasets
    RF=[];
    
    for a3 = 1:trees
        % Create bootstrapped dataset
        
        bsDATA1=DATA(4:end,:);
        bsY=[];
        bsY(Xsize(1),1)=0;
        
        for a1 = 1: Xsize(1) % Build datasets
            a2 = ceil(rand*Xsize(1));
            sampleLOG(a1)=a2;
            bsDATA1(a1,:)=DATA(a2+3,:);
            bsY(a1,1)=ceil(a2/reps);
        end
        
        
        
        % Build non-BAGGED dataset
        nbLOG=[];
        for a1=1:Xsize(1)
            if size(find(sampleLOG==a1),2)==0
                nbLOG(end+1)=ceil(a1/reps);
            end
        end
        
        % Select subset of variables
        bsDATA2=[];
        
        variableLOG = ceil(rand*Xsize(2));
        bsDATA2(:,1)= bsDATA1(:,variableLOG);
        for a1 = 2:variables
            a2 = ceil(rand*Xsize(2));
            while size(find(variableLOG==a2),2)>0
                a2 = ceil(rand*Xsize(2));
            end
            variableLOG(a1)=a2;
            bsDATA2(:,a1)= bsDATA1(:,variableLOG(a1));
        end
        clear bsDATA1
        
        
        %% Create Model
        RF.(strcat('m',num2str(a3)))= fitctree(bsDATA2,bsY);
        RF.(strcat('n',num2str(a3))).sampleLOG = sampleLOG;
        RF.(strcat('n',num2str(a3))).variableLOG = variableLOG;
    end
    
    
    %% Measure error
    Error = 0;
    Ypredict = [];
    Ypredict(size(bsDATA2,1),2)=0;
    
    Y=[];
    Y(Xsize(1),1)=0;
    vCOUNT = [];
    vCOUNT(Xsize(1))=0;
    
    Xnew1=DATA(4:end,:);
    for a2 = 1:trees
        sampleLOG = RF.(strcat('n',num2str(a2))).sampleLOG;
        variableLOG = RF.(strcat('n',num2str(a2))).variableLOG;
        model = RF.(strcat('m',num2str(a2)));
        
        Xnew2=[];
        Xnew2(size(Xnew1,1),variables)=0;
        
        for a3 = 1:variables
            Xnew2(:,a3)=Xnew1(:,variableLOG(a3));
        end
        for a1 = 1:Xsize(1)
            Y1 = ceil(a1/reps);
            if size(find(sampleLOG==a1),2)==0
                vCOUNT(a1)=vCOUNT(a1)+1;
                Y(a1,vCOUNT(a1)) = predict(model,Xnew2(a1,:));
                
                if Y(a1,end) == Y1
                    for a3 = 1:variables
                        variableCOST(variableLOG(a3))=1+variableCOST(variableLOG(a3));
                    end
                else
                    for a3 = 1:variables
                        variableCOST(variableLOG(a3))=variableCOST(variableLOG(a3))-1;
                    end
                end
                
            end
        end
    end
    for a1=1:Xsize(1)
        Ypredict(a1,2)=mode(Y(a1,1:vCOUNT(a1)));
        if mode(Y(a1,1:vCOUNT(a1)))~=ceil(a1/reps)
            Error = Error + 1;
        end
    end
    
    ErrorLOG(end+1,1)=trees;
    ErrorLOG(end,2)=variables;
    ErrorLOG(end,3)=Error;
    %size(ErrorLOG,1)
    % Change variable optimisation conditions
    if optimise == 1
        if trigger1 == 1 && trigger2 == 1
            trigger0 = 0;
            disp('Finalising')
        end
        if trigger1 == 0 && trigger2 == 1 %Optimising trees only
            if count == 0
                disp('Optimising trees')
            end
            count = count + 1;
            if count == 2
                count = 0;
                if ErrorLOG(end,3)>=ErrorLOG(end-1,3) && ErrorLOG(end-1,1) == ErrorLOG(1,1) || ErrorLOG(end,3)>=ErrorLOG(end-1,3) && ErrorLOG(end,1) - ErrorLOG(end-1,1) <=1 % Check to see if trees doesn't change over range
                    trigger1 = 1;
                elseif ErrorLOG(end,1)-ErrorLOG(end-1,1)<=1 % Difference between TN and TX is 1
                    TN=TX;
                    trigger1 = 1;
                else% What to do if max conditions works best
                    TN = TN + ceil((TX-TN)/4);
                    if ErrorLOG(end,3)>=ErrorLOG(4,3)
                        TX = TX + ceil((TX-TN)/4);
                    end
                end
                if VN < ErrorLOG(1,2)
                    VN = ErrorLOG(1,2);
                end
                if TN < ErrorLOG(1,1)
                    TN = ErrorLOG(1,1);
                end
                if TX > ErrorLOG(4,1)
                    TX = ErrorLOG(4,1);
                end
                if VX > ErrorLOG(4,2)
                    VX = ErrorLOG(4,2);
                end
                trees = TN;
            else
                trees = TX;
            end
        end

        if trigger1 == 1 && trigger2 == 0 %Optimising variables only
            if count == 0
                disp('Optimising variables')
            end
            count = count + 1;
            if count == 2
                count = 0;
                if ErrorLOG(end,3)>=ErrorLOG(end-1,3) && ErrorLOG(end-1,2) == ErrorLOG(1,2) || ErrorLOG(end,3)>=ErrorLOG(end-1,3) && ErrorLOG(end,2) - ErrorLOG(end-1,2) <=1 % Check to see if variables doesn't change over range
                    trigger2 = 1;
                elseif ErrorLOG(end,1)-ErrorLOG(end-1,1)<=1 % Difference between VN and VX is 1
                    VN=VX;
                    trigger2 = 1;
                else% What to do if max conditions works best
                    VN = VN + ceil((VX-VN)/4);
                    if ErrorLOG(end,3)>=ErrorLOG(4,3)
                        VX = VX + ceil((VX-VN)/4);
                    end
                end
                                if VN < ErrorLOG(1,2)
                    VN = ErrorLOG(1,2);
                end
                if TN < ErrorLOG(1,1)
                    TN = ErrorLOG(1,1);
                end
                if TX > ErrorLOG(4,1)
                    TX = ErrorLOG(4,1);
                end
                if VX > ErrorLOG(4,2)
                    VX = ErrorLOG(4,2);
                end
                variables = VN;
            else
                variables = VX;
            end
        end
        
        if trigger1 == 0 && trigger2 == 0 %Optimising both variables
            count = count + 1;
            if count == 4
                count = 0;
                % Decision making for optimisation
                if ErrorLOG(end,3)>=ErrorLOG(end-1,3) && ErrorLOG(end-1,2) == ErrorLOG(1,2) || ErrorLOG(end,3)>=ErrorLOG(end-1,3) && ErrorLOG(end,2) - ErrorLOG(end-1,2) <=1 % Check to see if variables doesn't change over range
                    trigger2 = 1;
                end
                if ErrorLOG(end,3)>=ErrorLOG(end-2,3) && ErrorLOG(end-1,1) == ErrorLOG(1,1) || ErrorLOG(end,3)>=ErrorLOG(end-2,3) && ErrorLOG(end,1) - ErrorLOG(end-2,1) <=1 % Check to see if trees doesn't change over range
                    trigger1 = 1;
                end
                if ErrorLOG(end-3,3) <= ErrorLOG(end,3) % Check to see if minimal values works better
                    VX = VN + ceil((VX-VN)/4);
                    VN = VN - ceil((VX-VN)/2);
                    TX = TN + ceil((TX-TN)/4);
                    TN = TN - ceil((TX-TN)/2);
                elseif ErrorLOG(end-2,3) <= ErrorLOG(end,3) % If minimise trees, maximise variables
                    TX = TN + ceil((TX-TN)/4);
                    TN = TN - ceil((TX-TN)/2);
                    if TN < ErrorLOG(1,1)
                        TN = ErrorLOG(1,1);
                    end
                    if ErrorLOG(end-2,3) < ErrorLOG(4,3)
                        VX = VX + ceil((VX-VN)/4);
                        VN = VN + ceil((VX-VN)/2);
                    end
                 elseif ErrorLOG(end-1,3) <= ErrorLOG(end,3) % If maximise trees, minimise variables
                    VX = VN + ceil((VX-VN)/4);
                    VN = VN - ceil((VX-VN)/2);
                    if ErrorLOG(end-1,3) < ErrorLOG(4,3)
                        TX = TX + ceil((TX-TN)/4);
                        TN = TN + ceil((TX-TN)/2);
                    end
                else % What to do if max conditions works best                    
                    VN = VN + ceil((VX-VN)/4);
                    TN = TN + ceil((TX-TN)/4);
                    if ErrorLOG(end,3)<ErrorLOG(4,3)
                        VX = VX - ceil((VX-VN)/4);
                        TX = TX - ceil((TX-TN)/4);
                    end
                end
                if VN < ErrorLOG(1,2)
                    VN = ErrorLOG(1,2);
                end
                if TN < ErrorLOG(1,1)
                    TN = ErrorLOG(1,1);
                end
                if TX > ErrorLOG(4,1)
                    TX = ErrorLOG(4,1);
                end
                if VX > ErrorLOG(4,2)
                    VX = ErrorLOG(4,2);
                end
                trees = TN;
                variables = VN;
            elseif rem(count,2)==0
                trees = TX;
                variables = VN;
            else
                variables = VX;
            end
        end
        % Incremental optimisation
        %         if trigger1 == 2 % Terminate RF process
%             trigger1 = 0;
%             for a1=1:Xsize(1)
%                 Ypredict(a1,1)=ceil(a1/reps);
%             end
%         end
%         if trigger0 ==1 % switch to stepwise optimisation
%             disp('Fine tuning number of variables')
%             trigger0 = 2;
%             variables = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),2);
%             trees = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),1);
%             variables = variables - 10;
%             count = 0;
%             if variables < 3
%                 variables =3;
%             end
%         elseif trigger0 == 2
%             variables = variables + 1;
%             count = count + 1;
%         end
%         
%         if count > 20 && trigger0 == 2 || variables > Xsize(2)/2 && trigger0
%             disp('Tuning number of trees')
%             variables = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),2);
%             trees = trees - 100;
%             if trees < 3
%                 trees = 3;
%             end
%             count = 0;
%             trigger0 =3;
%         elseif trigger0 == 3
%             trees = trees + 10;
%             count = count + 1;
%         end
%         
%         if count > 20 && trigger0 == 3 || trees > 250 && trigger0 == 3
%             disp('Fine tuning number of trees')
%             variables = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),2);
%             trees = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),1);
%             trees = trees - 10;
%             if trees < 3
%                 trees = 3;
%             end
%             count = 0;
%             trigger0 =4;
%         elseif trigger0 == 4
%             trees = trees + 1;
%             count = count + 1;
%         end
%         
%         if count > 20 && trigger0 == 4 || trees > 250 && trigger0 == 4
%             disp('Finalising')
%             trigger0 = 5;
%             trigger1 = 2;
%             variables = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),2);
%             trees = ErrorLOG(max(find(ErrorLOG(:,3)==min(ErrorLOG(:,3)))),1);
%         end
    
    
    else
        trigger0 = 0;
    end
end

if splitref ==1
    split1(pep1,pep2)
end

%% Create surf output for plotting mapped error
if optimise == 1
    X = sortrows(ErrorLOG(:,1));
    X=unique(X);
    Y = sortrows(ErrorLOG(:,2));
    Y=unique(Y)';
    for a3=1:size(X,1)
        Y(a3,:)=Y(1,:);
    end

    for a3=1:size(Y,2)
        X(:,a3)=X(:,1);
    end

    Z=griddata(ErrorLOG(:,1),ErrorLOG(:,2),ErrorLOG(:,3),X,Y);

    f=figure;
    movegui(f,'northeast')
    surf(X,Y,Z)
    xlabel('trees')
    ylabel('variables')
    zlabel('error')
    view([-17 3])
end
%% Calculate values for ExtraData
if size(ExtraData,1)>0
    % Rescale ExtraData
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
    ED = (ExtraData-offset)./scale;
    ExYpredict=[];
    ExYpredict(size(ExtraData,1),1)=0;
    for a2 = 1:trees
        model = RF.(strcat('m',num2str(a2)));
        variableLOG = RF.(strcat('n',num2str(a2))).variableLOG;
        Xnew2=[]; % Generates X set associated with variables of tree
        Xnew2(size(ExtraData,1),variables)=0;
        
        if size(ExtraData,2)==Xsize(2)
            for a3 = 1:variables
                Xnew2(:,a3)=ED(:,variableLOG(a3));
            end
        else
            for a3 = 1:variables
                Xnew2(:,a3)=ED(:,DATA(1,variableLOG(a3)));
            end
        end
        
        % Sequentially apply ExtraData samples to tree
        for a1 = 1:size(ExtraData,1)
            ExY(a1,a2) = predict(model,Xnew2(a1,:));
        end
    end
    for a1=1:size(ExtraData,1)
        ExYpredict(a1,1)=mode(ExY(a1,:));
    end
    output.RF.ExtraData = ExYpredict;
end

%% Output modelling outcomes
if optimise == 1
    output.RF.errorLOG = ErrorLOG;
    output.RF.variableCOST = variableCOST;
end
for a1=1:Xsize(1)
    Ypredict(a1,1)=ceil(a1/reps);
end
output.RF.Model = RF;
output.RF.predictedY = Ypredict;
output.RF.variables = variables;
output.RF.trees = trees;

if outputFORM == 0
message = 'Forest Finished Growing.';
message = [message newline 'Final variables = ',num2str(variables),'.'];
message = [message newline 'Final number of trees = ',num2str(trees),'.'];
message = [message newline 'Fraction correctly predicted = ',num2str(round(size(find(Ypredict(:,1)==Ypredict(:,2)),1)/size(Ypredict,1),2)),'.'];

Pix_SS = get(0,'screensize'); %Get screen dimensions
fig2 = uifigure('Name','RF Summary','units','pixels','Position',[Pix_SS(1,3)/4,Pix_SS(1,4)/3,250,150]);
ef = uieditfield(fig2,"numeric","Limits",[1 trees],'Position',[180,30,50,25]);
uibutton(fig2,'Text','OK','Position',[40,30,50,25],'ButtonPushedFcn', ...
    @(btnPCA,event) delete(fig2));
uibutton(fig2,'Text','View Tree','Position',[100,30,70,25],'ButtonPushedFcn', ...
    @(btnPCA,event) graphTREE(ef.Value));
uilabel(fig2,'Text',message,'Position',[40,65,200,60]);



g= figure('Name',strcat('Trees = ',num2str(trees),' Variables = ',num2str(variables)));
movegui(g,'southeast')
scatter(Ypredict(:,1),Ypredict(:,2))
xlabel('Category number');
ylabel('Predicted category');
else

    form(end+1,1)=variables;
    form(end,2)=trees;
    form(end,3)=round(size(find(Ypredict(:,1)==Ypredict(:,2)),1)/size(Ypredict,1),2);
end
end
function graphTREE(x1)
    global output
    view(output.RF.Model.(strcat('m',num2str(x1))),'Mode','graph')
end

