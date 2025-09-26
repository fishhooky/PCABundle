n=24;
for a2=1:8 %Sets which dataset
a1=mean(output.trainingDATA(4+(a2-1)*n:3+n/2+(a2-1)*n,:)); %Find mean of data1
a1(2,:)=mean(output.trainingDATA(4+n/2+(a2-1)*n:n+3+(a2-1)*n,:)); %find mean of data2
a1(3,:)=(a1(1,:)-a1(2,:)); %find residuals
%figure;hold on
%scatter(a1(1,:),a1(2,:));scatter(a1(1,:),a1(3,:))
P=polyfit(a1(1,:),a1(3,:),1); %find line of best fit with residuals
output.trainingDATA(4+(a2-1)*n:3+n/2+(a2-1)*n,:)=output.trainingDATA(4+(a2-1)*n:3+n/2+(a2-1)*n,:)-P(1)*a1(1,:)-P(2); %subtract systematic residuals
end
