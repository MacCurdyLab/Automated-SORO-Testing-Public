% %% SORO Test DEMO 
% 
% % Date: 12/1/2025
% 
% % Objective: The main goal of this script is to provide a sample workflow
% % for a test using the Soft Robotics test setup. Run sections to see plots
% % and explanations for each major component. The goal of this script is to
% % serve as an introduction to the previously written code, provide building
% % blocks that can be easily copy/pasted to create new tests, and provide a
% % sample test workflow. 
% 
% % NOTE: for the sake of simplicity, this demo does not account for 
% % additional actuator deformation due to gravity. 
% 
% %% Clear workspace to ensure DEMO starts from a clean state. 
% clear; clc; close all
% 
% %% Add helper functions to MATLAB Path
% addSOROpaths
% % assumes that main folder is clone of GitHub repository
% 
% %% Activate components of the test
% 
% % turn on light boxes behind each camera. (Manual)
% 
% % Cameras
% CameraIdentification % identify which camera is which
% 
% FrontCam
% cam1 = webcam(FrontCam); % set up camera
% cam1.Exposure = -4; % exposure value may need to change depending on lighting conditions
% TopCam
% cam2 = webcam(TopCam);
% cam2.Exposure = -8; % exposure value may need to change depending on lighting conditions
% 
% % Labjack
% [ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack(); % Initialize labjack
% channels = [4, 10]; % [AIO channels to stream data from, excitation voltage]
% scanRate = 1000; % scan rate in Hz
% AllData = [];    % empty array to store data in
% 
% % UR5 Control
% % on Teach Pendant, Activate UR Server Script - see https://o365coloradoedu-my.sharepoint.com/:w:/r/personal/maccurdy_colorado_edu/_layouts/15/Doc.aspx?sourcedoc=%7BF41ECE95-F398-4737-88D2-E90C076C16E2%7D&file=SORO%20Testing%20Documentation.docx&action=default&mobileredirect=true
% % or MACLab Onedrive > Lab Projects > Automated Soft Robotics Testing >
% % User Guides > SORO Testing Documentation
% 
% IP = '192.168.1.10';  % IP address of physical UR5
% position = [0.300, -0.075, .325]; % desired (X,Y,Z) position of end effector, in METERS
% eulerangles = [0, pi/4, 0]; % desired orientation of End Effector, ZYZ rotation order, in RADIANS
% movetime = 3; % Time in seconds that the arm will take to move to desired position
% 
% % move to desired position
% MoveToPose(IP, position, eulerangles, movetime)
% pause(1)
% 
% %% Take images of an actuator in some different configurations
% % We'll take images of the actuator in a series of different orientations
% % while gathering data with the LabJack. 
% 
% % First, start with the Vertical plane (perpendicular to workbench surface)
% Actuator = 'TestActuator'; % String that identifies the actuator to be tested. 
% extra = '_Demo_vertical';
% FileName = strcat(Actuator, extra);
% % A new folder with this name will be created under TestData
% 
% max_pressure = 30; % maximum pressure supplied to the actuator, in PSI
% pressures = linspace(0, max_pressure, 6);
% 
% % desired position of the end effector. This is an arbitrarily chosen point
% % that does not risk collision with the rest of the system. 
% % NOTE: depends on configuration of test setup. 
% des_x = 12.5*25.4; % mm
% des_y = 0; % meters
% des_z = 11.5*25.4; % mm
% 
% % for this sample test, we'll change the direction that the actuator is
% % pointing. 
% angles = [0:90:180] * pi/180;
% step_time = 1; 
% 
% AllData = [];
% 
% % we use 1/4" diameter stickers attached to the actuator to measure its
% % position. 
% Marker_Diameter = 6.35;
% Ltool = 67.5 + Marker_Diameter/2 + 8; % distance from end effector point to first marker on actuator
% % 67.5 mm for length of actuator, 1/2 marker diameter to get to centroid of
% % first marker, and 8 mm to account for the UR5 thread protector. 
% 
% for i = 1:length(angles)
%     SetHIPressure(0) % Sets pressure from Proportional Pressure Control Valve to specified pressure in psi
% 
%     ToggleVacuumChannel(1) % Draw vacuum in actuator while moving
% 
%     % calculate EE position based on desired offset from camera position
%     ex = (des_x - Ltool*sin(angles(i)))/1000;
%     ez = (des_z - Ltool*cos(angles(i)))/1000;
%     pos = [ex, des_y, ez];
%     eulerangles = [0, angles(i), 0];
% 
%     % move to calculated position
%     MoveToPose(IP, pos, eulerangles, movetime) 
% 
%     ToggleVacuumChannel(0) % Remove vacuum in actuator after movement
%     pause(1)
%     close
% 
%     % When in position, inflate actuator to all desired input pressures
%     for ia = 1:length(pressures)
%         SetHIPressure(pressures(ia))
% 
%         % Save end effector positions
%         ee_positions((i*length(pressures) - length(pressures)) + ia, :) = pos;
%         ee_angles((i*length(pressures) - length(pressures)) + ia, :) = eulerangles;
% 
%         % stream data from LabJack 
%         [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);
%         AllData = [AllData; Data];
% 
%         % Capture Image of Actuator
%         pause(0.1) %pause is needed to prevent frames from repeating in .tif file. 
%         next_img = snapshot(cam1);
%         disp('Image Captured')
% 
%         if i == 1 && ia == 1 % if this is the first image, create .tif file and directory. else, add to file
%             % Write input pressure on the image
%             LabelString = strcat('Input Pressure =', num2str(pressures(ia), '%0.3f'), ' psi');
%             LabelPosition = [10 10];
%             LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
%             % prepare to save images in desired folder
%             Path = pwd;
%             ActuatorDirectory = strcat(Path, '\Test Data\', Actuator, '\');
%             imgDirectory = strcat(ActuatorDirectory, 'Images\');
%             % folderName = append(Actuator, '\');
%             [status, msg, id] = mkdir(imgDirectory);
% 
%             imString = "_NA_TestImgs";
%             imgFile = strcat(FileName, imString, '.tif');
%             VerticalImages = imgFile;
%             file_location = strcat(imgDirectory, imgFile); 
%             addpath(imgDirectory)
%             imwrite(LabeledImage, file_location);
%         else
%             LabelString = strcat('Input Pressure =', num2str(pressures(ia), '%0.3f'), ' psi');
%             LabelPosition = [10 10];
%             LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
% 
%             imwrite(LabeledImage, file_location, 'WriteMode','append');
%         end
%         pause(0.1)
%         VacuumDuration(1) % Draw vacuum in Actuator for specified time in seconds
%     end
%     % clear cam
%     VacuumDuration(3)
% end
% RemoveAir
% 
% % Return to home position
% position = [0.300, -0.075, .325]; % desired (X,Y,Z) position of end effector, in METERS
% eulerangles = [0, pi/4, 0]; % desired orientation of End Effector, ZYZ rotation order, in RADIANS
% movetime = 3; % Time in seconds that the arm will take to move to desired position
% 
% % move to desired position
% MoveToPose(IP, position, eulerangles, movetime)
% 
% % Save test data in .mat files 
% 
% [status, msg, id] = mkdir(append(ActuatorDirectory, 'MAT Files'));
% matFileLocation = strcat(ActuatorDirectory, 'MAT Files\');
% addpath(matFileLocation)
% 
% % Load pressure sensor Calibration function (saved previously)
% pressurestruct = load('Prosense30psi17Jun2025.mat');
% VoltageToPressureFit = pressurestruct.CalibrationCoefficients;
% 
% % save input and pressures in MAT file
% AllInputPressures = [];
% for k = 1:length(angles)
%     AllInputPressures = [AllInputPressures, pressures];
% end
% input_matFileName = strcat(FileName, '_inputPressures');
% 
% MeasuredPressures = polyval(VoltageToPressureFit, AllData);
% meas_matFileName = strcat(FileName, '_MeasuredPressures');
% 
% % save commanded and measured pressures
% save(strcat(matFileLocation, input_matFileName, '.mat'), 'AllInputPressures')
% save(strcat(matFileLocation, meas_matFileName, '.mat'), 'MeasuredPressures')
% 
% % save arm end effector pose in MAT file
% positionMatFile = strcat(FileName, '_ArmPositions');
% orientationMatFile = strcat(FileName, '_ArmOrientations');
% 
% save(strcat(matFileLocation, positionMatFile, '.mat'), 'ee_positions')
% save(strcat(matFileLocation, orientationMatFile, '.mat'), 'ee_angles')
% 
% figure()
% plot(MeasuredPressures)
% 
% %% re-do the above test in the horizontal plane (parallel to workbench surface)
% Actuator = 'TestActuator'; % String that identifies the actuator to be tested. 
% extra = '_Demo_horizontal';
% FileName = strcat(Actuator, extra);
% % A new folder with this name will be created under TestData
% 
% max_pressure = 30; % maximum pressure supplied to the actuator, in PSI
% pressures = linspace(0, max_pressure, 11);
% 
% % desired position of the end effector. This is an arbitrarily chosen point
% % that does not risk collision with the rest of the system. 
% % NOTE: depends on configuration of test setup. 
% des_x = 12.25*25.4; % mm
% des_y = 0; % mm
% des_z = 0.2550;  % meters
% 
% % for this sample test, we'll change the direction that the actuator is
% % pointing. 
% angles = [-45:45:45] * pi/180;
% step_time = 5; 
% 
% AllData = [];
% 
% % we use 1/4" diameter stickers attached to the actuator to measure its
% % position. 
% Marker_Diameter = 6.35;
% Ltool = 67.5 + Marker_Diameter/2 + 8; % distance from end effector point to first marker on actuator
% % 67.5 mm for length of actuator, 1/2 marker diameter to get to centroid of
% % first marker, and 8 mm to account for the UR5 thread protector. 
% 
% for o = 1:length(angles)
%     SetHIPressure(0)
%     % VacuumDuration(0.5)
%     ToggleVacuumChannel(1)
% 
%     %calculate EE position based on desired offset from camera position
%     ex = (des_x - Ltool*cos(angles(o)))/1000;
%     ey = (des_y - Ltool*sin(angles(o)))/1000; % + counter*amt;
%     pos = [ex, ey, des_z];
%     eulerangles = [angles(o), pi/2, 2*pi/4];
% 
%     % move to calculated position
%     MoveToPose(IP, pos, eulerangles, movetime)
%     ToggleVacuumChannel(0)
%     pause(1)
%     close
% 
%     for i = 1:length(pressures)
%         SetHIPressure(pressures(i))
%         ee_positions((o*length(pressures) - length(pressures)) + i, :) = pos;
%         ee_angles((o*length(pressures) - length(pressures)) + i, :) = eulerangles;
%         % FastSetHIPressure(pressures(i), ljerror, ljhandle, ljudObj)
% 
%         start = tic;
%         [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);
%         time = toc(start);
%         AllData = [AllData; Data];
% 
%         times = linspace(0, time, length(Data));
% 
%         pause(0.15) %pause is needed to prevent frames from repeating in .tif file. 
%         next_img = snapshot(cam2);
% 
%         disp('Image Captured')
% 
%         if o == 1 && i ==1 % if this is the first image, create file. else, add to file
%            LabelString = strcat('Input Pressure =', num2str(pressures(i), '%0.3f'), ' psi');
%             LabelPosition = [10 10];
%             LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
%             % prepare to save images in desired folder
%             Path = pwd;
%             ActuatorDirectory = strcat(Path, '\Test Data\', Actuator, '\');
%             imgDirectory = strcat(ActuatorDirectory, 'Images\');
%             folderName = append(Actuator, '\');
%             [status, msg, id] = mkdir(imgDirectory);
% 
%             imString = "_NA_TestImgs";
%             imgFile = strcat(FileName, imString, '.tif');
%             HorizontalImages = imgFile;
%             file_location = strcat(imgDirectory, imgFile); 
%             addpath(imgDirectory)
%             imwrite(LabeledImage, file_location);
%         else
% 
%             LabelString = strcat('Input Pressure =', num2str(pressures(i), '%0.3f'), ' psi');
%             LabelPosition = [10 10];
%             LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
% 
%             imwrite(LabeledImage, file_location, 'WriteMode','append');
%         % clear next_img
%         end
%         pause(0.05)
%         VacuumDuration(1)
%         pause(0.05)
% 
%     end
%     VacuumDuration(1)
%     % clear cam
% 
% end
% RemoveAir
% 
% % Return to home position
% position = [0.300, -0.075, .325]; % desired (X,Y,Z) position of end effector, in METERS
% eulerangles = [0, pi/4, 0]; % desired orientation of End Effector, ZYZ rotation order, in RADIANS
% movetime = 3; % Time in seconds that the arm will take to move to desired position
% 
% % move to desired position
% MoveToPose(IP, position, eulerangles, movetime)
% 
% % Save test data in .mat files 
% 
% [status, msg, id] = mkdir(append(ActuatorDirectory, 'MAT Files'));
% matFileLocation = strcat(ActuatorDirectory, 'MAT Files\');
% addpath(matFileLocation)
% 
% % Load pressure sensor Calibration function (saved previously)
% pressurestruct = load('Prosense30psi17Jun2025.mat');
% VoltageToPressureFit = pressurestruct.CalibrationCoefficients;
% 
% % save input and pressures in MAT file
% AllInputPressures = [];
% for k = 1:length(angles)
%     AllInputPressures = [AllInputPressures, pressures];
% end
% input_matFileName = strcat(FileName, '_inputPressures');
% 
% MeasuredPressures = polyval(VoltageToPressureFit, AllData);
% meas_matFileName = strcat(FileName, '_MeasuredPressures');
% 
% % save commanded and measured pressures
% save(strcat(matFileLocation, input_matFileName, '.mat'), 'AllInputPressures')
% save(strcat(matFileLocation, meas_matFileName, '.mat'), 'MeasuredPressures')
% 
% % save arm end effector pose in MAT file
% positionMatFile = strcat(FileName, '_ArmPositions');
% orientationMatFile = strcat(FileName, '_ArmOrientations');
% 
% save(strcat(matFileLocation, positionMatFile, '.mat'), 'ee_positions')
% save(strcat(matFileLocation, orientationMatFile, '.mat'), 'ee_angles')
% 
% figure()
% plot(MeasuredPressures)
% 
% %% Clear Workspace Again
% % This might seem counterintitive, but it can be useful to take images then
% % store them for later analysis. We'll clear the workspace to demonstrate 
% % loading and processing stored data Actuators may stretch or perform
% % differently over time, but the actuator may not strictly need to be
% % imaged every time it is used. 
% 
% close all, 
% 
% % keep cameras and actuator name. users will need to specify which
% % actuator's data they want to load, and which camera took the images. 
% % Normally, a user will provide this information as an input when 
% % loading existing data. In this case, we will just keep these
% % variables. 
% clearvars -except Actuator FileName cam1 FrontCam cam2 TopCam 
% 
% %% Load data from test, Fit splines to points
% Marker_Diameter = 6.35;  % 
% % act_len = 25.4 * 2.45;
% 
% Images = strcat(FileName, '_NA_TestImgs.tif');
% TestPositions = append(erase(Images, '_NA_TestImgs.tif'), '_ArmOrientations.mat');
% matStruct = load(TestPositions);
% H_angles = matStruct.ee_angles(:, 2);
% unique_angles = unique(H_angles);
% 
% PressureMatFile = strcat(FileName, '_inputPressures.mat');
% matStruct = load(PressureMatFile); 
% input_pressures = matStruct.AllInputPressures;

% find markers on every frame of .tif file
[ImgProcessed, positionCellArray, pixels_per_mm] = ProcessTIFImage(Images, Marker_Diameter, Actuator, 'Front', 300);

% Separate Datum from other points
[AllDatumPTs, SortedPoints_cell] = DatumDetector(Images, ImgProcessed, positionCellArray, pixels_per_mm, 2);

% convert measured points to real coordinates
all_meas_pts = cell(length(SortedPoints_cell), 1);
for i = 1:length(SortedPoints_cell)
    % gather real point data

    all_meas_pts{i} = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);
end

% rotate measured points. Because the images were taken while the actuator
% was moving, the points wont overlap. Rotate the points the amount that the 
% end effector is turned to force them to overlap. 

for i = 1:length(SortedPoints_cell)
    % gather real point data
    act_pts = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);
    
    fix((i-1)/length(unique(input_pressures)));

    angle = H_angles(i) 

    [xr, yr] = Rotate(act_pts(:, 1), act_pts(:, 2), -angle); 

    figure(55)
    scatter(xr, yr); hold on
    axis equal

    column = mod(i, length(unique(input_pressures)));

    if column == 0
        column = max(length(unique(input_pressures)));
    end

    page = fix((i-1)/length(unique(input_pressures))) + 1;
    all_X(:, column, page) = xr;
    all_Y(:, column, page) = yr;

    if i == length(SortedPoints_cell)
        mean_x = mean(all_X, 3);
        mean_y = mean(all_Y, 3);
        sz_mean_x = size(mean_x);

        for aa = 1:sz_mean_x(2)
            all_est_pts{aa} = [mean_x(:, aa), mean_y(:, aa)];
        end
    
    end
    % store experimental data for bend angle calculations
    all_meas_pts_exp{i} = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);
end

figure()
for o = 1:11
    pts = all_est_pts{o};
    scatter( pts(:, 1), pts(:, 2) )
    hold on
end
axis equal

%% Fit splines to sorted points
% this provides a continuous representation of each inflation state
num_segments = length(SortedPoints_cell{1})-1;
allCurves = NaturalCubicSplineFit(all_est_pts, num_segments, FileName);

figure()
for o = 1:length(allCurves)
    pts = all_est_pts{o};
    scatter(pts(:, 1), pts(:, 2))
    hold on 
end 
axis equal

figure()
for o = 1:length(allCurves)
    fnplt(allCurves{o})
    hold on 
end 
axis equal

% load input pressures from test data
PressureMatFile = strcat(FileName, '_inputPressures.mat');
matStruct = load(PressureMatFile); 
input_pressures = matStruct.AllInputPressures;
P_max = max(input_pressures);

%% Find M and H matrices for the actuator under test
% these matrices can be re-used to generate spline representations of the actuator

[M, H] = FindActuatorMatrices(allCurves, unique(input_pressures), 4, 4);

%% Generate Sag Surface
% this 3D surface approximates the change in actuator deformation due to
% gravity. 
bend_angles_vert = FindBendAngles(VerticalImages, allCurves_Vert, num_segments, input_pressures_vert, 2, true)
bend_angles_horiz = FindBendAngles(HorizontalImages, allCurves_Horiz_exp, num_segments, input_pressures_horiz, 1, true)
[SagSurface_calib, max_sag, min_sag] = GenerateSagSurface(Actuator, true) % Requires BendAngles.mat to exist for both horizontal and vertical tests (created and saved by FindBendAngles)


ee_angles = [0:22.5:180] * pi/180
x_range = linspace(min(input_pressures), max(input_pressures), 500);
y_range = linspace(min(ee_angles), max(ee_angles), 500);

[X, Y] = meshgrid(x_range, y_range);
Z2 = SagSurface_calib(X, Y);


% Save Sag Surface in .mat file
matlocation = append(pwd, '\Test Data\' , Actuator, '\MAT Files\', Actuator, '_SagSurface.mat');
save(matlocation, 'SagSurface_calib');

%% estimate bend angle to input pressure based on RT model
% we will use the distal tangent bend angle to approach a load cell to
% measure the force applied by the actuator. 
disp('ESTIMATE DISTAL TANGENT BEND ANGLE BASED ON POLAR SPIRAL MODELS...')
% estimate points along actuator for each inflation state
allCurves_points = cell(length(input_pressures), 1); 
dimensionless = linspace(0, 1, 100);
for a = 1:length(allCurves_points)
    [ray_length_coeff, theta_coeff] = FindPolarCoefficients(input_pressures(a), M, H);
    rays = polyval(ray_length_coeff, dimensionless);
    angles = polyval(theta_coeff, dimensionless);

    x_predicted = rays.*cos(angles);
    y_predicted = rays.*sin(angles);
    x_predicted = x_predicted - x_predicted(1);
    y_predicted = y_predicted - y_predicted(1);
    
    allCurves_points{a} = [x_predicted', y_predicted'];
end

num_segments_model = length(dimensionless) - 1;
allCurves_model =  NaturalCubicSplineFit(allCurves_points, num_segments_model, FileName);
bend_angles_model = FindBendAngles(Images, allCurves_model, num_segments_model, input_pressures, 2, false);

figure(), 
for o = 1:length(allCurves_model)
    fnplt(allCurves_model{o})
    hold on
end
axis equal

%% move arm to a a few initial bend positions to approach load cell

PressureToBend = polyfit(input_pressures(1:11), bend_angles_model(1:11), 2);
BendToPressure = polyfit(bend_angles_model(1:11), input_pressures(1:11), 2);

bend_angles = (10:10:40)*pi/180; % inital bend angles to approach load cell
bend_pressures = polyval(BendToPressure, bend_angles);

%% Load Calibration Functions for load cells and pressure sensors

%input pressures
PressureMatFile = strcat(FileName, '_inputPressures.mat');
PressurematStruct = load(PressureMatFile); 
pressures = PressurematStruct.AllInputPressures;

% Load Cell Calibration function
LoadCellstruct = load('RiceLake5kg16Jun2025.mat');
VoltageToLoadFit = LoadCellstruct.CalibrationCoefficients;

Psensestruct = load('Prosense30psi17Jun2025.mat');
VoltageToPresFit = Psensestruct.CalibrationCoefficients;

%% Prepare system to run a test using the newly generated actuator models

%% Prepare camera to take images
cam = webcam(FrontCam);
cam.Exposure = -5;

%% Prepare to read data using the LabJack
[ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack();
channels = [4, 10; 
            1, 10]; % stream data on AIO channels 4 and 1. (Pressure sensor and load cell)
step_time = 2;
scanRate = 1000;

%% Execute a test: poke a load cell, measure data, plot it. 
% manually provide load cell position. Measured with respect to center of
% UR5 base.
cell_x = 450;
cell_y = 2.5;
cell_z = 430;

max_pressure = max(input_pressures);

Ltool = 67.5 + Marker_Diameter/2+8; % distance from end effector point to first marker on actuator
Wtool = 8.5 - Marker_Diameter/2;
dist_act = sqrt(Ltool^2+ Wtool^2);
mount_angle = atan2(Wtool, Ltool);

RemoveAir

% set up empty arrays to store data
pressureSensVoltages = cell(length(bend_pressures), 1);
loadCellVoltages = cell(length(bend_pressures), 1);

pressureSensVoltages2 = cell(length(bend_pressures), 1);
loadCellVoltages2 = cell(length(bend_pressures), 1);

steps = 30;
disp('APPROACH LOAD CELL...')

desired_heading = pi/2;
IP = '192.168.1.10';

for k = 1:length(bend_pressures)
    
    disp(append('MOVING TO INTITIAL POSITION ', num2str(k), 'OUT OF ', num2str(length(bend_pressures) ) ) )

    AllData = [];
    tic

    in_press = linspace(bend_pressures(k), max_pressure, steps);
    % in_press = bend_pressures(k); % if we want to analyze initial
    % position only

    % ORIENTATION
    % use sag surface to converge to some end effector angle that supports
    % desired heading.
    theta = polyval(PressureToBend, bend_pressures(k));
    ee_angle = desired_heading - theta;

    % alpha = SagSurface(bend_pressures(k), ee_angle);
    actual_bend = theta + ee_angle; % + alpha;
    delta_actual = desired_heading - actual_bend;
    loops = 0;
    while delta_actual < -5*pi/180
        loops = loops+1;
        ee_angle = ee_angle - 0.5*pi/180;
        % alpha = SagSurface(bend_pressures(k), ee_angle);
        actual_bend = theta + ee_angle; % + alpha;
        delta_actual = desired_heading - actual_bend;
    end
    ee_deg = ee_angle*180/pi;

    % POSITION
    [ray_length_coeff, theta_coeff] = FindPolarCoefficients(bend_pressures(k), M, H);
    rays = polyval(ray_length_coeff, dimensionless);
    angles = polyval(theta_coeff, dimensionless);

    X = rays.*cos(angles);
    Y = rays.*sin(angles);

    [Xr, Yr] = Rotate(X, Y, -(theta)+pi/2);
    figure(25); scatter(Xr, Yr, '.'); axis equal; title(bend_pressures(k))

    % in MILLIMETERS
    x_base = (cell_x + Xr(end)); % invert x axis to convert from matlab x axis to real X
    z_base = (cell_z - Yr(end)); % switch from matlab y coords to IRL z coords
    ee_x = (x_base - dist_act * cos(pi/2 - (mount_angle+ee_angle)))/1000;
    ee_z = (z_base - dist_act * sin(pi/2 - (mount_angle+ee_angle)))/1000;

    % Move Arm to positions
    pos = [ee_x, cell_y/1000, ee_z];
    eulerangles = [0, ee_angle, 0];
    move_time = 3; % in seconds

    above_pos = pos + [0, 0, 0.01];

    [result, state] = MoveToPose(IP, above_pos, eulerangles, move_time);
    SetHIPressure(bend_pressures(k))
    pause(2)
    [result, state] = MoveToPose(IP, pos, eulerangles, move_time);
    pause(2)
    close
    close

    % after arriving, stream data
    % measure at current pressure
    [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);
    pause(0.06)
    
    % distill a specific point + error bars 
    loadCell = Data(:, 2);
    Psense = Data(:, 1);
    
    % for 95% CI, Z = 1.96
    Z = 1.960;
    CI_load = Z * std(loadCell)/sqrt(length(loadCell));
    CI_pres = Z * std(Psense)/sqrt(length(Psense));
    
    LoadCellData = zeros(steps+1, 2);
    PsenseData = zeros(steps+1, 2);

    LoadCellData(1, :) = [mean(loadCell), CI_load];
    PsenseData(1, :) = [mean(Psense), CI_pres];
    
    AllData = [AllData; Data];

    % do all other pressures and measure
    for ka = 1:length(in_press)
        SetHIPressure( in_press(ka) )
        [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);
        pause(0.06)
        image2 = snapshot(cam);
        LabelPosition = [10 10];
        LabelString = strcat('Input Pressure =', num2str(in_press(ka), '%0.3f'), ' psi');

        annotated_image = insertText(image2, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
        if k == 1 && ka == 1 % if this is the first image, create file. else, add to file
                LabelString = strcat('Input Pressure =', num2str(in_press(ka), '%0.3f'), ' psi');
                LabelPosition = [10 10];
                LabeledImage = insertText(image2, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
                % prepare to save images in desired folder
                Path = pwd;
                ActuatorDirectory = strcat(Path, '\Test Data\', Actuator, '\');
                imgDirectory = strcat(ActuatorDirectory, 'Images\');
                folderName = append(Actuator, '\');
                [status, msg, id] = mkdir(imgDirectory);

                imString = "_LoadCellTest";
                imgFile = strcat(Actuator, imString, '.tif');
                file_location = strcat(imgDirectory, imgFile);
                addpath(imgDirectory)
                imwrite(LabeledImage, file_location);
            else
                image2 = snapshot(cam);
                LabelString = strcat('Input Pressure =', num2str(in_press(ka), '%0.3f'), ' psi');
                LabelPosition = [10 10];
                LabeledImage = insertText(image2, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");

                imwrite(LabeledImage, file_location, 'WriteMode','append');
                % clear next_img
            end
        % distill a specific point + error bars 
        loadCell = Data(:, 2);
        Psense = Data(:, 1);
        
        % for 95% CI, Z = 1.96
        Z = 1.960;
        CI_load = Z * std(loadCell)/sqrt(length(loadCell));
        CI_pres = Z * std(Psense)/sqrt(length(Psense));
     
        LoadCellData(ka+1, :) = [mean(loadCell), CI_load];
        PsenseData(ka+1, :) = [mean(Psense), CI_pres];
      
        AllData = [AllData; Data];
    end

    RemoveAir

    pressureSensVoltages{k} = AllData(:, 1);
    loadCellVoltages{k} = AllData(:, 2);

    pressureSensVoltages2{k} = PsenseData;
    loadCellVoltages2{k} = LoadCellData;

    time = toc;
    approx_time = linspace(0, time, length(AllData));
    times{k} = approx_time;

    % for long actuators, reset to vertical to get actuator back on top of
    % load cell
    [result, state] = MoveToPose(IP, above_pos+[-0.050, 0, 0.01], [0, 0, 0], move_time);
    close
    pause(1)

end
RemoveAir
% move arm straight back from last position
[result, state] = MoveToPose(IP, above_pos-[0.075, 0, 0], eulerangles, move_time);

pause(2)
% Safe(r) intermediate position to return to
[result, state] = MoveToPose(IP, [0.250, 0.005, 0.300], [0, pi/4, 0], move_time);

close
close


