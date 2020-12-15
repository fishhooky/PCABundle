PCA Bundle
Andrew Hook (C) 2020
Last tested in Matlab R2018a (9.4.0.813654) on 23-10-2020.
___________________________________________________________________________
INTRODUCTION
___________________________________________________________________________
The PCA Bundle enables PCA and PLS to be conducted on any dataset.
It outputs the standard groups required for reporting these multivariate analysis approaches.
The script also helps lead the user through the decision making required.
The script, in particular, enables selection of sparse datasets through LASSO, OPS and recursive feature selection.

To run the script you type PCA into the command window or run the PCA script. 
This will create the pop box with all the buttons that you can then use. 
You then do not need to re-run the script or interface with the Matlab command window except to add your data.

___________________________________________________________________________
ADDING YOUR DATA
___________________________________________________________________________
Paste the training data into the training variable.
If you have test data paste it to the test variable. 
If you have no test data PLS will use leave-one-out method for cross validation.
Add m/z values to xVALUES if you have them. 
You can also add Sample names to the variable SampleNames. 
If you want to add some data that you just want to plot on the the scores plot you can add it to ExtraData.
If you wish to do PLS add Y data to the Ytest (Y test data) and Ytraining (Y training data) variables.

The training and test data needs to be organised in the same order of samples with replicates positioned together. 
So if you have three samples with 5 replicates for training and 2 replicates for the test set then: 
training data set rows 1-5 = sample 1, rows 6-10 = sample 2 and rows 11-15 = sample 3
test data rows 1-2 = sample 1, rows 3-4 = sample 2 and rows 5-6 = sample 3.

Y data follows the same pattern but will be a single column of data.

___________________________________________________________________________
USING THE POP-UP INTERFACE
___________________________________________________________________________
############################ Check boxes ##################################
Select transparent BKG to chance the background of graphs to transparent.
If you then select the graph, select Edit -> Copy Figure the graph will paste with a transparent backgound.

When doing PCA X-axis PC will change the principal component on the x axis of the main scores plot.
When doing PCA Y-axis PC will change the principal component on the y axis of the main scores plot.

Click on the check box next to square root mean to divide data by the square root of the mean.
Click on the check box next to Scale By STDec to divide data by the standard deviation (variance scaling).

You can input the number of samples for the training and test set in the two boxes below Training/Test replicates. 
The top box is for training and the bottom is for test.

If collective optimise is selected the optimisation of the test sets will consider all data when selecting optimal test set, rather than just other replicates of the same sample.

When doing PLS select log Y data to process the log (base 10) of the y dataset. System will remove values = 0.

############################### Buttons ###################################
‘Run PCA’ will perform PCA on your inputted data and will display the loadings and scores outputs.
Will switch to PCA if in PLS mode. Will recalulate the model if clicked in PCA mode.

‘Run PLS’ will perform PLS on your inputted data and will display the loadings and scores outputs.
Will switch to PLS if in PCA mode. Will recalulate the model if clicked in PLS mode.

'Transpose Data’ will transpose your training/test data. 
Different samples should be in different rows whilst different columns should be different x variables. 
If this is not the case use 'Transpose Data' to switch it.

‘Re-set data’ will revert back to the datasets originally entered into the training and test variables. 
You may wish to do this if you reduce your dataset and want to start again. 
If there is some problem and things are not displaying as expected or an error is displaying hitting this command may solve the problem.

'OPEN' enables a saved dataset to be loaded.
After loading will run PCA or PLS (whatever was being run when saved).

‘CLOSE’ ends the script, clears variables and closes the pop-up interface.
Does not clear traing and test variables or output variable.

’SAVE’ will save the necessary variables so that you can reload a session. 
Once the PCA command is given and the pop-up interface is displayed the previous session can be re-called by loading the saved .mat file using 'OPEN'.

‘Refresh Graphs’ will re-plot the scores and loadings plots. You will need to do this if you change the PC you want to plot in the boxes under X-axis PC or Y-axis PC. If you add numbers here this will change the loadings and scores plots to correspond.

'Orbi-filter'. There is electronic noise in the acquistion of Orbi data that produces false peaks.
The Orbi filter allows you to select ranges that you would like to have removed. The script will then exclude these peaks from all subsequent analysis
You can turn off the filter, but will need to re-set the data to access previously filtered m/z ranges.
With Orbi-filter on recursive feature addition will also not be permitted to add ions within the excluded ranges.
To look up or ammend the ranges being filter find the function oFILTER in the main PCA script

