%% ActuatorRTCurve
% 
% Date: 10/20/2025
% Inputs:
%   P_in - float, double - Model Input pressure in psi
% 
%   R - R matrix, double - matrix, double. R matrix found by FindActuatorMatrices.m
%   Contents of this matrix describe a second-order
%   polynomial fit. This fit determines how the coefficients of a higher-order
%   polynomial (that describes the distance from the origin to any point
%   along an actuator) changes with pressure.
% 
%   T - matrix, double. matrix, double. T matrix found by FindActuatorMatrices.m
%   Contents of this matrix describe a second-order
%   polynomial fit. This fit determines how the coefficients of a higher-order
%   polynomial (that describes the angle from the positive X axis to any point along the
%   actuator) changes with pressure. 
%
% Output:
%   predicted_coords - n x 2 matrix, double. - Contains x, y coordinates of
%   points along curve
%   SingleCurve - ppform defined 2D spline that describes actuator curve. 
% 
% Objective: Generate a single curve that represents some actuator at some
% input pressure

function [predicted_coords, SingleCurve] = ActuatorRTCurve(P_in, R, T)

[ray_length_coeff, theta_coeff] = FindPolarCoefficients(P_in, R, T);
dimensionless = linspace(0, 1, 1000);

rays = polyval(ray_length_coeff, dimensionless);
angles = polyval(theta_coeff, dimensionless);

x_predicted = rays.*cos(angles);
y_predicted = rays.*sin(angles);
x_predicted = x_predicted - x_predicted(1);
y_predicted = y_predicted - y_predicted(1);

SingleCurve =  NaturalCubicSplineFit( {[x_predicted', y_predicted']}, (length(x_predicted)-1) );
SingleCurve = SingleCurve{1};

predicted_coords = [x_predicted', y_predicted'];

end