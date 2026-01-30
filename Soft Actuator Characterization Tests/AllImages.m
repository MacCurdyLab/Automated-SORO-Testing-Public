%% AllImages
% 
% Date: 11/11/2025
% Inputs:
%   Actuator - string, 'char' - describes the actuator to be tested. A new
%   folder will be made under Test Data with the same name as Actuator.
%   this folder will contain images and data related to the actuator under
%   test. 
%   max_pressure - float, 'double' - describes the maximim pressure in psi
%   that the actuator will be exposed to
%   camOrder - matrix, doubles - 1x2 matrix that contains
%   [FrontCameraIndex, TopCameraIndex] (call webcamlist to see all
%   available cameras, run CameraIdentification.m to see which is frontcam
%   and which is top cam). 
%   step_time - float, 'double' - describes the time in seconds that the
%   actuator will be pressurized for a given inflation state
%   vac_time - float, 'double' - describes the time in seconds that a
%   vacuum will be drawn inside the actuator between inflation states. 
%   
%
% Output:
%   Directory - String, 'char'. Points to the directory where images are
%   saved

%   VerticalImages - string, 'char', string that describes file name of the
%   vertical plane images 

%   HorizontalImages- string, 'char', string that describes file name of the
%   horizontal plane images 
% 
% Objective: Function to take photos of an actuator in both vertical and horizontal orientations 

function [Directory, VerticalImages, HorizontalImages] = AllImages(Actuator, max_pressure, camOrder, step_time, vac_time)

wedgeSize=22.5;
num_steps = 11;

[ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack();
channels = [4, 10];
scanRate = 1000;
AllData = [];

% iterate through pressures, take picture for each, add tif file.
FrontCam = camOrder(1);
cam1 = webcam(FrontCam); % set up camera and take photo
cam1.Exposure = -4; % exposure value may need to change depending on lighting conditions

TopCam = camOrder(2);
cam2 = webcam(TopCam);
cam2.Exposure = -8; % exposure value may need to change depending on lighting conditions

%% First Do Vertical Images
extra1 = '_multipose_vac';

if vac_time == 0
    extra1 = '_multipose_novac';
end

FileName = strcat(Actuator, extra1);

% move arm to standard position
IP = '192.168.1.10'; 
position = [0.300, -0.075, .325];
eulerangles = [0, pi/4, 0];
movetime = 3;
close

angles = [0:wedgeSize:180] * pi/180;
pressures = linspace(0, max_pressure, num_steps);
% pressures = linspace(0, max_pressure, 11)

num_images = length(pressures);

Ltool = 70.675+8; 

des_x = 12.5*25.4;
des_z = 11.5*25.4;

InputPressures = zeros((num_images*length(angles)), 1);
ee_positions = zeros((num_images*length(angles)), 3);
ee_angles = zeros((num_images*length(angles)), 3);



% include counter if actuator is long
counter = 0;
amt = (4/25.4)/length(angles);
for o = 1:length(angles)
    SetHIPressure(0)
    % VacuumDuration(0.5)
    ToggleVacuumChannel(1)

    %calculate EE position based on desired offset from camera position
    ex = (des_x - Ltool*sin(angles(o)))/1000;
    ez = (des_z - Ltool*cos(angles(o)))/1000 + counter*amt;
    pos = [ex, -0.125, ez];
    eulerangles = [0, angles(o), 0*pi/4];

    % move to calculated position
    MoveToPose(IP, pos, eulerangles, movetime)
    ToggleVacuumChannel(0)
    pause(1)
    close

    counter = counter+1;

    for i = 1:length(pressures)
        SetHIPressure(pressures(i))
        ee_positions((o*length(pressures) - length(pressures)) + i, :) = pos;
        ee_angles((o*length(pressures) - length(pressures)) + i, :) = eulerangles;
        % FastSetHIPressure(pressures(i), ljerror, ljhandle, ljudObj)

        start = tic;
        [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);
        time = toc(start);
        AllData = [AllData; Data];

        times = linspace(0, time, length(Data));

        pause(0.15) %pause is needed to prevent frames from repeating in .tif file. 
        % last_img = next_img;
        next_img = snapshot(cam1);
        % next_img = getsnapshot(vidobj);

        disp('Image Captured')

        if o == 1 && i ==1 % if this is the first image, create file. else, add to file
            LabelString = strcat('Input Pressure =', num2str(pressures(i), '%0.3f'), ' psi');
            LabelPosition = [10 10];
            LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
            % prepare to save images in desired folder
            Path = pwd;
            ActuatorDirectory = strcat(Path, '\Test Data\', Actuator, '\');
            imgDirectory = strcat(ActuatorDirectory, 'Images\');
            % folderName = append(Actuator, '\');
            [status, msg, id] = mkdir(imgDirectory);

            imString = "_NA_TestImgs";
            imgFile = strcat(FileName, imString, '.tif');
            VerticalImages = imgFile;
            file_location = strcat(imgDirectory, imgFile); 
            addpath(imgDirectory)
            imwrite(LabeledImage, file_location);
        else

            LabelString = strcat('Input Pressure =', num2str(pressures(i), '%0.3f'), ' psi');
            LabelPosition = [10 10];
            LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");

            imwrite(LabeledImage, file_location, 'WriteMode','append');
        % clear next_img
        end
        pause(0.1)
        VacuumDuration(vac_time)


    end
    % clear cam
    VacuumDuration(vac_time*2)

end

% remove air from system
RemoveAir

% return to home position
position = [0.300, -0.075, .325];
eulerangles = [0, pi/4, 0];
MoveToPose(IP, position, eulerangles, movetime)
close

% Print Image file name and location
Images_Saved_to = file_location
Image_file_name = imgFile

%% save information about test in MAT files

[status, msg, id] = mkdir(append(ActuatorDirectory, 'MAT Files'));
matFileLocation = strcat(ActuatorDirectory, 'MAT Files\');
addpath(matFileLocation)

% Load pressure sensor Calibration function
pressurestruct = load('Prosense30psi17Jun2025.mat');
VoltageToPressureFit = pressurestruct.CalibrationCoefficients;

% save input and pressures in MAT file
AllInputPressures = [];
for k = 1:length(angles)
    AllInputPressures = [AllInputPressures, pressures];
end
input_matFileName = strcat(FileName, '_inputPressures');

MeasuredPressures = polyval(VoltageToPressureFit, AllData);
press_and_time = [MeasuredPressures', time'];
meas_matFileName = strcat(FileName, '_MeasuredPressures');

% save commanded and measured pressures
save(strcat(matFileLocation, input_matFileName, '.mat'), 'AllInputPressures')
save(strcat(matFileLocation, meas_matFileName, '.mat'), 'MeasuredPressures')

% save arm end effector pose in MAT file
positionMatFile = strcat(FileName, '_ArmPositions');
orientationMatFile = strcat(FileName, '_ArmOrientations');

save(strcat(matFileLocation, positionMatFile, '.mat'), 'ee_positions')
save(strcat(matFileLocation, orientationMatFile, '.mat'), 'ee_angles')


% Next: Horizontal Images

step_time = 3;
pause(step_time)

extra2 = '_multipose_horizontal_vac';

if vac_time == 0
    extra2 = '_multipose_horizontal_novac';
end

FileName = strcat(Actuator, extra2);

% move arm to standard position
IP = '192.168.1.10'; 
position = [0.250, -0.0750, 0.2550];
eulerangles = [-pi/4, pi/2, pi/2];
movetime = 3;
MoveToPose(IP, position, eulerangles, movetime)

close

% max_pressure = 20;

angles = [-45:wedgeSize:45] * pi/180;
pressures = linspace(0, max_pressure, num_steps);

num_images = length(pressures);

% iterate through pressures, take picture for each, add tif file.

% take a picture at 1/10 max pressure, add to .tif file. 
% VacuumDuration(.5)
% SetHIPressure(max_pressure/10)

% % disp('Taking photo in 2 seconds...')
% % pause(1)
% disp('Taking photo in 1 second...')
% pause(1)

% est_num_entries = 1000 * 2 * length(pressures) * length(angles);
% commanded_pressure = zeros(est_num_entries, 1);
% voltages_main = zeros(est_num_entries, 1);
% time = zeros(est_num_entries, 1);
% index = 1;
% [ljerror, ljhandle, ljudObj] = InitializeLabJack();

% total_time = tic;

% clear cam
% cam = webcam(1);

Ltool = 70.675+10; 
% Lact = 89;

des_x = 12.25*25.4;
des_y = -2.5*25.4;

InputPressures = zeros((num_images*length(angles)), 1);
ee_positions = zeros((num_images*length(angles)), 3);
ee_angles = zeros((num_images*length(angles)), 3);

% [ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack();
% channels = [4, 10];
% scanRate = 1000;
% step_time = step_time;
AllData = [];
pause(2)
% include counter if actuator is long
counter = 0;
amt = (3/25.4)/length(angles);
for o = 1:length(angles)
    SetHIPressure(0)
    % VacuumDuration(0.5)
    ToggleVacuumChannel(1)

    %calculate EE position based on desired offset from camera position
    ex = (des_x - Ltool*cos(angles(o)))/1000;
    ey = (des_y - Ltool*sin(angles(o)))/1000; % + counter*amt;
    pos = [ex, ey, 0.2550];
    eulerangles = [angles(o), pi/2, 2*pi/4];

    % move to calculated position
    MoveToPose(IP, pos, eulerangles, movetime)
    ToggleVacuumChannel(0)
    pause(1)
    close

    counter = counter+1;

    for i = 1:length(pressures)
        SetHIPressure(pressures(i))
        ee_positions((o*length(pressures) - length(pressures)) + i, :) = pos;
        ee_angles((o*length(pressures) - length(pressures)) + i, :) = eulerangles;
        % FastSetHIPressure(pressures(i), ljerror, ljhandle, ljudObj)

        start = tic;
        [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj);
        time = toc(start);
        AllData = [AllData; Data];

        times = linspace(0, time, length(Data));

        pause(0.15) %pause is needed to prevent frames from repeating in .tif file. 
        next_img = snapshot(cam2);

        disp('Image Captured')
        
        if o == 1 && i ==1 % if this is the first image, create file. else, add to file
           LabelString = strcat('Input Pressure =', num2str(pressures(i), '%0.3f'), ' psi');
            LabelPosition = [10 10];
            LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
            % prepare to save images in desired folder
            Path = pwd;
            ActuatorDirectory = strcat(Path, '\Test Data\', Actuator, '\');
            imgDirectory = strcat(ActuatorDirectory, 'Images\');
            folderName = append(Actuator, '\');
            [status, msg, id] = mkdir(imgDirectory);

            imString = "_NA_TestImgs";
            imgFile = strcat(FileName, imString, '.tif');
            HorizontalImages = imgFile;
            file_location = strcat(imgDirectory, imgFile); 
            addpath(imgDirectory)
            imwrite(LabeledImage, file_location);
        else
                     
            LabelString = strcat('Input Pressure =', num2str(pressures(i), '%0.3f'), ' psi');
            LabelPosition = [10 10];
            LabeledImage = insertText(next_img, LabelPosition, LabelString, FontSize=30, TextBoxColor="white", TextColor="black");
        
            imwrite(LabeledImage, file_location, 'WriteMode','append');
        % clear next_img
        end
        pause(0.05)
        VacuumDuration(vac_time)
        pause(0.05)

    end
    VacuumDuration(vac_time*2)
    % clear cam

end

% remove air from system
RemoveAir

% return to home position
position = [0.250, -0.0750, 0.2250];
eulerangles = [-pi/4, pi/2, 2*pi/4];
MoveToPose(IP, position, eulerangles, movetime)
close

% Print Image file name and location
Images_Saved_to = file_location
Image_file_name = imgFile

%% save information about test in MAT files

[status, msg, id] = mkdir(append(ActuatorDirectory, 'MAT Files'));
matFileLocation = strcat(ActuatorDirectory, 'MAT Files\');
addpath(matFileLocation)

% Load pressure sensor Calibration function
pressurestruct = load('Prosense30psi17Jun2025.mat');
VoltageToPressureFit = pressurestruct.CalibrationCoefficients;

% save input and pressures in MAT file
AllInputPressures = [];
for k = 1:length(angles)
    AllInputPressures = [AllInputPressures, pressures];
end
input_matFileName = strcat(FileName, '_inputPressures');

MeasuredPressures = polyval(VoltageToPressureFit, AllData);
press_and_time = [MeasuredPressures', time'];
meas_matFileName = strcat(FileName, '_MeasuredPressures');

% save commanded and measured pressures
save(strcat(matFileLocation, input_matFileName, '.mat'), 'AllInputPressures')
save(strcat(matFileLocation, meas_matFileName, '.mat'), 'MeasuredPressures')

% save arm end effector pose in MAT file
positionMatFile = strcat(FileName, '_ArmPositions');
orientationMatFile = strcat(FileName, '_ArmOrientations');

save(strcat(matFileLocation, positionMatFile, '.mat'), 'ee_positions')
save(strcat(matFileLocation, orientationMatFile, '.mat'), 'ee_angles')

Directory = append(pwd, '\Test Data\', Actuator);

end