‘RFE/RFA’ will enable a wizard to begin recursive feature elimination/addition to create a sparse dataset.
This function is described further below.

'Remove redundant’ will check any variables that are correlated and remove variables that are highly correlated.
User sets the threshold and will remove any variables that correlate with any other variable with an R2>threshold.

‘Optimise test set’ will randomly rearrange the replicates in the training and test sets until it finds an optimal arrangement.
For PCA, will seek to find where all the test samples are within 95% confidence ellipses. 
You can select ‘Collective optimisation’ to consider all sample sets together for the optimisation.
For PLS will seek to optimise the correlation between the measured and predicted values for the test set only.
Note that this method of optimisation is prone to over-fitting, particularly when using a sparse dataset.
The second method is turned off but can be accessed through modifying the code.
If optimise test set is selected whilst doing PLS it will optimise based upon PCA.

'CLEAR ALL' re-sets all variables, deleting and data added by the user.

############################ PCA Buttons ##################################
'Refresh Graphs' will replot all PCA graphs. 
Do this after changing the PCs you wish to show.

‘Manual Reduce’ allows for manual selection of X-variables based upon the loadings.
Allows user to define thresholds for the loadings on different PCs to remove uninformative descriptors.

‘Dendrogram’ will create a dendrogram plot based upon scores for selected PCs.

‘Create 3D plot’ will create a scores plot with 3 PCs displayed. 

___________________________________________________________________________
PLS REGRESSION
___________________________________________________________________________
Partial least square regression allows construction of a regression model that correlates a multivariate set of features with a univariate dataset.
To do PLS hit the 'Run PLS' button. This switches to PLS mode and invites the user addition of Y data.
If no test data is added PLS will use the leave-one-out method for cross-validation.
The SIMPLS algorithm is used.

Use the #Latent variables box to select the number of latent variables to be used in the model.
This is determined by the minimum in the RMSECV curve. This is not always clear.
If no minimum apparent in RMSECV curve trying optimising the test set. 
To avoid over-fitting switch to PCA, optimise the test set in that mode and then return to PLS.

Total LVs sets the total number of latent variables to be graphed for the RMSECV. 
This will auto-limit based upon the number of features selected. If features are added this may need to be manually increased.

Least absolute shrinkage and selection operator (LASSO).
LASSO is a useful method for selection of a sparse dataset.
Running LASSO is automated and based upon minimisation of the square error.
After LASSO has been run the reduced number of features are automatically applied.
A graph showing the LASSO regression is shown as well as the cross-validated deviance that was used to select the number of features.
To apply the sparse dataset selected by LASSO to PLS hit the 'Run PLS' button.

___________________________________________________________________________
RECURSIVE FEATURE SELECTION
___________________________________________________________________________

After hitting the RFE/RFA button a wizard will guide you through feature selection.

Recursive feature selection can be used in conjunction with LASSO, manual selection or remove redundant.

It will initially ask if you wish to apply a previous selection process.
This enables you to re-select the number of features from a previous run without having to re-calculate the selection criteria.

If in PCA mode it will ask you which PCs to consider. Select PCs.

You can then select elimination or addition. 
Elimination starts with all variables and then removes one at a time.
Addition starts with a few variables (minimum of 3) and sequentially adds variables.

If addition is selected will ask how many features you wish to screen for. 
A good way to reduce the time cost of feature selection is to select a reduced set of variables here.

The two modes can be used in tandem, ie. after eliminating to 10 variables you can then do an addition to add back variables.

If in PCA mode it will ask you what selection criteria you want to use.
'Maximise separation' will calculate the mean of each set of replicates and then sum the distance between all the means.
This criteria will try to maximise the distance between the means of samples.
'Minimise overlap' will calculate the 95% confidence ellipses and calulate the % area that the ellipses overlap. 
This criteria will try to avoid the 95% confidence ellipses overlapping.
You may also alternate between the two.
If overlap is already minimised to 0% will revert to maximising separation.

If in PLS mode the selection criteria is the R2 value for the measured versus predicted values for the training set.

