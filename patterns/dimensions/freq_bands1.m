function [freqbins,freqbinlabels] = freq_bands1
%[freqbins,freqbinlabels] = freq_bands1

freqbins = [2 4; 4 8.1; 10 14; 16 26; 28 42; 44 100];
freqbinlabels = {'Delta', 'Theta', 'Alpha', 'Beta', 'Low Gamma', 'High Gamma'};
