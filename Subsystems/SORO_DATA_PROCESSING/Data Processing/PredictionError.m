%% function to compute error between predicted actuator profile and Measured Data
%
% Date: 8/19/2025
% Inputs:
%   AllErrors - matrix, 'double', matrix of size frames x markers that contains the
%   cartesian distance from a measured marker to the equivalent point on
%   the predicted curve. 
%   actuatorLength - scaler, 'double', estimated or measured length of the 
%   actuator under test (in millimeters)

% Output:
%   ERROR - scalar that describes the error of an actuator fit

% Objective: Function that computes an error metric that compares the
% predicted fit of an actuator to the experimentally measured data. 

function [ERROR] = PredictionError(AllErrors, actuatorLength)
[frames, markers] = size(AllErrors);

all_col_errors = zeros(frames, 1);
for this_frame = 1:frames
    error_this_frame = AllErrors(this_frame, :); 
    squared_errors = error_this_frame.^2;
    SSE = sum(squared_errors);
    all_col_errors(this_frame) = sqrt(SSE)/(markers*actuatorLength);
end

NORM = norm(AllErrors)

ERROR = sum(all_col_errors);

end