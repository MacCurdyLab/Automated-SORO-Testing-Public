%% Arm Position Datum Detection

% Date: 8/27/2025
% Inputs: 
%   TifFile - string that points to a .tif file that contains images 
%   of a soft actuator at multiple different bend states
%   ImgProcessed - string that points to a .tif file that is undistorted 
%   and includes the centroid and bounding box markers
%   positionCellArray - Cell array that contains the XY coordinates of
%   every point in the processed .tif file
%   pixels_per_mm - estimated conversion between pixel and real scale based
%   on diameter of markers. 

% Outputs: 
%   AllDatumPTs - Cell Array that contains the measured coordinates of
%   every datum point in every frame

% Objective: Function to semi-automatically identify the datum points (the
% points on the mounting fixture) from user input on first frame. The user
% manually identifies the first datum point in the first frame, then we use
% the known arm positions to estimate where the remaining datum points 
% % should be based on the movement of the arm. 

% Note 2: reported datum points are left in PIXEL coordinates (origin in top Left)

function [AllDatumPTs, SortedPoints] = DatumDetector(TifFile, ImgProcessed, positionCellArray, pixels_per_mm, change_angle)

% % genericFile = 'Hainsworth_95A_multipose_horizontal'; Marker_Diameter = 6.35;
% genericFile = 'Hainsworth_95A_multipose_vac'; Marker_Diameter = 6.35;
% Images = strcat(genericFile, '_NA_TestImgs.tif'); close all; clc;
% % [ImgProcessed, positionCellArray, pixels_per_mm] = ProcessTIFImage(Images, Marker_Diameter, 'Hainsworth_95A', 2);
% TifFile = Images;
% change_angle = 2;

% load stored data from when images were taken
FileName = erase(TifFile, '_NA_TestImgs.tif');
positionMatFile = strcat(FileName, '_ArmPositions.mat');
orientationMatFile = strcat(FileName, '_ArmOrientations.mat');

dist = sqrt( (0.0386)^2 + (0.01335)^2  ); % approximate distance from ee position to first marker. Fixed distance. 
ee_positions = load(positionMatFile).ee_positions;
if change_angle == 1
    ee_angles = load(orientationMatFile).ee_angles(:,change_angle);
    first_alpha = ee_angles(1) + atan(13.3/38.6); % angle from ee centroid to firse marker plus end effector orientation

    datum_x = ee_positions(1, 1) + dist*cos(first_alpha);
    datum_y = ee_positions(1, 2) + dist*sin(first_alpha);
    datum_z = ee_positions(1, 3);
    
    first_estd_datum_x = datum_y;
    first_estd_datum_z = datum_x;

elseif change_angle == 2
    ee_angles = load(orientationMatFile).ee_angles(:,change_angle);
    first_alpha = ee_angles(1) + atan(13.3/38.6); % angle from ee centroid to firse marker plus end effector orientation
    first_estd_datum_x = ee_positions(1, 1) + dist*sin(first_alpha);
    first_estd_datum_z = ee_positions(1, 3) + dist*cos(first_alpha);

end

% show first frame and ask user to click on a specific point
first_frame = imread(ImgProcessed, 1);
imshow(first_frame)

title('Click on First Datum Point:' )
roi = drawpoint('Color', 'magenta', 'Tag', '*');
selected_pt = roi.Position;

% create empty arrays to store things we care about later
% estd_datum_pos = cell(length(positionCellArray), 1); % estimated datum marker position in real coordinates
% estd_datum_pixel = cell(length(positionCellArray), 1); % estimated datum marker position in pixel coordinates
% delta_datum = cell(length(positionCellArray), 1); % change in datum marker position in real coordinates
% delta_pixel = cell(length(positionCellArray), 1); % change in datum marker position in pixel coordinates
AllDatumPTs = cell(length(positionCellArray), 1);% cell array to store all 3 datum centroids for every frame
SortedPoints = cell(length(positionCellArray), 1); % cell array to store sorted points
% ActualMeasPos = cell(length(positionCellArray), 1);

% find closest point in frame data set to selected point
% points = positionCellArray{1};
% [X_measured, Y_measured] = closestPoint(selected_pt(1), selected_pt(2), points(:, 1), points(:, 2));
% ActualMeasPos{1} = [X_measured, Y_measured];
% estd_datum_pos{1} = [X_measured, Y_measured];

