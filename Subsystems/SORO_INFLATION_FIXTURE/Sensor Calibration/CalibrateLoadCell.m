%% Calibrate Load Cell
% 
% Date: 6/6/2025
% Inputs:
%   LoadCellName - string that describes the physical load cell that is
%   calibrated
%   LoadCellAdaperWeight - weight in grams of any object or surface that is
%   set atop the load cell to allow it to accept weights/objects. (0 if
%   nothing is used.)
%   channel - LabJack channel that the load cell is connected to. 
%   
%
% Output:
%   CalibrationCoefficients - coefficients for a linear fit that describes
%   the response of a load cell. 
%   MatFile - mat file that contains the coefficients
% 
% Objective: function to automatically generate a calibration function for
% a given load cell. User will be asked to place 10 objects on the load
% cell or adapter plate

function [CalibrationCoefficients, MatFile] = CalibrateLoadCell(LoadCellName, LoadCellAdapterWeight, channel)

weights = zeros(1, 10);
voltages = zeros(1, 10);

for i = 1:10
    disp(['Object Number ', num2str(i), '/10'])
    disp('Place an object of a known weight on the Load Cell')
    prompt1 = 'Enter Object Weight (in grams): ';
    weights(i) = input(prompt1) + LoadCellAdapterWeight;
    disp('Wait...')
    pause(0.5)
    voltages(i) = ReadAINchannel(channel);
end

figure()
scatter(voltages, weights, '+')
ylabel('Weight (g)')
xlabel('Voltage (V)')
hold on 
CalibrationCoefficients = polyfit(voltages, weights,  1);
x2 = linspace(min(voltages), max(voltages)); 
y = CalibrationCoefficients(1)*x2 + CalibrationCoefficients(2);
plot(x2,y)
legend('Measured Weights', 'Fit Line')


extime = datetime('now'); 
monthYear = string(extime, 'ddMMMyyyy');
MatFile = strcat(LoadCellName, monthYear);
extension = '.mat';
location = strcat(pwd, '\MAT files\Calibration Functions\');

save(strcat(location, MatFile, extension), 'CalibrationCoefficients')

end
