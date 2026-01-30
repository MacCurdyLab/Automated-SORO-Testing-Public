%% LoadCell Test
clear; clc; %close all
% relies on M and H matrices having been found for actuator

% ======= Manual Inputs =======

% String that names the actuator to test
Actuator = "Hainsworth_95A_1";

% maximum pressure for the actuator to test in psi
max_pressure = 30;

Marker_Diameter = 6.35;

% % List of initial bend angles for the actuator to approach the load cell.
bend_angles = (15:37.5:90)*pi/180;
% bend_angles = (10:10:40)*pi/180;

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
vac_time = step_time * 1; 



cam = webcam(1);

% ======= Manual Inputs =======
RemoveAir
VacuumDuration(5)

%% Load input pressures
disp('LOAD ACTUATOR TEST DATA...')
HorizontalImages = append(Actuator, '_multipose_horizontal_vac_NA_TestImgs.tif');
PressureMatFile = strcat(Actuator, '_multipose_horizontal_vac_inputPressures.mat');
matStruct = load(PressureMatFile); 
input_pressures_horiz = matStruct.AllInputPressures;
input_pressures = unique(input_pressures_horiz);

%% Prepare Arm
% move arm to standard position
IP = '192.168.1.10'; 
position = [0.300, -0.075, .325];
eulerangles = [0, pi/4, 0];
movetime = 3;
MoveToPose(IP, position, eulerangles, movetime)
close

%% Load M and H matrices
disp('LOAD ACTUATOR POLAR SPIRAL MODELS...')
MHstruct = load(append(Actuator, '_MH_matrices.mat'));
M = MHstruct.M;
H = MHstruct.H;

sagstruct = load(append(Actuator, '_SagSurface.mat'));
SagSurface = sagstruct.SagSurface_calib;

%% estimate bend angle to input pressure based on MH model
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

disp('PREPARE TO APPROACH LOAD CELL...')
% fit spline to estimated points
num_segments_model = length(dimensionless) - 1;
allCurves_model =  NaturalCubicSplineFit(allCurves_points, num_segments_model, strcat(Actuator, '_multipose_horizontal_vac') );

% estimate bend angles based on input pressure
bend_angles_model = FindBendAngles(HorizontalImages, allCurves_model, num_segments_model, input_pressures_horiz, 1, false);

figure()
scatter(input_pressures, bend_angles_model)
xlabel('Pressure (psi)')
ylabel('Bend Angle, (radians)')

%% move arm to a a few initial bend positions to approach load cell

PressureToBend = polyfit(input_pressures, bend_angles_model, 2);
BendToPressure = polyfit(bend_angles_model, input_pressures, 2);

bend_pressures = polyval(BendToPressure, bend_angles);

% LOAD CELL POSITION = X = 508 mm, Y = 10 mm, Z = 374.65 mm
cell_x = 18.7*25.4-4;
cell_z = 14.6*25.4;
cell_y = 5;

desired_heading = pi/2;

Ltool = 67.5 + Marker_Diameter/2+8; 
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

times = cell(length(bend_pressures), 1);