% position of first marker with respect to end effector pose
% dist = sqrt( (0.0386)^2 + (0.01335)^2  ); % distance from ee position to first marker. Fixed distance. 
% first_alpha = ee_angles(1) + atan(13.3/38.6); % angle from ee centroid to firse marker plus end effector orientation
% first_estd_datum_x = ee_positions(1, 1) + dist*sin(first_alpha);
% first_estd_datum_z = ee_positions(1, 3) + dist*cos(first_alpha);
first_datum = [first_estd_datum_x, first_estd_datum_z];
dist_bw_datum_markers = 13 * pixels_per_mm;

close
% for each frame, estimate datum base from ee position and angle. use
% estimate to find actual measured point. 
datum_angles = [];
cam_ang = [];
for i = 1:length(positionCellArray)

    % load all data points from frame
    points = positionCellArray{i};

    % estimate first datum marker position in real coords based on EE pose
    alpha = ee_angles(i) + atan(13.3/38.6); % angle from vertical to EE center to first datum marker

    % estimate position of first datum point in image frame based on
    if change_angle == 2
        estd_datum_x = ee_positions(i, 1) + 0.5*dist*sin(alpha);
        estd_datum_z = ee_positions(i, 3) + 0.5* dist*cos(alpha);

        % find difference between current datum and first datum
        datum = [estd_datum_x, estd_datum_z];
        difference = first_datum - datum ;

        delta_pixels = difference*1000*pixels_per_mm; % + [20, -20]; % convert from m to mm before converting to pixel coordinates

        est_pos = [selected_pt(1), selected_pt(2)] + delta_pixels;

        [measuredx, measuredy] = closestPoint(est_pos(1), est_pos(2), points(:, 1), points(:, 2));

        % first points found, find the rest
        Datum = zeros(3, 2);
        Datum(1, :) = [measuredx, measuredy];
        % 
        next_ptx = measuredx - dist_bw_datum_markers * sin(ee_angles(i));
        next_pty = measuredy - dist_bw_datum_markers * cos(ee_angles(i));
        [Datum2tx, Datum2ty] = closestPoint(next_ptx, next_pty, points(:,1), points(:,2));

        last_ptx = measuredx - 2*dist_bw_datum_markers * sin(ee_angles(i));
        last_pty = measuredy - 2*dist_bw_datum_markers * cos(ee_angles(i));
        [Datum3tx, Datum3ty] = closestPoint(last_ptx, last_pty, points(:,1), points(:,2));

        % next_ptx = est_pos(1) - dist_bw_datum_markers * sin(ee_angles(i));
        % next_pty = est_pos(2) - dist_bw_datum_markers * cos(ee_angles(i));
        % [Datum2tx, Datum2ty] = closestPoint(next_ptx, next_pty, points(:,1), points(:,2));
        % 
        % last_ptx = est_pos(1) - 2*dist_bw_datum_markers * sin(ee_angles(i));
        % last_pty = est_pos(2) - 2*dist_bw_datum_markers * cos(ee_angles(i));
        % [Datum3tx, Datum3ty] = closestPoint(last_ptx, last_pty, points(:,1), points(:,2));

    elseif change_angle == 1
        datum_x = ee_positions(i, 1) + dist*cos(alpha);
        datum_y = ee_positions(i, 2) + dist*sin(alpha);
        datum_z = ee_positions(i, 3);

        estd_datum_x = datum_y;
        estd_datum_z = datum_x;

        % find difference between current datum and first datum
        datum = [estd_datum_x, estd_datum_z];
        difference = first_datum - datum;

        delta_pixels = difference*1000*pixels_per_mm; % convert from m to mm before converting to pixel coordinates

        est_pos = [selected_pt(1), selected_pt(2)] - delta_pixels;

        [measuredx, measuredy] = closestPoint(est_pos(1), est_pos(2), points(:, 1), points(:, 2));

        % first points found, find the rest
        Datum = zeros(3, 2);
        Datum(1, :) = [measuredx, measuredy];

        next_ptx = measuredx + dist_bw_datum_markers * sin(ee_angles(i));
        next_pty = measuredy + dist_bw_datum_markers * cos(ee_angles(i));
        [Datum2tx, Datum2ty] = closestPoint(next_ptx, next_pty, points(:,1), points(:,2));

        last_ptx = measuredx + 2*dist_bw_datum_markers * sin(ee_angles(i));
        last_pty = measuredy + 2*dist_bw_datum_markers * cos(ee_angles(i));
        [Datum3tx, Datum3ty] = closestPoint(last_ptx, last_pty, points(:,1), points(:,2));

        % next_ptx = est_pos(1) + dist_bw_datum_markers * sin(ee_angles(i));
        % next_pty = est_pos(2) + dist_bw_datum_markers * cos(ee_angles(i));
        % [Datum2tx, Datum2ty] = closestPoint(next_ptx, next_pty, points(:,1), points(:,2));
        % 
        % last_ptx = est_pos(1) + 2*dist_bw_datum_markers * sin(ee_angles(i));
        % last_pty = est_pos(2) + 2*dist_bw_datum_markers * cos(ee_angles(i));
        % [Datum3tx, Datum3ty] = closestPoint(last_ptx, last_pty, points(:,1), points(:,2));
    end



    Datum(2, :) = [Datum2tx, Datum2ty];
    Datum(3, :) = [Datum3tx, Datum3ty];

    AllDatumPTs{i} = Datum;

    delta_x = Datum(3, 1) - Datum(1, 1);
    delta_y = Datum(3, 2) - Datum(1, 2);

    if delta_x < 0 && delta_y < 0
        delta_x = abs(delta_x);
        delta_y = abs(delta_y);
        datum_angle = atan(delta_x/delta_y);

    elseif delta_x < 0 && delta_y > 0
        delta_x = abs(delta_x);
        delta_y = abs(delta_y);
        datum_angle = (pi/2-atan(delta_x/delta_y)) + pi/2;

    elseif delta_x > 0 && delta_y < 0
        delta_x = abs(delta_x);
        delta_y = abs(delta_y);
        datum_angle = -atan(delta_x/delta_y);

    elseif delta_x > 0 && delta_y > 0
        delta_x = abs(delta_x);
        delta_y = abs(delta_y);
        datum_angle = -(pi/2-atan(delta_x/delta_y)) - pi/2 + 2*pi;

    end
    
    % datum_angles = [datum_angles; abs(datum_angle)];
    camera_angle = datum_angle - ee_angles(i); % measure how far the datum is pointed away from the commanded heading
    % cam_ang = [cam_ang; camera_angle]

    % % uncomment the below portion to see where the estimated points
    % % actually fall.
    % 
    % est_pts = zeros(3, 2);
    % est_pts(1, :) = est_pos;
    % est_pts(2, :) = [next_ptx, next_pty];
    % est_pts(3, :) = [last_ptx, last_pty];
    % i
    % Datum
    % est_pts
    % figure(50000)
    % imshow(imread(ImgProcessed, i))
    % for j = 1:length(Datum)
    %     hold on
    %     plot(est_pts(j, 1), est_pts(j, 2), 'r+', 'MarkerSize', 30, 'LineWidth', 2)
    % end

    % with the datum located, sort the points by finding the closest point
    % to the datum base, then the closest to that point, and so on until
    % all points are listed. 
    unsorted_x = points(:, 1); 
    unsorted_y = points(:, 2);
    % figure()
    % scatter(unsorted_x, unsorted_y); axis equal; hold on
    % [unsorted_x, unsorted_y] = Rotate(unsorted_x, unsorted_y, camera_angle);
    % scatter(unsorted_x, unsorted_y)

    current = Datum(1, :);
    sorted = current;


    unsorted_x(unsorted_x == current(1)) = [];
    unsorted_y(unsorted_y == current(2)) = [];
   
    while isempty(unsorted_x) == false
        [nearest_x, nearest_y] = closestPoint(current(1,1), current(1,2), unsorted_x, unsorted_y);
        nearest = [nearest_x, nearest_y];
        sorted = [sorted; nearest];
        
        unsorted_x;
        index_x = find(unsorted_x==nearest_x, 1);
        unsorted_x(index_x(1)) = [];

        unsorted_y;
        index_y = find(unsorted_y==nearest_y, 1);
        unsorted_y(index_y(1)) = [];

        X_len = length(unsorted_x);
        Y_len = length(unsorted_y);
        
        % unsorted_x(unsorted_x == nearest_x) = [];
        % unsorted_y(unsorted_y == nearest_y) = [];
        
        current = nearest;
    end
    % 
    % rotate datum points and sorted points by the angle that the camera is
    % tilted. 
    % datum_x = Datum(:, 1);
    % datum_y = Datum(:, 2);
    % [datum_x, datum_y] = Rotate(datum_x, datum_y, camera_angle);
    % Datum = [datum_x, datum_y];

    % sorted_x = sorted(:, 1);
    % sorted_y = sorted(:, 2);
    % [rotd_sorted_x, rotd_sorted_y] = Rotate(sorted_x, sorted_y, camera_angle);
    % 
    % sorted = [rotd_sorted_x, rotd_sorted_y];


    % remove datum points from SortedPoints
    sorted(3, :) = [];
    sorted(2, :) = [];
    sorted(1, :) = [];

    SortedPoints{i} = sorted;



end

end