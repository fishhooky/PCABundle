function ellipseASSIGN(PCS,variables,scores,TestScores)

% Applies sequentially all ExtraData and assigns each sample to a different
% class based upon 95% confidence ellipses


global output ExtraData
ED = ExtraData;

%% Export PCs of interest
PCs=[];
for a=1:size(PCS,1)-5-output.variables(9)
    if PCS(size(PCS,1)+1-a).Value==1
        PCs(end+1)=a;
    end
end

%% Extract data
data=[];
dataT=[];
for a = 1:size(PCs,2)
    data(:,a)=scores(:,PCs(a));
    dataT(:,a)=TestScores(:,PCs(a));
end

%% Find ellipses
for a = 1:floor(size(PCs,2)/2)
    Coor{a} = GetEllipses(data(:,1+2*(a-1):2*a),output.variables(1),output.variables(12),dataT(:,1+2*(a-1):2*a),output.variables(4));
    mCoor(a,:) = mean(Coor{a});
end

if size(ED,2)>0
    %% Build ExtraData file with selected features
    % Check to ensure ExtraData size is correct
    if size(ED,2)~=size(output.trainingDATA,2)
        for j1=1:size(output.trainingDATA,2)
            ED(:,j1)=ExtraData(:,output.trainingDATA(1,j1));
        end
        ED(:,j1+1:end)=[];
    end
    if variables(7)==1
        scale=output.trainingDATA(3,:);
        offset=output.trainingDATA(2,:);
        if variables(8)==1
            scale=scale.*output.trainingDATA(2,:).^0.5;
        end
    elseif variables(8)==1
        offset=0;
        scale=output.trainingDATA(2,:).^0.5;
    else
        scale=1;
        offset =0;
    end
    if variables(9) == 0
        EScores=((ED-offset)./scale-output.PCA.mu)*output.PCA.loadings;
    else
        EScores=((ED-offset)./scale-mean(output.trainingDATA(4:end,:),1))*output.PLS.Stats.W*pinv(output.PLS.Loadings'*output.PLS.Stats.W);
    end
else
    msgbox("Please add Extra data")
    return
end

for a1 = 1:size(ED,1)

    for a2 = 1:size(PCs,2)
        tEscores(a2) =  EScores(a1,PCs(a2));
    end
    for a3=1:floor(size(PCs,2)/2) % Switch between different PCA scores plots
        % Find which ellipse point is closest to score
        for a2 = 1:size(Coor{a3},2)/2 % Switch between different ellipses
            dist=(Coor{a3}(:,1+2*(a2-1):2*a2)-tEscores(1,1+2*(a3-1):2*a3)).^2;
            dist1=(dist(:,1)+dist(:,2)).^0.5;

            remain=find(dist1==min(min(dist1)),1);
            % Interpolate nearest point using quadratic fit
            if remain == 1 || remain == size(dist,1)
                xfit=[];
                yfit=[];
                xfit=Coor{a3}(size(dist,1)-1,a2*2-1);
                xfit(2:3,1)=Coor{a3}(1:2,a2*2-1);
                yfit=Coor{a3}(size(dist,1)-1,a2*2);
                yfit(2:3,1)=Coor{a3}(1:2,a2*2);
            else
                xfit=Coor{a3}(remain-1:remain+1,a2*2-1);
                yfit=Coor{a3}(remain-1:remain+1,a2*2);
            end
            p=polyfit(xfit,yfit,2);
            p1=roots([2*p(1)^2 3*p(1)*p(2) p(2)^2+2*p(1)*p(3)-2*p(1)*tEscores(2*a3)+1 p(2)*p(3)-p(2)*tEscores(2*a3)-tEscores(1+2*(a3-1))]);
            p1=p1(p1==real(p1));
            if size(p1,1)>1
                p1=p1(abs(p1-xfit(2))==min(abs(p1-xfit(2))));
            end
            y1=polyval(p,p1);

            % Calculate distances
            ETM=((tEscores(1+2*(a3-1))-mCoor(a3,a2*2-1))^2+(tEscores(2*a3)-mCoor(a3,a2*2))^2)^0.5;
            eETM=((p1-mCoor(a3,a2*2-1))^2+(y1-mCoor(a3,a2*2))^2)^0.5;

            % Check if outlier
            if ETM>eETM
                A1(a2,a3,1)=0;
                A1(a2,a3,2)=ETM;
            else
                A1(a2,a3,1)=1;
                A1(a2,a3,2)=ETM;
            end
        end
    end
    
    if max(sum(A1(:,:,1),2))>floor(size(PCs,2)/2)-1
        if size(find(sum(A1(:,:,1),2)>floor(size(PCs,2)/2)-1),1)>1
            A(a1,1)=0;
        else
            A(a1,1)=find(sum(A1(:,:,1),2)>floor(size(PCs,2)/2)-1);
            A(a1,2)=sum(A1(A(a1,1),:,2),2);
        end
    else
        A(a1,1)=size(Coor{a3},2)/2+1;
        A(a1,2)=min(sum(A1(:,:,2),2));
    end
end
if exist("A","var")==1
    output.dendrogram.assign = A;
    msgbox("Analysis complete. Output in output.dendrogram.assign")
else
    msgbox("Please add Extra Data")
end


