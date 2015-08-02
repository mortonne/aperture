function shuffles = randperm2(iterations,datalen)
%RANDPERM2 - 2-Dimensional Random permutation.
%
% FUNCTION:
%   shuffles = randperm2(iterations,datalen)
%
% INPUT ARGS:
%   iterations = 1000;    % Number of random shuffles
%   datalen = 200;        % Total number of observations whos
%                         % indexes should be shuffled
%
% OUTPUT ARGS:
%   shuffles(iterations,datalen) - Shuffled indexes for each iteration.
%



[ign,shuffles] = sort(rand(iterations,datalen),2);


