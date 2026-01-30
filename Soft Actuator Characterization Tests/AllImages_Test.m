clear; clc; close all
% ======= START Manual Inputs =======

% String that names the actuator to test
Actuator = "Hainsworth_95A_1";

% maximum pressure for the actuator to test in psi
max_pressure = 30;

% diameter of fiducial stickers in mm
Marker_Diameter = 6.35; 

% Wan actuator has smaller markers than others 
% if Actuator == "Wan_85A" | Actuator == "Wan_85A_2" | Actuator == "Wan_85A_3" | Actuator == "Wan_85A_4"
%     Marker_Diameter = Marker_Diameter/2
% end


% Hansell actuator has smaller markers
if Actuator == "Hansell_Endo_30A"
    Marker_Diameter = 5;
end

% time in seconds that the actuator will be pressurized. 
step_time = 1; 
% time in seconds that a vacuum will be pulled in the actuator.
vac_time = step_time * 1; 

% ======= END Manual Inputs =======

%% Gather Images
% [Directory, VerticalImages, HorizontalImages] = AllImages(Actuator, max_pressure, [1, 2], step_time, vac_time);

VerticalImages = append(Actuator, '_multipose_vac_NA_TestImgs.tif');
vertTest = append(erase(VerticalImages, '_NA_TestImgs.tif'), '_ArmOrientations.mat');
matStruct = load(vertTest);
Vert_angles = matStruct.ee_angles(:, 2);

HorizontalImages = append(Actuator, '_multipose_horizontal_vac_NA_TestImgs.tif');
horizTest = append(erase(HorizontalImages, '_NA_TestImgs.tif'), '_ArmOrientations.mat');
matStruct = load(horizTest);
Horiz_angles = matStruct.ee_angles(:, 1);

%% Load input pressures
PressureMatFile = strcat(Actuator, '_multipose_horizontal_vac_inputPressures.mat');
matStruct = load(PressureMatFile); 
input_pressures_horiz = matStruct.AllInputPressures;
input_pressures = unique(input_pressures_horiz);

PressureMatFile = strcat(Actuator, '_multipose_vac_inputPressures.mat');
matStruct = load(PressureMatFile); 
input_pressures_vert = matStruct.AllInputPressures;

unique_angles = unique(Horiz_angles);
unique_pres = unique(input_pressures_vert); 

%% Process Images

% I = imread("Hainsworth_95A_multipose_horizontal_vac_NA_TestImgs.tif", 25);
% 
% [BW, Lower_bd, Upper_bd] = FindHSVbounds(I);
% =============================
%% Vertical 
vertcamNum = 'Front';
vert_moving = 2;
disp('PROCESS VERTICAL PLANE IMAGES...')

% I = imread(VerticalImages, 45);
% imshow(I)
% [BW, Lower_bd, Upper_bd, RGB, HSV] = FindHSVbounds(I);

[ImgProcessed1, VertpositionCellArray, Vert_pixels_per_mm] = ProcessTIFImage(VerticalImages, Marker_Diameter, Actuator, vertcamNum, 300);
[AllDatumPTs_Vert, Vert_SortedPoints_cell] = DatumDetector(VerticalImages, ImgProcessed1, VertpositionCellArray, Vert_pixels_per_mm, vert_moving);

% convert measured points to real coordinates
Vert_all_meas_pts = cell(length(Vert_SortedPoints_cell), 1);
for i = 1:length(Vert_SortedPoints_cell)
    % gather real point data

    Vert_all_meas_pts{i} = PixtoReal(Vert_SortedPoints_cell{i}, Vert_pixels_per_mm);
end
num_segments = length(Vert_SortedPoints_cell{1})-1;
allCurves_Vert = NaturalCubicSplineFit(Vert_all_meas_pts, num_segments, strcat(Actuator, '_multipose_vac') );

% =============================
%% Horizontal
horizcamNum = 'Top';
vert_moving = 1;
disp('PROCESS HORIZONTAL PLANE IMAGES...')
% I = imread(HorizontalImages, 35);
% imshow(I)
% [BW, Lower_bd, Upper_bd, RGB, HSV] = FindHSVbounds(I);
[ImgProcessed2, HorizpositionCellArray, Horiz_pixels_per_mm] = ProcessTIFImage(HorizontalImages, Marker_Diameter, Actuator, horizcamNum, 300);
[AllDatumPTs_Horiz, Horiz_SortedPoints_cell] = DatumDetector(HorizontalImages, ImgProcessed2, HorizpositionCellArray, Horiz_pixels_per_mm, vert_moving);

