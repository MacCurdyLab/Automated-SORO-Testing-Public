%% spline Coeff Eval
%
% N = number of markers attached to actuator
% M = number of inflation states imaged
% spline_segments = N - 1
%
% Date: 8/29/2025
% Inputs:
%   coeffs - matrix, 'double' , 2*N x 2 matrix that contains the
%   coefficients for 2 splines, x(t) and y(t), where the coordinates of the
%   points along the spline are ( x(t), y(t) )
%   breaks - vector, 'double', 1 x M vector that contains the domain of the
%   dimensionless number that increases along the length of the spline (t
%   in x(t), y(t) )
%   points_per_segment - integer, 'double'. Desired number of points to
%   resolve the spline into. 

% Output:
%   X - vector, 'double', 1 x points_per_segment that contains X
%   coordinates of points along the spline. 
%   Y - vector, 'double', 1 x points_per_segment that contains Y
%   coordinates of points along the spline. 

% Objective: Function to Evaluate the coefficients in a ppform spline with 
% a dimensionality of 2. The splines used to represent actuator curvatures

function [X, Y] = SplineCoeffEval_2D(coeffs, breaks, points_per_segment)

sz = size(coeffs);

odd_indices = 1:2:sz(1);
even_indices = 2:2:sz(1);

% X = zeros(50*length(coeffs)/2, 1);
% Y = zeros(50*length(coeffs)/2, 1);

X = zeros(length(breaks), 1);
Y = zeros(length(breaks), 1);

if points_per_segment ~= 0
    X = [];
    Y = [];
end

% figure()
% for every set of coefficients
for j = 1:(sz(1)/2)
    if points_per_segment == 0
        t_eval = breaks(j+1)-breaks(j);
    
        y_poly = poly2sym( coeffs( even_indices(j), :) );
        y_eval = double(subs(y_poly, t_eval));
    
        x_poly = poly2sym( coeffs( odd_indices(j), :) );
        x_eval = double(subs(x_poly, t_eval));
    
        X(j+1) = x_eval;
        Y(j+1) = y_eval;
    else
        t_eval = linspace(0, breaks(j+1)-breaks(j), points_per_segment);

        y_poly = poly2sym( coeffs( even_indices(j), :) );
        y_eval = double(subs(y_poly, t_eval));

        x_poly = poly2sym( coeffs( odd_indices(j), :) );
        x_eval = double(subs(x_poly, t_eval));

        X = [X, x_eval];
        Y = [Y, y_eval];
    end

end


end