%% Script to close PCA run

close all force
evalin( 'base', 'clearvars -except test training output' )
clear global XVariableNames