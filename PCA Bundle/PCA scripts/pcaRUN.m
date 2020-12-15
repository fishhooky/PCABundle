%% Script that does PCA

global training test output
[coeff,score,latent,tsquared,explained,mu] = pca(training);
    
output{1}=coeff;
output{2}=score;
output{3}=latent;
output{4}=tsquared;
output{5}=explained;
output{6}=mu;