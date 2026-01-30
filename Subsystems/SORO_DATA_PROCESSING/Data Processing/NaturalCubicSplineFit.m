%% Natural Spline Fit
% 
% Date: 7/22/2025
% Inputs:
%   SortedPoints - cell array with cells that contain m x 2 matrices
%   describing the x, y coordinates of each fiducial centroid. Each cell is
%   a different frame. note: points should first be converted to REAL
%   coordinates before fitting splines
%   genericFile - optional - string describing images that SortedPoints
%   came from. If included, the input pressure will be added to the struct
%   that describes the spline curve for a specific frame. 
%
% Output:
%   allCurves - cell array that where each cell contains a struct describing a
%   piecewise natural spline curve for each set of points in SortedPoints 
% 
% Objective: function to generate spline curves that describe the bending
% of an actuator for various pressures. 

function allCurves = NaturalCubicSplineFit(Points, num_segments, genericFile)
% empty array to store information
allCurves = cell(length(Points), 1);
% if genericFile was given, find the relevant .mat file with the input
% pressures.
if exist('genericFile', 'var')
    % read input pressures from .mat file
    PressureMatFile = strcat(genericFile, '_inputPressures.mat');
    matStruct = load(PressureMatFile); 
    pressures = matStruct.AllInputPressures;
end

% for every frame, separate the X and Y points. Invert the Y axis, then
% feed into cscvn to generate natural spline curve. Save in array. If
% genericFile was given, add input pressure to curve struct before saving. 
for i = 1:length(Points)

    points = Points{i};
    
    % reduce number of points
    odds = 1:2:length(points);
    evens = 2:2:length(points);

    % num_segments = 3 

    % decide which rows of points to keep. 
    keep_indexes = round(linspace(1, length(points), num_segments+1), 0);

    points2 = zeros(length(keep_indexes), 2);
    % remove even numbered rows

    for j = 1:length(keep_indexes) % need to reverse order of evens
        points2(j, :) = points(keep_indexes(j), :);
    end

    points = points2;

    % actuatorCurve = csape(X, Y, 'second');

    % d = linspace(0, 1, length(points));
    % actuatorCurvex = csaps(points(:, 1), d, 0.25);
    % actuatorCurvey = csaps(points(:, 2), d, 0.25);
    % actuatorCurvex.breaks = [actuatorCurvex.breaks, actuatorCurvey.breaks];
    % actuatorCurvex.coefs = [actuatorCurvex.coefs; actuatorCurvey.coefs];

    actuatorCurve = cscvn(points');

    [estimated_length, segment_lengths] = EstimateBreakLength(actuatorCurve.breaks);
    actuatorCurve.EstimatedLength = estimated_length;

    if ~exist('genericFile', 'var')
        allCurves{i} = actuatorCurve;
        % allCurves{i} = actuatorCurvex;
    elseif exist('genericFile', 'var')
        % PRESSURES
        actuatorCurve.InputPressure = pressures(i);
        allCurves{i} = actuatorCurve;
        % actuatorCurvex.InputPressure = pressures(i);
        % allCurves{i} = actuatorCurvex;
    end

end

end