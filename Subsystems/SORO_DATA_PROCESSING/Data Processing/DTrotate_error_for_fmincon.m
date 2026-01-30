%% DTrotate_error_for_fmincon(rot_angle, all_est_pts, genericFile)
% 
% Date: 9/30/2025

% N = number of markers on an actuator
% M = number of inflation states imaged

% Inputs:
%   offsets - float, double. Angle by which an actuator's estimated points
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

function ERROR = DTrotate_error_for_fmincon(rot_angle, all_est_pts, unique_pres, allCurves, DT_fit, act_len)
num_segments = allCurves{1}.pieces;
for kb = 1:length(all_est_pts)
    P_in = unique_pres(kb);
    curve = allCurves{kb};

    DT_angle_at_Pin = polyval(DT_fit, P_in);
    

    % segment_angles = linspace(0, DT_angle_at_Pin, num_segments);
    segment_angles = ones(1, length(all_est_pts{1})-1) * DT_angle_at_Pin/num_segments;
    % segment_angles(4) = segment_angles(4) *1.4

    estimated_points = zeros(length(all_est_pts{1}), 2);

    est_segment_lengths = ones(1, length(all_est_pts{1})-1) * curve.EstimatedLength/(num_segments);
    % est_segment_lengths = [0; curve.SegmentLengths]

    [final_TF_matrix, all_TF_matrices] = makeTFMatrix(segment_angles, est_segment_lengths);

    prev_tfs = eye(3);
    for kbb = 1:(length(estimated_points)-1)
        origin = [0; 0; 1];
        prev_tfs = prev_tfs * all_TF_matrices{kbb};
        pt = prev_tfs * origin;
        estimated_points(kbb+1, 1) = pt(1);
        estimated_points(kbb+1, 2) = pt(2);
    end

    [estimated_points(:, 1), estimated_points(:, 2)] = Rotate(estimated_points(:, 1), estimated_points(:, 2), ((135-rot_angle)*pi/180));
    
    errors = zeros(length(estimated_points), 1);
    for kbc = 1:length(estimated_points)
        errors(kbc) = dist_2pts(all_est_pts{kb}(kbc, 1), all_est_pts{kb}(kbc, 2), estimated_points(kbc, 1), estimated_points(kbc, 2))/(length(all_est_pts{kb}) * sum(est_segment_lengths));
        all_dists_DT(kb, kbc) = dist_2pts(all_est_pts{kb}(kbc, 1), all_est_pts{kb}(kbc, 2), estimated_points(kbc, 1), estimated_points(kbc, 2));
    end

    all_DT_errors(kb) = sum(errors);


end

ERROR = PredictionError(all_dists_DT, act_len)

end