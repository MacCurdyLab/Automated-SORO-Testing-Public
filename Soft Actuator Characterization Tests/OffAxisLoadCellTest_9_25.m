%% OFF Axis LoadCell Test
clear; clc; close all
% relies on R and T matrices having been found for actuator

% ======= Manual Inputs =======

% String that names the actuator to test
Actuator = "Gunawardane_T4_85A_4";

% maximum pressure for the actuator to test in psi
max_pressure = 20;

% % List of initial bend angles for the actuator to approach the load cell.
bend_angles = (15:15:90)*pi/180;
% bend_angles = (10:10:40)*pi/180;

% diameter of fiducial stickers in mm
Marker_Diameter = 6.35; 

% Wan actuator has smaller markers than others 
if Actuator == "Wan_85A" 
    Marker_Diameter = Marker_Diameter/2 ;
end

% Hansell actuator has smaller markers
if Actuator == "Hansell_Endo_30A" 
    Marker_Diameter = 5;
end

% time in seconds that the actuator will be pressurized. 
step_time = 1; 
% time in seconds that a vacuum will be pulled in the actuator.
vac_time = step_time * 3; 



cam = webcam(1);

% ======= Manual Inputs =======

RemoveAir

%% Load input pressures
disp('LOAD ACTUATOR TEST DATA...')
HorizontalImages = append(Actuator, '_multipose_horizontal_vac_NA_TestImgs.tif');
PressureMatFile = strcat(Actuator, '_multipose_horizontal_vac_inputPressures.mat');
matStruct = load(PressureMatFile); 
input_pressures_horiz = matStruct.AllInputPressures;
input_pressures = unique(input_pressures_horiz);

%% Bring in relevant Calibration Functions

% Load Cell Calibration function
LoadCellstruct = load('RiceLake5kg16Jun2025.mat');
VoltageToLoadFit = LoadCellstruct.CalibrationCoefficients;

% Pressure Sensor Calibration Function
Psensestruct = load('Prosense30psi17Jun2025.mat');
VoltageToPresFit = Psensestruct.CalibrationCoefficients;

%% Prepare Arm
% move arm to standard position
IP = '192.168.1.10'; 
position = [0.300, -0.075, .375];
eulerangles = [0, pi/2, 2*pi/4];
movetime = 3;
MoveToPose(IP, position, eulerangles, movetime)
close

%% Load R and T matrices
disp('LOAD ACTUATOR POLAR SPIRAL MODELS...')
RTstruct = load(append(Actuator, '_RT_matrices.mat'));
R = RTstruct.R;
T = RTstruct.T;

sagstruct = load(append(Actuator, '_SagSurface.mat'));
SagSurface = sagstruct.SagSurface_calib;

%% estimate bend angle to input pressure based on RT model
% estimate points along actuator for each inflation state
disp('ESTIMATE DISTAL TANGENT BEND ANGLE BASED ON POLAR SPIRAL MODELS...')
allCurves_points = cell(length(input_pressures), 1); 
dimensionless = linspace(0, 1, 100);
for a = 1:length(allCurves_points)
    [ray_length_coeff, theta_coeff] = FindPolarCoefficients(input_pressures(a), R, T);
    rays = polyval(ray_length_coeff, dimensionless);
    angles = polyval(theta_coeff, dimensionless);

    x_predicted = rays.*cos(angles);
    y_predicted = rays.*sin(angles);
    x_predicted = x_predicted - x_predicted(1);
    y_predicted = y_predicted - y_predicted(1);
    
    allCurves_points{a} = [x_predicted', y_predicted'];
end

RemoveAir

disp('PREPARE TO APPROACH LOAD CELL...')
% move arm straight back from last position
IP = '192.168.1.10'; 
position = [0.300, -0.075, .375];
eulerangles = [0, pi/2, 2*pi/4];
movetime = 3;
MoveToPose(IP, position, eulerangles, movetime)
close

