%% estimate length of actuator from breaks
% 
% Date: 8/5/2025
% Inputs:
%   breaks - list of break points from cubic spline fit. in terms of
%   dimensionless length along actuator. Sum of square roots of distances
%   along the spline. 
%
% Output:
%   estimated_length = estimated length of actuator markers in mm
% 
% Objective: function to generate spline curves that describe the bending
% of an actuator for various pressures. 

function [estimated_length, segment_lengths] = EstimateBreakLength(breaks)
% find length of spline

breaks_reduced = zeros(length(breaks), 1);
segment_lengths = zeros(length(breaks)-1, 1);
for c = 1:(length(breaks) - 1)
    this_break = breaks(c+1)-breaks(c);
    breaks_reduced(c) = this_break;
    segment_lengths(c) = this_break^2;
end
estimated_length = sum(breaks_reduced.^2); % square each term, then add.

end