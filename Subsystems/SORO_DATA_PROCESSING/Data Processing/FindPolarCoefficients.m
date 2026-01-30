%% FindPolarCoefficients
% 
% Date: 8/27/2025
% Inputs:
%   P_in - float, double. Desired input pressure to model an actuator's
%   deformation

%   Ray_coeffs - matrix, double. R matrix found by FindActuatorMatrices.m
%   Contents of this matrix describe a second-order
%   polynomial fit. This fit determines how the coefficients of a higher-order
%   polynomial (that describes the distance from the origin to any point
%   along an actuator) changes with pressure.

%   Theta_coeffs - matrix, double. T matrix found by FindActuatorMatrices.m
%   Contents of this matrix describe a second-order
%   polynomial fit. This fit determines how the coefficients of a higher-order
%   polynomial (that describes the angle from the positive X axis to any point along the
%   actuator) changes with pressure. 

% Output:
%   real_ray_length_coeff - specific set of coefficients that define a
%   polynomial that describes the distance from the origin to any point
%   along an actuator

%   real_theta_coeff - specific set of coefficients that define a
%   polynomial that describes the angle from the positive X axis to any 
%   point along the actuator


% Objective: Evaluate R and T matrices for a desired input pressure and
% generate a curve that approximates an actuator's deformation.

function [real_ray_length_coeff, real_theta_coeff] = FindPolarCoefficients(P_in, Ray_coeffs, Theta_coeffs)
    asize = size(Ray_coeffs);
    Pins = zeros(1, asize(2));
    for i = 1:length(Pins)
        Pins(i) = P_in^(length(Pins) - i);
    end
    
    % evaluate coefficients at P_in
    raycoeffs = Ray_coeffs.* Pins;
    thetacoeffs = Theta_coeffs  .* Pins;
    
    % add rows together, return column vector of sums
    real_ray_length_coeff = sum(raycoeffs, 2);
    real_theta_coeff = sum(thetacoeffs, 2);
end