% fit spline to estimated points
num_segments_model = length(dimensionless) - 1;
allCurves_model =  NaturalCubicSplineFit(allCurves_points, num_segments_model, strcat(Actuator, '_multipose_horizontal_vac') );

% estimate bend angles based on input pressure
bend_angles_model = FindBendAngles(HorizontalImages, allCurves_model, num_segments_model, input_pressures_horiz, 1, false);

figure()
scatter(input_pressures, bend_angles_model)
xlabel('Pressure (psi)')
ylabel('Bend Angle, (radians)')

%% Move arm to several bend angles, hovering above load cell, then step downwards. 

disp('PREPARE TO APPROACH LOAD CELL...')
PressureToBend = polyfit(input_pressures, bend_angles_model, 2);
BendToPressure = polyfit(bend_angles_model, input_pressures, 2);

bend_pressures = polyval(BendToPressure, bend_angles);

% LOAD CELL POSITION 
cell_x = 18.8*25.4;
cell_z = 14.5*25.4;
cell_y = -2.5;

desired_heading = pi/2;

Ltool = 67.5 + Marker_Diameter/2+ 10; 
Wtool = 8.5 - Marker_Diameter/2;
dist_act = sqrt(Ltool^2+ Wtool^2);
mount_angle = atan2(Wtool, Ltool);
RemoveAir

