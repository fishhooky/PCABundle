function plsSCORES(data,list,SampleNames,type)
%% Scores plot for PLS
global output temp
Pix_SS = get(0,'screensize'); %Get screen dimensions
LV=[];

% Extract selected Latent variables of interest
for x1=0:size(list,1)-5
    if list(size(list,1)-x1).Value==1
        LV(end+1)=x1+1;
    end
end


figure('Name','Scores plot','Position',[Pix_SS(1,3)/10,Pix_SS(1,4)/2,Pix_SS(1,4)/2.7+100,Pix_SS(1,4)/2.7]);
hold on
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end
set(gca,'FontName','Calibri','FontSize',16,'Position',[0.18,0.18,0.74*0.75,0.74]);
% Find number of datasets
reps = output.variables(1,1);
datasets = floor(size(data,1)/reps);

if size(LV,2)==3
    x3=1;
else
    x3=0;
end

data1(:,1)=data(:,LV(1));
data1(:,2)=data(:,LV(2));
if x3==1
    data1(:,3)=data(:,LV(3));
end

% Find different colours for different datasets
cs(1:datasets,3)=0;
for a =0: datasets-1
    cs(a+1,1:3)=colourcalc(a,datasets-1,'Rainbow');
end
if output.variables(1)==0
    mks={'o'};
else
    mks = {'o','^','d'};
end

% Add data
for a=1:datasets
    if isempty(find(output.omit==a))==1
        if x3==0
            scatter(data1(1+reps*(a-1):a*reps,1),...
                data1(1+reps*(a-1):a*reps,2),...
                9,cs(a,:),'filled',mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
        else
            scatter3(data1(1+reps*(a-1):a*reps,1),...
                data1(1+reps*(a-1):a*reps,2),...
                data1(1+reps*(a-1):a*reps,3),...
                9,cs(a,:),'filled',mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
        end
    end
end
if type == 1
    text = strcat('Predicted d',num2str(LV(1)));
    xlabel(text)
    text = strcat('Predicted d',num2str(LV(2)));
    ylabel(text)
    if x3==1
        text = strcat('Predicted d',num2str(LV(3)));
        zlabel(text)
    end
else
    text = strcat('LV',num2str(LV(1)),' (',num2str(round(output.PLS.Variance(2,LV(1))*100,1)),'%)');
    xlabel(text)
    text = strcat('LV',num2str(LV(2)),' (',num2str(round(output.PLS.Variance(2,LV(2))*100,1)),'%)');
    ylabel(text)
    if x3==1
        text = strcat('LV',num2str(LV(3)),' (',num2str(round(output.PLS.Variance(2,LV(3))*100,1)),'%)');
        zlabel(text)
    end
end

% Add extradata to graph
if isfield(temp,'ExtraData')==1 && size(temp.ExtraData,2)>0
    if type == 1
            scatter(output.PLS.PredictExtraData(:,1),...
                output.PLS.PredictExtraData(:,2),...
                12,[0,0,0],'x')        
    else
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
    PlotScores=((temp.ExtraData-offset)./scale-mean(output.trainingDATA(4:end,:),1))*output.PLS.Stats.W*pinv(output.PLS.Loadings'*output.PLS.Stats.W);
    output.PLS.ExtraDataScores=PlotScores;
    x1=size(PlotScores,1);
    for a=1:x1
        if x3 == 0
            scatter(PlotScores(a,LV(1)),PlotScores(a,LV(2)),...
                12,[1-a/x1,1-a/x1,1-a/x1],'x')
        else
            scatter3(PlotScores(a,LV(1)),PlotScores(a,LV(2)),PlotScores(a,LV(3)),...
                12,[1-a/x1,1-a/x1,1-a/x1],'x')
        end
    end
    end
end

% Confidence Ellipses
if reps>1 && x3 == 0
    Ellipse = GetEllipses(data1,reps,output.variables(12));
    output.PLS.ScoresEllipses=Ellipse;
    for a=1:datasets
        if isempty(find(output.omit==a))==1
            plot(Ellipse(:,1+2*(a-1)),Ellipse(:,2*a),...
                'Color',cs(a,:))
        end
    end
end

% Adding test dataset to graph
if isfield(output.PLS,'TScores')==1 && size(output.PLS.TScores,1)>0
    reps = output.variables(1,4);
    % XDataSource/YDataSource must be separately defined to allow linkdata
    for a=1:datasets
        if isempty(find(output.omit==a))==1
            if x3==0
                if type == 1
                    scatter(output.PLS.predictTEST(1+(a-1)*reps:reps*a,LV(1)),...
                        output.PLS.predictTEST(1+(a-1)*reps:reps*a,LV(2)),...
                        12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))},...
                        'XDataSource','temp.TestScores(1+(a-1)*reps:reps*a,1)',...
                        'YDataSource','temp.TestScores(1+(a-1)*reps:reps*a,2)')
                else
                    scatter(output.PLS.TScores(1+(a-1)*reps:reps*a,LV(1)),...
                        output.PLS.TScores(1+(a-1)*reps:reps*a,LV(2)),...
                        12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))},...
                        'XDataSource','temp.TestScores(1+(a-1)*reps:reps*a,1)',...
                        'YDataSource','temp.TestScores(1+(a-1)*reps:reps*a,2)')
                end
            else
                if type == 1
                    scatter3(output.PLS.predictTEST(1+(a-1)*reps:reps*a,LV(1)),...
                        output.PLS.predictTEST(1+(a-1)*reps:reps*a,LV(2)),...
                        output.PLS.predictTEST(1+(a-1)*reps:reps*a,LV(3)),...
                        12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
                else
                    scatter3(output.PLS.TScores(1+(a-1)*reps:reps*a,LV(1)),...
                        output.PLS.TScores(1+(a-1)*reps:reps*a,LV(2)),...
                        output.PLS.TScores(1+(a-1)*reps:reps*a,LV(3)),...
                        12,cs(a,:),mks{a-size(mks,2)*floor((a-0.1)/size(mks,2))})
                end
            end
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

% Scatter 3D plot formatting
if x3 == 1
    grid on
    view([45 45])
end
