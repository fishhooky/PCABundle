function [r_ellipse,testOUTPUT]=error_ellipse(data,test)
%clearvars -except data data1;
%close all;

testOUTPUT=[];

% Create some random data


% Calculate the eigenvectors and eigenvalues
covariance = cov(data);
[eigenvec, eigenval ] = eig(covariance);

% Get the index of the largest eigenvector
[largest_eigenvec_ind_c, r] = find(eigenval == max(max(eigenval)));
largest_eigenvec = eigenvec(:, largest_eigenvec_ind_c);

% Get the largest eigenvalue
largest_eigenval = max(max(eigenval));

% Get the smallest eigenvector and eigenvalue
if(largest_eigenvec_ind_c == 1)
    smallest_eigenval = max(eigenval(:,2));
    smallest_eigenvec = eigenvec(:,2);
else
    smallest_eigenval = max(eigenval(:,1));
    smallest_eigenvec = eigenvec(1,:);
end

% Calculate the angle between the x-axis and the largest eigenvector
angle = atan2(largest_eigenvec(2), largest_eigenvec(1));

% This angle is between -pi and pi.
% Let's shift it such that the angle is between 0 and 2pi
if(angle < 0)
    angle = angle + 2*pi;
end

% Get the coordinates of the data mean
avg = mean(data);

% Get the 95% confidence interval error ellipse
chisquare_val = 2.4477;
theta_grid = linspace(0,2*pi);
phi = angle;
X0=avg(1);
Y0=avg(2);
a=chisquare_val*sqrt(largest_eigenval);
b=chisquare_val*sqrt(smallest_eigenval);

% the ellipse in x and y coordinates 
ellipse_x_r  = a*cos( theta_grid );
ellipse_y_r  = b*sin( theta_grid );

%Define a rotation matrix and its inverse
R = [ cos(phi) sin(phi); -sin(phi) cos(phi) ];
R1=inv(R);

% Process test data
if size(test,1)>0
    % Translate test
    test(:,1)=test(:,1)-X0;
    test(:,2)=test(:,2)-Y0;
    % Rotate test data
    test = test * R1;
    % Find test vector angle
    testtheta = atan (abs(test(:,2))./abs(test(:,1))*a/b);
    % Find test coordinates on 95% ellipse
    test_r = a*cos(testtheta);
    test_r(:,2)=b*sin(testtheta);
    % plot data
%     h=figure;
%     hold on
%     plot(ellipse_x_r,ellipse_y_r)
%     scatter(abs(test_r(:,1)),abs(test_r(:,2)))
%     scatter(abs(test(:,1)),abs(test(:,2)))
%     scatter(0,0)
%     close(h)
    % See if test within 95% confidence ellipse
    for x1=1:size(test,1)
        if abs(test_r(x1,1))>abs(test(x1,1)) && abs(test_r(x1,2))>abs(test(x1,2))
            testOUTPUT(x1)=1;
        else
            testOUTPUT(x1)=0;
        end
    end
end

%let's rotate the ellipse to some angle phi
r_ellipse = [ellipse_x_r;ellipse_y_r]' * R;

%translate in X and Y
r_ellipse(:,1)=r_ellipse(:,1) + X0;
r_ellipse(:,2)=r_ellipse(:,2) + Y0;

% Draw the error ellipse
%plot(r_ellipse(:,1) + X0,r_ellipse(:,2) + Y0,'-')
%hold on;

% Plot the original data
%plot(data(:,1), data(:,2), '.');
mindata = min(min(data));
maxdata = max(max(data));
%xlim([mindata-3, maxdata+3]);
%ylim([mindata-3, maxdata+3]);
%hold on;

% Plot the eigenvectors
%quiver(X0, Y0, largest_eigenvec(1)*sqrt(largest_eigenval), largest_eigenvec(2)*sqrt(largest_eigenval), '-m', 'LineWidth',2);
%quiver(X0, Y0, smallest_eigenvec(1)*sqrt(smallest_eigenval), smallest_eigenvec(2)*sqrt(smallest_eigenval), '-g', 'LineWidth',2);
%hold on;

% Set the axis labels
%hXLabel = xlabel('x');
%hYLabel = ylabel('y');