steps = 5;
disp('APPROACH LOAD CELL...')
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

    alpha = SagSurface(bend_pressures(k), ee_angle);
    actual_bend = theta + ee_angle + alpha;
    delta_actual = desired_heading - actual_bend;
    loops = 0;
    while delta_actual < -5*pi/180
        loops = loops+1;
        ee_angle = ee_angle - 0.5*pi/180;
        alpha = SagSurface(bend_pressures(k), ee_angle);
        actual_bend = theta + ee_angle + alpha;
        delta_actual = desired_heading - actual_bend;
    end
    ee_deg = ee_angle*180/pi;

    % POSITION
    [ray_length_coeff, theta_coeff] = FindPolarCoefficients(bend_pressures(k), M, H);
    rays = polyval(ray_length_coeff, dimensionless);
    angles = polyval(theta_coeff, dimensionless);

    X = rays.*cos(angles);
    Y = rays.*sin(angles);

    [Xr, Yr] = Rotate(X, Y, -(theta)+pi/4);
    figure(25); scatter(Xr, Yr, '.'); axis equal; title(bend_pressures(k))

    % in MILLIMETERS
    x_base = (cell_x + Xr(end)); % invert x axis to convert from matlab x axis to real X
    z_base = (cell_z - Yr(end)); % switch from matlab y coords to IRL z coords
    ee_x = (x_base - dist_act * cos(pi/2 - (mount_angle+ee_angle)))/1000;
    ee_z = (z_base - dist_act * sin(pi/2 - (mount_angle+ee_angle)))/1000;
    ee_y = cell_y/1000;

    % Move Arm to positions
    pos = [ee_x, ee_y, ee_z];
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
    % image = snapshot(cam);
    % LabelPosition = [10 10];
    % LabelString = strcat('Input Pressure =', num2str(bend_pressures(k), '%0.3f'), ' psi');
    % annotated_image = insertText(image, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
    % [imgName, file_location] = AddImgtoTif(annotated_image, append('\Test Data\', Actuator, '\Images\', Actuator, '_LoadCellTest') );
    
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

%% Bring in relevant Calibration Functions

% Load Cell Calibration function
LoadCellstruct = load('RiceLake5kg16Jun2025.mat');
VoltageToLoadFit = LoadCellstruct.CalibrationCoefficients;

% Pressure Sensor Calibration Function
Psensestruct = load('Prosense30psi17Jun2025.mat');
VoltageToPresFit = Psensestruct.CalibrationCoefficients;

figure()
for a = 1:length(loadCellVoltages)
    % convert to forces
    Force_N = (polyval(VoltageToLoadFit, loadCellVoltages{a}) - 6.4) * 9.81/1000; % convert to newtons
    measPressure = (polyval(VoltageToPresFit, pressureSensVoltages{a}));
    % Weight = loadCellVoltages{a};
    % Pressure = pressureSensVoltages{a};

    scatter(measPressure, Force_N, '.')
    xlabel('Pressure (psi)')
    ylabel('Force (N)')
    grid on
    title('Input Pressure to Bend Angle, RAW DATA')
    hold on
    legend('15', '30', '45', '60', '75', '90')
end

figure()
for b = 1:length(loadCellVoltages)
    % convert to forces
    Loads_filtered = loadCellVoltages2{b};
    pres_filtered = pressureSensVoltages2{b};
    
    % load_means = (VoltageToLoadFit(1).* Loads_filtered(:, 1) + VoltageToLoadFit(2) - 6.4) * 9.81/1000; % convert to newtons
    % load_CIs = (VoltageToLoadFit(1).* Loads_filtered(:, 2) + VoltageToLoadFit(2)) * 9.81/1000; % convert to newtons
    % 
    % pres_means = (VoltageToPresFit(1).* pres_filtered(:, 1) + VoltageToPresFit(2) ); % convert to newtons
    % pres_CIs = (VoltageToPresFit(1).* pres_filtered(:, 2) + VoltageToPresFit(2) ); % convert to newtons

    load_means = (polyval(VoltageToLoadFit, Loads_filtered(:, 1)) - 6.4) * 9.81/1000; % convert to newtons
    pres_means = (polyval(VoltageToPresFit, pres_filtered(:, 1)));

    load_CIs = (polyval(VoltageToLoadFit, Loads_filtered(:, 1)+Loads_filtered(:, 2)) - 6.4) * 9.81/1000 - load_means;
    pres_CIs = (polyval(VoltageToPresFit, pres_filtered(:, 1)+pres_filtered(:, 2))) - pres_means;

    errorbar(pres_means, load_means, load_CIs, load_CIs, pres_CIs, pres_CIs)
    hold on

    % scatter(pres_means, load_means)
    xlabel('Pressure (psi)')
    ylabel('Force (N)')
    title('Input Pressure to Bend Angle')
    hold on
    legend('15', '30', '45', '60', '75', '90')
end

% Save Test Data in a mat file
matlocation = append(pwd, '\Test Data\' , Actuator, '\MAT Files\', Actuator);
ext_1 = '_Raw_LC_Test_Data.mat';
save(append(matlocation, ext_1), 'loadCellVoltages', 'Force_N', 'pressureSensVoltages', 'measPressure')

ext_2 = '_EB_LC_Test_Data.mat'; % EB = error Bar
save(append(matlocation, ext_2), 'loadCellVoltages2', 'pressureSensVoltages2')

% figure()
% for a = 1:length(loadCellVoltages)
%     % convert to forces
%     Weight = VoltageToLoadFit(1).* loadCellVoltages{a} + VoltageToLoadFit(2) - 3;
%     scatter(times{a}, Weight, '.')
%     xlabel('Time (s)')
%     ylabel('Force (g)')
%     hold on
%     legend('0.05', '0.1', '0.15', '0.2', '0.25')
%     % legend('0 degree', '15 degree', '30 degree', '45 degree', '60 degree', '75 degree', '90 degree')
% 
% end
% 
% figure()
% for b = 1:length(pressureSensVoltages)
%     % convert to forces
%     Pressure = VoltageToPresFit(1).* pressureSensVoltages{b} + VoltageToPresFit(2);
%     scatter(times{b}, Pressure, '.')
%     xlabel('Time (s)')
%     ylabel('Pressure (psi)')
%     hold on
%     % legend('0 degree', '15 degree', '30 degree', '45 degree', '60 degree', '75 degree', '90 degree')
%     legend('0.05', '0.1', '0.15', '0.2', '0.25')
% end
% 
% % save test data in .mat files
% matFileLocation = append(pwd, '\Test Data\', Actuator, '\MAT Files\', Actuator, '_Multipose_Load_Test.mat')
% save(matFileLocation, 'loadCellVoltages', 'Weight', 'pressureSensVoltages', 'Pressure')
