%% Circrotate_error_for_fmincon(rot_angle, all_est_pts, genericFile)
% 
% Date: 9/30/2025

% N = number of markers on an actuator
% M = number of inflation states imaged

% Inputs:
%   offsets - float, double. Angle by which an actuator's estimated points
%   UPDATE REQUIRED
%   are rotated to minimize error. 
%
%   all_est_pts - Cell Array, M length cell array. Each cell contains an
%   Nx2 matrix of X, Y coordinates of estimated points
%
%   genericFile - string, 'char'. Shortened version of name of .tif file
%   that contains images of inflation states. 

% Output:
%   error - scalar, double. metric that approximates how well a predicted
%   actuator fit matches real data. 

% Objective: Error function for use in FMINCON optimization to estimate 
% position of the neutral axis of an actuator under test. 

function ERROR = Circrotate_error_for_fmincon(rot_angle, all_est_pts, unique_pres, allCurves, splin_rad, act_len)
num_frames = length(allCurves);
num_markers = length(allCurves{1});
all_dists_circ = zeros(num_frames, num_markers);

for index = 1:length(unique_pres)
    P_in = unique_pres(index);

    x_real = all_est_pts{index}(:, 1);
    y_real = all_est_pts{index}(:, 2);

    curve = allCurves{index};
    act_length = curve.EstimatedLength;

    radius_predicted = ppval(splin_rad, P_in);

    center = [0, radius_predicted];

    betas = linspace(0, act_length/radius_predicted, 1000) ;

    x_predicted = center(1) + radius_predicted * sin(betas);
    y_predicted = center(2) - radius_predicted * cos(betas);

    [x_predicted, y_predicted] = Rotate(x_predicted, y_predicted, (135-rot_angle)*pi/180 );
    [c1, c2] = Rotate(center(1), center(2), (135-rot_angle)*pi/180 );
    center = [c1, c2];

    errors = zeros(length(x_real), 1);
    closest_pts = zeros(length(x_real), 2);
    for j = 1:length(x_real)
        [closest_pts(j, 1), closest_pts(j, 2)] = closestPoint(x_real(j), y_real(j), x_predicted, y_predicted);
        errors(j) = dist_2pts(closest_pts(j, 1), closest_pts(j, 2), x_real(j), y_real(j))/(act_length*length(x_real));
        all_dists_circ(index, j) = dist_2pts(closest_pts(j, 1), closest_pts(j, 2), x_real(j), y_real(j));
    end

    errors;
    SSEs2(index) = sum(errors);

    
end

ERROR = PredictionError(all_dists_circ, act_len)

end