A graph will then be shown for the selection criteria versus the number of features.
You should select the minimum number of features that maximises the selection criteria.
(Note that in graphs the selection criteria should always be maximised).
___________________________________________________________________________
ORDERED FEATURE SELECTION (OPS)
___________________________________________________________________________

If doing PLS you can also access OPS as a feature selection method through the RFE/RFA button.
Select OPS when the option is provided (instead of addition or elimination).
This method does PLS with the number of latent variables selected. 
It then creates a PLS model with a few features that have the largest regression coefficients (considers absolute values).
It then sequentially adds the feature with the next largest regression coefficient.
User defines total number of features to consider.
For each model it calculates the RMSECV and reports this value for the varied number of features.

Select the minimum number of features that produces a minimum RMSECV.
___________________________________________________________________________
OUTPUT VARIABLE
___________________________________________________________________________

All data modifications and processing is logged in the output variable.
Each of the fields within the output variable are described below.

variables
This describes various user defined settings.
1-number of training replicates
2-X axis PC or number of latent variables
3-Y axis PC or total latent variables
4-number of test replicates
5-toggle collective optimisation
6-toggle transparent BKG
7-toggle variance scaling
8-toggle SRM
9-toggle PCA/PLS
10-toggle log/log for PLS
11-toggle for orbi-sims filter

log
Data hold for manual reduction of features

omit
Add numbers to this variable to prevent from being graphed on scores plots
If you add 2000 the legend will be turned off

trainingDATA
Current X data being used for PCA/PLS
row 1 = number of variable in reference to training variable
row 2 = mean of variable
row 3 = standard deviation of variables

testDATA
Current X test data being used for PCA/PLS

sampleNUMBERS
Log of rearrangements of training and test datasets.
Numbers indicate which samples are placed where.

rOUTPUT
Record of the last recursive feature selection performed.
Graph the final column to reproduce graph used for selection criteria.

############################## PCA ########################################
This variable holds all the outputs from PCA

loadings
Loadings from PCA

scores
Scores from PCA

latent
Principal component variances, that is the eigenvalues of the covariance matrix of X, returned as a column vector. 

tsquared
Hotelling’s T-Squared Statistic, which is the sum of squares of the standardized scores for each observation, returned as a column vector.

explained
Percentage of the total variance explained by each principal component, returned as a column vector.

mu
Estimated means of the variables in X, returned as a row vector.

Confidence Ellipses
Coordinates of the calculated 95% confidence ellipses for each dataset.
Alternates between the X and Y coordinates.
Column 1 = sample 1 X coordinates
Column 2 = sample 1 Y coordinates
Column 3 = sample 2 X coordinates etc.

############################## PLS ########################################
This variable holds the outputs from PLS.

residuals
Different between measured and predicted values

RegressionVector
The regression vector, with the regression coefficient for each feature
Note the first value = a constant that is added to Regression vector * X values to find y predicted

predictTRAINING
Predicted values for training dataset

measuredTRAINING
Measured values for the training dataset

predictTEST
Predicted values for test dataset

measuredTEST
Measured values for the test dataset

r2_SE
Measured error of cross validation for PLS models with varied number of latent variables
Different number of latent variables in different rows
Column 1 = number of latent variables
Column 2 = r2 of training set
Column 3 = r2 of test set
Column 4 = RMSE
Column 5 = RMSECV

Loadings
Loadings for the latent variables

Variance
Variance captured
___________________________________________________________________________
TROUBLE SHOOTING
___________________________________________________________________________
Most problems can be solved by hitting Re-set Data. 
This will revert to originally inputted datasets, so will undo any sparse datasets/test set optimisation.

If Re-set Data does not work hit 'CLOSE' and re-run PCA script.

If no minimum apparent in RMSECV curve trying optimising the test set. 
To avoid over-fitting switch to PCA, optimise the test set in that mode and then return to PLS.

PROBLEM: No RMSECV curve visible or only a few variables visible. 
SOLUTION: The Total LVS may have autoset to a low value. Manually increase this value.

PROBLEM: Trying to minimise overlap for feature selection but % overlap keeps increasing.
SOLUTION: % overlap is inverted for feature selection. All selection criteria are maximised.

If you find an error that these solutions do not solve please save the data and send the matlab file with a descrption of the error to andrew.hook@nottingham.ac.uk