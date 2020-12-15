function h = plsGRAPH(residuals,RV,yfitPLS,YTraining,YTest,TestfitPLS,r2,PLSPctVar)
global output
Pix_SS = get(0,'screensize'); %Get screen dimensions
%plot latent variables
figure('Name','Variance explained','Position',[10+Pix_SS(1,3)/15+50,50+Pix_SS(1,4)/2,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
hold on
set(gca,'FontName','Calibri','FontSize',18);
plot(cumsum(100*PLSPctVar(2,:)),'-bo','color','k');
ylabel('Variance captured (%)');
yyaxis right
plot(r2(:,1),r2(:,5),'-bo','color','r');
set( gca, 'ycolor','r');
xlabel('Number of latent variables');
ylabel('RMSECV');
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end

%plot residuals
% figure('Name','Residuals','Position',[10+Pix_SS(1,3)/15+50,50,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
% stem(residuals)
% xlabel('Observation');
% ylabel('Residual');
% set(gca,'FontName','Calibri','FontSize',14);

%plot r2
figure('Name','Coefficient of determination','Position',[10+Pix_SS(1,3)/15+50,50,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
hold on
plot(r2(:,1),r2(:,2),'-','color','k');
ylabel('R^{2} Training','color','k');
set( gca, 'YGrid', 'on' ,'ycolor','k');
if abs(sum(sum(YTest)))>0
    yyaxis right
    plot(r2(:,1),r2(:,3),'-','color','r');
    ylabel('R^{2} Test','color','r');
    set( gca, 'ycolor','r');
end
xlabel('Observation');
set(gca,'FontName','Calibri','FontSize',14);
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end

%plot of regression vector
figure('Name','Regression vector','Position',[10+Pix_SS(1,3)/15+50+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,50,(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,Pix_SS(1,4)/2.7]);
global xVALUES temp output
if size(xVALUES,2)>0
    temp.xVALUES=[];
    for a=1:size(RV,1)-1
        temp.xVALUES(a,1)=xVALUES(1,output.trainingDATA(1,a));
        if RV(a+1,1)>0
            temp.xVALUES(a,2)=0;
            temp.xVALUES(a,3)=abs(RV(a+1,1));
        else
            temp.xVALUES(a,3)=0;
            temp.xVALUES(a,2)=abs(RV(a+1,1));
        end
    end
    errorbar(temp.xVALUES(:,1),RV(2:end,1),temp.xVALUES(:,3),temp.xVALUES(:,2),'o','CapSize',0,'MarkerSize',0.01,'LineWidth',0.5)
    xlabel('m/z')
    set(gca,'FontName','Calibri','FontSize',16);
 %    pos=get(get(gca,'xlabel'),'position');
     set(gca,'XAxisLocation','origin')
 %    set(get(gca,'xlabel'),'position',pos);
else
    stem(RV(2:end,1))
    xlabel('Variable');
    set(gca,'FontName','Calibri','FontSize',16);
end
box off
ylabel('Regression coefficient (a.u.)');
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end

YX(1)=min(yfitPLS);
YX(2)=max(yfitPLS);

%plot of measured versus predicted
figure('Name','Measured versus predicted','Position',[10+Pix_SS(1,3)/15+50+(Pix_SS(1,3)-10-Pix_SS(1,3)/15-50)/3,50+Pix_SS(1,4)/2,Pix_SS(1,4)/2.7+100,Pix_SS(1,4)/2.7]);
if abs(sum(sum(YTest)))>0
    plot(YTraining(:,:),yfitPLS,'ko',YTest(:,:),TestfitPLS,'r^',YX(:),YX(:),'k:');
    text(YX(1),YX(2),strcat('R^{2} = ',num2str(round(r2(output.variables(2),2),2))),'FontSize',14);
    text(YX(1),0.8*YX(2),strcat('R^{2} = ',num2str(round(r2(output.variables(2),3),2))),'color','r','FontSize',14);
else
    plot(YTraining(:,:),yfitPLS,'ko',YX(:),YX(:),'k:');
    text(YX(1),YX(2),strcat('R^{2} = ',num2str(round(r2(output.variables(2),2),2))),'FontSize',14);
end
if output.variables(10)==1
    xlabel('Measured log(fraction)');
    ylabel('Predicted log(fraction)');
else
    xlabel('Measured fraction');
    ylabel('Predicted fraction');
end
set(gca,'FontName','Calibri','FontSize',16);
pos=get(gcf,'Position');
pos(3)=pos(4);
set(gcf,'Position',pos);
box off
if output.variables(1,6)==1
    set(gcf, 'Color', 'None');
    set(gca, 'Color', 'None');
end