% convert measured points to real coordinates. 
Horiz_all_est_pts = cell(length(unique_pres), 1);
Horiz_all_meas_pts_exp = cell(length(unique_pres), 1);
all_horiz_X = zeros(length(Horiz_SortedPoints_cell{1}), length(unique(input_pressures_horiz)), length(unique_angles));
all_horiz_Y = all_horiz_X;


% rotate points from horizontal images to overlap, then find the average of
% each point along the actuator for each inflation state. 
for i = 1:length(Horiz_SortedPoints_cell)

    unique_h_angles = unique(Horiz_angles);
    % gather real point data
    Horiz_pts = PixtoReal(Horiz_SortedPoints_cell{i}, Horiz_pixels_per_mm);

    fix((i-1)/length(unique(input_pressures_vert)));

    angle = Horiz_angles(i) - pi/4 - abs(2*(unique_h_angles(1)-unique_h_angles(2)))*fix((i-1)/length(unique(input_pressures_vert)));
    [xr, yr] = Rotate(Horiz_pts(:, 1), Horiz_pts(:, 2), angle); 

    column = mod(i, length(unique(input_pressures_horiz)));
    if column == 0
        column = max(length(unique(input_pressures_horiz)));
    end
    page = fix((i-1)/length(unique(input_pressures_horiz))) + 1;
    all_horiz_X(:, column, page) = xr;
    all_horiz_Y(:, column, page) = yr;

    if i == length(Horiz_SortedPoints_cell)
        mean_x = mean(all_horiz_X, 3);
        mean_y = mean(all_horiz_Y, 3);
        sz_mean_x = size(mean_x);

        for aa = 1:sz_mean_x(2)
            Horiz_all_est_pts{aa} = [mean_x(:, aa), mean_y(:, aa)];
        end

    end
    % store experimental data for bend angle calculations
    Horiz_all_meas_pts_exp{i} = PixtoReal(Horiz_SortedPoints_cell{i}, Horiz_pixels_per_mm);
end

disp('FIT FUNCTIONS TO MEASURED ACTUATOR POSITIONS...')
num_segments = length(Horiz_SortedPoints_cell{1})-1;
allCurves_Horiz = NaturalCubicSplineFit(Horiz_all_est_pts, num_segments, strcat(Actuator, '_multipose_horizontal_vac') );
allCurves_Horiz_exp = NaturalCubicSplineFit(Horiz_all_meas_pts_exp, num_segments, strcat(Actuator, '_multipose_horizontal_vac') );
%% find matrices M and H
MAGNITUDE_ORDER = 4;
HEADING_ORDER = 4;
[M, H] = FindActuatorMatrices({allCurves_Horiz{1:length(unique(input_pressures_horiz))}}', unique(input_pressures_horiz), MAGNITUDE_ORDER, HEADING_ORDER);

% Save M and H to a .mat file
MH_location = append(pwd, '\Test Data\' , Actuator, '\MAT Files\', Actuator, '_MH_matrices.mat');
save(MH_location, 'M', 'H');

%% Generate Sag Surface
bend_angles_vert = FindBendAngles(VerticalImages, allCurves_Vert, num_segments, input_pressures_vert, 2, true)
bend_angles_horiz = FindBendAngles(HorizontalImages, allCurves_Horiz_exp, num_segments, input_pressures_horiz, 1, true)
[SagSurface_calib, max_sag, min_sag] = GenerateSagSurface(Actuator, true) % Requires BendAngles.mat to exist


ee_angles = [0:22.5:180] * pi/180
x_range = linspace(min(input_pressures), max(input_pressures), 500);
y_range = linspace(min(ee_angles), max(ee_angles), 500);

[X, Y] = meshgrid(x_range, y_range);
Z2 = SagSurface_calib(X, Y);


% Save Sag Surface in .mat file
matlocation = append(pwd, '\Test Data\' , Actuator, '\MAT Files\', Actuator, '_SagSurface.mat');
save(matlocation, 'SagSurface_calib');

disp('FIT FUNCTIONS SAVED!')

% MultiBendLoadCellTest_9_22
% 
% OffAxisLoadCellTest_9_25
