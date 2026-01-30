%% Calibrate Pressure Sensor
% 
% Date: 6/9/2025
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
% Objective: function to automatically generate a calibration function for
% a pressure sensor that is connected to the main air output of the
% inflation fixture. The pressure will increase in 20 steps from 0 to
% whatever is specified as the max pressure when calling the function. 

function [coefficients, MatFile] = CalibratePressureSensor(PressureSensorName, max_pressure, duration, channel)

SetHIPressure(0)
VacuumDuration(0.5)

pressures = linspace(0, max_pressure, 20);

voltages = zeros(length(pressures), 1);

for i = 1:length(pressures)

    status = SetHIPressure(pressures(i));
    
    disp(status)
    pause(duration) % pause at each pressure for some arbitrary time 
    voltages(i) = ReadAINchannel(channel);

end

SetHIPressure(0)
coefficients = polyfit(voltages, pressures, 1);

figure()
scatter(voltages, pressures, '+')
hold on
plot(voltages, pressures)
ylabel('Pressure (psi)')
xlabel('Voltage (V)')
hold on 
CalibrationCoefficients = polyfit(voltages, pressures,  1);
x2 = linspace(min(voltages), max(voltages)); 
y = CalibrationCoefficients(1)*x2 + CalibrationCoefficients(2);
plot(x2,y)
legend('Measured Pressures', 'Order of Points', 'Fit Line')
title(strcat('Channel ', num2str(channel), ', pressures from ', num2str(min(pressures)), ' to  ', num2str(max_pressure), ' psi'))


extime = datetime('now'); 
monthYear = string(extime, 'ddMMMyyyy');
MatFile = strcat(PressureSensorName, monthYear);
extension = '.mat';
location = strcat(pwd, '\MAT files\Calibration Functions\');

save(strcat(location, MatFile, extension), 'CalibrationCoefficients')

end