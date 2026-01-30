%% FitCircles
% 
% Date: 8/29/2025
% Inputs:
%   PointsCellArray - N length cell array. Each cell contains an Mx2 matrix
%   that contains the X, Y coordinates of the data points that we want to
%   fit a circle to. 

% Output:
%   All_radii - vector, 'double'. Nx1 List of  radii found that fit the provided
%   data points
% 
%   All_centers - matrix, 'double'. Nx2 matrix of X, Y coordinates of
%   centers of circles that fit provided data points. 

% Objective: fit N circles to N sets of (x, y) coordinates

function [All_radii, All_centers] = FitCircles(PointsCellArray)

All_radii = zeros(length(PointsCellArray), 1);
All_centers = zeros(length(PointsCellArray), 2);

for i = 1:length(PointsCellArray)
    A = PointsCellArray{i}';
    % ID Coope method for fitting a circle
    % https://ir.canterbury.ac.nz/server/api/core/bitstreams/89e305b2-12b0-4156-ad16-1a5c7ce93bc9/content
    [n,m] = size(A);
    y = [A', ones(m, 1)]\sum(A.*A)';
    center = .5*y(1:n); 
    All_centers(i, :) = center;
    All_radii(i) = sqrt(y(n+1) +center'*center);
end

end