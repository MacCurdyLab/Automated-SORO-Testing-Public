%% ReadAINchannel
% 
% Date: 5/28/2025
% Inputs:
%   channelp - Integer that defines the LabJack Analog Input channel we 
%   want to read.
%   for example, for channel AIN4, channelP = 4
%
% Output:
%   voltage - raw voltage measured from ground to channel at the 
%   moment data was read.  
% 
% Objective: % Function to read analog input voltage from various sensor
% types connected to the inflation fixture. 

% NOTE: This function re-initializes the Labjack every time it is called. 
% This slows the function, and may make it a poor choice for when a user 
% is attempting to collect "live" data in a loop, or when the sensor input
% is changing often. In these cases, please see FastReadAINchannel or
% LJSream functions instead. This function is still occasionally useful
% when troubleshooting. 

function voltage = ReadAINchannel(channelP)

% Make the UD .NET assembly visible in MATLAB.
ljasm = NET.addAssembly('LJUDDotNet');
ljudObj = LabJack.LabJackUD.LJUD;

try
    % Read and display the UD version.
    % disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

    % Open the first found LabJack U6.
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);
    
    voltage = 0.0;
    range = ljudObj.StringToConstant('LJ_rgBIP10V');
    resolution = 8;
    settling = 0;
    binary = 0;

    channelN = 199;
    state = 0;
    [ljerror, voltage] = ljudObj.eAIN(ljhandle, channelP, channelN, voltage, range, resolution, settling, binary);
    %disp(strcat('FIO0 = ', str(voltage)))
catch e
    showErrorMessage(e)
end

end