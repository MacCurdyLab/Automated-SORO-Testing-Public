%% Find Actuator Matrices
% 
% Date: 8/27/2025
% Inputs:
%   allCurves - Cell Array, 'cell'. each cell describes a ppform spline that
%   represents an inflation state. 
%   input_pressures - vector, double. list of pressures that were input to
%   during testing to form the ppform splines in allCurves

%   RAYS_ORDER - integer, double. Defines the order of polynomial used to
%   determine distance from origin (actuator base) to any point along the
%   actuator, for each inflation state. 

%   THETA_ORDER - integer, double. Defines the order of polynomial used to
%   determine angle from the positive X axis to any point along the
%   actuator, for each inflation state.
%
% Output:
%   R - matrix, double. Contents of this matrix describe a second-order
%   polynomial fit. This fit determines how the coefficients of a higher-order
%   polynomial (that describes the distance from the origin to any point
%   along an actuator) changes with pressure. 

%   T - matrix, double. Contents of this matrix describe a second-order
%   polynomial fit. This fit determines how the coefficients of a higher-order
%   polynomial (that describes the angle from the positive X axis to any point along the
%   actuator) changes with pressure. 
% 
% Objective: Use a series of spline curves that represent each inflation
% state to find a set of two matrices that can be used to estimate an
% actuator's position based on input pressure alone. 


function [R, T] = FindActuatorMatrices(allCurves, input_pressures, RAYS_ORDER, THETA_ORDER)

% RAYS_ORDER = 4;
% THETA_ORDER = 4;

odd_indices = 1:2:length(allCurves{1}.coefs);
even_indices = 2:2:length(allCurves{1}.coefs);
% segments = 1:(allCurves{1}.pieces);
all_r = [];
all_theta = [];

for i = 1:length(allCurves)
    thisCurve = allCurves{i};
    segments = 1:(thisCurve.pieces);
    % % gather real point data
    % meas_pts = all_meas_pts{i};
    % 
    % % measure maximum value of theta needed to plot spiral (in polar
    % % coordinates)
    % end_angle = atan2( meas_pts(end, 2), meas_pts(end, 1) );
    % if end_angle < 0
    %     end_angle = end_angle + 2*pi;
    % end

    % evaluate spline curves at numerous points to create rays.
    all_x = [];
    all_y = [];

    for ia = 1:(length(thisCurve.coefs)/2)
        t_eval = linspace(0, thisCurve.breaks(ia+1)-thisCurve.breaks(ia), 50);
        y_poly = poly2sym( thisCurve.coefs( even_indices(ia), :) );
        y_eval = double(subs(y_poly, t_eval));

        x_poly = poly2sym( thisCurve.coefs( odd_indices(ia), :) );
        x_eval = double(subs(x_poly, t_eval));

        % remove repeated ray lengths
        x_eval(1) = [];
        y_eval(1) = [];

        all_x = [all_x; x_eval'];
        all_y = [all_y; y_eval'];

    end

    % measure cartesian distance from origin to spline (these are our ray
    % magnitudes)
    rays = zeros(length(all_x), 1);
    for ib = 1:length(all_x)
        rays(ib) = dist_2pts(all_x(ib), all_y(ib), 0, 0);
    end

    % measure angle theta to every point along spline
    thetas = zeros(length(all_x), 1);
    for ic = 1:length(all_x)
        theta = atan2(all_y(ic), all_x(ic));
        if theta < 0
            theta = theta + 2*pi;
        end
        thetas(ic) = theta;
    end

    % fit function to ray length along actuator (as a percentage of length
    % along actuator)
    d = (0:(1/(length(rays)-1)):1 );
    ray_function = polyfit(d, rays, RAYS_ORDER);

    % fit function to theta along actuator
    theta_function = polyfit(d, thetas, THETA_ORDER);

    % estimate length of actuator based on breaks
    breaks_reduced = [];
    for id = segments
        this_break = thisCurve.breaks(id+1)-thisCurve.breaks(id);
        breaks_reduced = [breaks_reduced; this_break];
    end
    est_len = sum(breaks_reduced.^2);

    % save all coeffs
    all_r = [all_r; ray_function];
    all_theta = [all_theta; theta_function];
    % save measured attributes in curve struct
    % thisCurve.EndAngle = end_angle;
    thisCurve.EstimatedLength = est_len;
    thisCurve.RayCoeffs = ray_function;
    thisCurve.ThetaCoeffs = theta_function;
    thisCurve.Rays = rays;
    thisCurve.Thetas = thetas;
    allCurves{i} = thisCurve;

end

%% pressure predicitive spiral
% second order
R = zeros(RAYS_ORDER+1, 3);
for q = 1:RAYS_ORDER+1
    r_coeffs = polyfit(input_pressures, all_r(:, q), 2);
    R(q, 1) = r_coeffs(1);
    R(q, 2) = r_coeffs(2);
    R(q, 3) = r_coeffs(3);
end


T = zeros(THETA_ORDER+1, 3);
for g = 1:THETA_ORDER+1
    theta_coeffs = polyfit(input_pressures, all_theta(:, g), 2);
    T(g, 1) = theta_coeffs(1);
    T(g, 2) = theta_coeffs(2);
    T(g, 3) = theta_coeffs(3);
end

end