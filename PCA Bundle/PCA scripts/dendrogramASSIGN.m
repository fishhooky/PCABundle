function dendrogramASSIGN(PCS,variables,scores,TestScores)

% Applies sequentially all ExtraData and assigns each sample to a different
% class


global output ExtraData

dendrogram_plot(PCS,variables,scores,TestScores,[])
PCS(1).Value=1;
reps = inputdlg('Total number of replicates per class?','Sample size',[1,40],{num2str(output.variables(1)+output.variables(4))});
close
if size(reps,1)==0
    return
else
    reps=str2double(reps);
end
R1 = output.dendrogram.order(1,:);
for a1 = 1:size(ExtraData,1)
    dendrogram_plot(PCS,variables,scores,TestScores,ExtraData(a1,:),1)
    R2(1) = find(output.dendrogram.order(1,:)==max(R1)+1);
    if R2(1)==1 || R2(1) == size(output.dendrogram.order,2)
        % Determine if point is outlier
        % Else assign to nearest point
        if R2(1)==1
            if output.dendrogram.order(2,1)==max(output.dendrogram.order(2,1:reps+1))
                R2(1)=size(output.dendrogram.order,2);
                A(a1,1)=ceil(R2(1)/reps);
            else
                R2(1)=output.dendrogram.order(1,2);
                A(a1,1)=ceil(find(R1==R2(1))/reps);
            end
        else
            if output.dendrogram.order(2,end-1)<max(output.dendrogram.order(2,end-reps-1:end))                
                R2(1)=output.dendrogram.order(1,end-1);
                A(a1,1)=ceil(find(R1==R2(1))/reps);
            else
                A(a1,1)=ceil(R2(1)/reps);
            end
        end
    else
        R2(2) = output.dendrogram.order(1,R2(1)-1);
        R2(4) = output.dendrogram.order(1,R2(1)+1);
        R2(3) = output.dendrogram.order(2,R2(1)-1);
        R2(5) = output.dendrogram.order(2,R2(1));
        
        if R2(3)<R2(5)
            R2(1)=R2(2);
        else
            R2(1)=R2(4);
        end
        A(a1,1)=ceil(find(R1==R2(1))/reps);
    end
end
if exist("A","var")==1
    output.dendrogram.assign = A;
    msgbox("Analysis complete. Output in output.dendrogram.assign")
else
    msgbox("Please add Extra Data")
end


