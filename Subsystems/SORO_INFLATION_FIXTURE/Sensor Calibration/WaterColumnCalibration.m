%% Calibrate Pressure sensor with water column

% Date: 8/27/2025
% Inputs:
%   LoadCellName - string that describes the physical pressure sensor that is
%   calibrated
%   max_pressure - maximum pressure for the system to inflate to durimg the
%   test (in psi)
%   duration - amount of time for pressure sensor to remain at pressure
%   before measuring voltage. 
%   channel - LabJack channel that the sensor is connected to. 
%   
% Output:
%   CalibrationCoefficients - coefficients for a linear fit that describes
%   the response of pressure sensor to input pressures. 
%   MatFile - mat file that contains the coefficients
% 
% Objective: Script to guide a user through the steps of calibrating a
% pressure sensor using a column of water. Attach the pressure sensor to
% the bottom of a clear tube of known diameter, then start the script.
% Follow the prompts and input the information as requested. 


channel = 5;
pipeDiameter = 0.7645; % inches

SensorName = 'Prosense100WCH'
% remember to take a zero measurement!

num_readings = 20;

volume_Added = zeros(1, num_readings);
ManualInchesReadings = zeros(1, num_readings);

voltages = zeros(1, num_readings);

for i = 1:num_readings
    disp(['Addition Number ', num2str(i), '/20'])
    disp('Add known volume (in mL) to the water column')

    prompt1 = 'Enter added water (in mL): ';
    volume_Added(i) = input(prompt1);
    disp('Wait...')
    pause(0.5)

    prompt2 = 'Enter Manual reading of total inches of water';
    ManualInchesReadings(i) = input(prompt2);
    pause(0.5)

    voltages(i) = ReadAINchannel(channel)
end

% total volume in mL added to system
totalVolumeAdded = sum(volume_Added);

% convert mL to cubic inches
est_cubic_inches_added = volume_Added/16.387;

totalHeight_observed = ManualInchesReadings(end)

% plot collected data
close all
figure()
scatter(voltages, ManualInchesReadings, '+')
xlabel('Voltages (V)')
ylabel('Inches H2O')
title('Inches of water to Sensor Voltage')

% convert to psi
figure()
Pressure_psi = ManualInchesReadings*0.036127;
scatter(voltages, Pressure_psi, '+')
xlabel('Voltages (V)')
ylabel('Pressure (psi)')
title('Psi to Sensor Voltage')

% find calibration fit function
CalibrationCoefficients = polyfit(voltages, Pressure_psi, 1);

x = linspace(min(voltages), max(voltages)); 
pressureFit = CalibrationCoefficients(1)*x + CalibrationCoefficients(2);
hold on
plot(x, pressureFit)
legend('Measured Values', 'Fit Line'); 

% save calibration function for later use
extime = datetime('now'); 
monthYear = string(extime, 'ddMMMyyyy');
MatFile = strcat(SensorName, monthYear);
extension = '.mat';
location = strcat(pwd, '\MAT files\Calibration Functions\');

save(strcat(location, MatFile, extension), 'CalibrationCoefficients')