% prepare LJ
[ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack();
channels = [4, 10; 1, 10];
scanRate = 1000;

% set up empty arrays to store data
pressureSensVoltages = cell(length(bend_pressures), 1);
loadCellVoltages = cell(length(bend_pressures), 1);

pressureSensVoltages2 = cell(length(bend_pressures), 1);
loadCellVoltages2 = cell(length(bend_pressures), 1);

delta_pos = cell(length(bend_pressures), 1);

times = cell(length(bend_pressures), 1);

steps = 25;
step_size = 0.002;
OVERLOAD = false;
% for each bend angle, hover above load cell and step downwards
disp('APPROACH LOAD CELL...')
for k = 1:length(bend_pressures)
    OVERLOAD = false;
    disp('VACUUM RESET ACTUATOR BENDING')
    VacuumDuration(20)
    % if k == length(bend_pressures)
    %     cell_x = cell_x + 10
    % end
    if OVERLOAD == false
        AllData = [];
        tic
        
        [ray_length_coeff, theta_coeff] = FindPolarCoefficients(bend_pressures(k), R, T);
        rays = polyval(ray_length_coeff, dimensionless);
        angles = polyval(theta_coeff, dimensionless);

        X = rays.*cos(angles);
        Y = rays.*sin(angles);

        [Xr, Yr] = Rotate(X, Y, -pi/4);
        figure(25); scatter(Xr, Yr, '.'); axis equal; title(bend_pressures(k))

        x_base = (cell_x - Yr(end)); % invert x axis to convert from matlab x axis to real X
        y_base = (cell_y + Xr(end)); % switch from matlab y coords to IRL z coords
        ee_x = (x_base - Ltool)/1000+0.00;
        ee_y = (y_base - Wtool)/1000-0.00;

        % Move Arm to positions
        pos = [ee_x, ee_y, (cell_z+7.5)/1000];
        eulerangles = [0, pi/2, 2*pi/4];
        move_time = 3; % in seconds

        above_pos = pos + [0, 0, 0.005];
        [result, state] = MoveToPose(IP, above_pos, eulerangles, move_time);
        close 
    
        SetHIPressure(bend_pressures(k))

        change_pos = zeros(length(steps), 1);
        LoadCellData = zeros(steps, 2);
        PsenseData = zeros(steps, 2);
        
        for ka = 1:steps
            [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);

            pause(0.06)
            image = snapshot(cam);
            if k == 1 && ka == 1 % if this is the first image, create file. else, add to file
                LabelString = strcat('Input Pressure =', num2str(bend_pressures(k), '%0.3f'), ' psi');
                LabelPosition = [10 10];
                LabeledImage = insertText(image, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
                % prepare to save images in desired folder
                Path = pwd;
                ActuatorDirectory = strcat(Path, '\Test Data\', Actuator, '\');
                imgDirectory = strcat(ActuatorDirectory, 'Images\');
                folderName = append(Actuator, '\');
                [status, msg, id] = mkdir(imgDirectory);

                imString = "_OffAxisLoads";
                imgFile = strcat(Actuator, imString, '.tif');
                file_location = strcat(imgDirectory, imgFile);
                addpath(imgDirectory)
                imwrite(LabeledImage, file_location);
            else

                LabelString = strcat('Input Pressure =', num2str(bend_pressures(k), '%0.3f'), ' psi');
                LabelPosition = [10 10];
                LabeledImage = insertText(image, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");

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

            LoadCellData(ka, :) = [mean(loadCell), CI_load];
            PsenseData(ka, :) = [mean(Psense), CI_pres];

            

            load_c = polyval(VoltageToLoadFit, Data);
            Load_meas = max(load_c(:, 2))
            if max(load_c(:, 2)) > 1000
                [result, state] = MoveToPose(IP, above_pos+[0, 0, 0.1], eulerangles, move_time);
                close
                disp('OVERLOAD  (1 kg)')
                OVERLOAD = true;
                break
            elseif max(load_c(:, 2)) < 0.75 * mean(polyval(VoltageToLoadFit, AllData))
                disp('ACTUATOR SLIPPED')
                [result, state] = MoveToPose(IP, above_pos+[0, 0, 0.1], eulerangles, move_time);
                Data = [];
                OVERLOAD = true;
                break
            else
                [result, state] = MoveToPose(IP, above_pos-[0, 0, ka*step_size], eulerangles, move_time);
                close 
            end

            AllData = [AllData; Data];

            change_pos(ka) = ka*step_size;

        end

        
    end

    RemoveAir
    VacuumDuration(10)

    pressureSensVoltages{k} = AllData(:, 1);
    loadCellVoltages{k} = AllData(:, 2);

    pressureSensVoltages2{k} = PsenseData;
    loadCellVoltages2{k} = LoadCellData;
    
    delta_pos{k} = change_pos;

    pause(1)
    time = toc;
    approx_time = linspace(0, time, length(AllData));
    times{k} = approx_time;



end

RemoveAir

% move to home position
IP = '192.168.1.10'; 
position = [0.300, -0.075, .375];
eulerangles = [0, pi/2, 0];
movetime = 3;
MoveToPose(IP, position, eulerangles, movetime)
close


%%%%
figure()
for a = 1:length(loadCellVoltages)
    % convert to forces
    change_in_pos = delta_pos{a}*1000;
    raw_data = loadCellVoltages2{a};

    Loads_filtered = loadCellVoltages2{a};
    pres_filtered = pressureSensVoltages2{a};

    force_data = raw_data(1:length(change_in_pos), 1);
    Force_N = (polyval(VoltageToLoadFit, force_data) - 6.4) * 9.81/1000; % convert to newtons
    measPressure = (polyval(VoltageToPresFit, pressureSensVoltages{a}));
    
    % Weight = loadCellVoltages{a};
    % Pressure = pressureSensVoltages{a};

    plot(change_in_pos, Force_N, '--o')
    xlabel('Change in Position (mm)')
    ylabel('Force (N)')
    grid on
    title('Off Axis Force to Deformation')
    hold on
    legend('15', '30', '45', '60', '75', '90')
end

%% Save Test Data in a mat file
matlocation = append(pwd, '\Test Data\' , Actuator, '\MAT Files\', Actuator);
ext_1 = '_Raw_OffAxis_LC_Test_Data.mat';
save(append(matlocation, ext_1), 'loadCellVoltages', 'Force_N', 'pressureSensVoltages', 'measPressure')

ext_2 = '_EB_OffAxis_LC_Test_Data.mat'; % EB = error Bar
save(append(matlocation, ext_2), 'loadCellVoltages2', 'pressureSensVoltages2', 'delta_pos')

