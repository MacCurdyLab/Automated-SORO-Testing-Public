%% FastReadAINchannel
% 
% Date: 5/28/2025
% Inputs:
%   channelp - Integer that defines the LabJack Analog Input channel we 
%   want to read.
%   for example, for channel AIN4, channelP = 4
%   ljerror, ljhandle, ljudObj - properties of the initialized Labjack U6
%
% Output:
%   voltage - raw voltage measured from ground to channel AIN4 at the 
%   moment data was read.  
% 
% Objective: % Function to read analog input voltage from various sensor
% types connected to the inflation fixture. similar to ReadAINchannel, 
% but assumes that the labjack has already been initialized and saves 
% time by not restarting it. Runs and returns voltage in approximately half
% the time of ReadAINchannel, but is slightly more cumbersome to use. 

function voltage = FastReadAINchannel(channelP, ljhandle, ljudObj)

try   
    voltage = 0.0;
    range = int32(2);
    % range = ljudObj.StringToConstant('LJ_rgBIP10V');
    resolution = 8;
    settling = 0;
    binary = 0;

    channelN = 199;
    %state = 0;
    [ljerror, voltage] = ljudObj.eAIN(ljhandle, channelP, channelN, voltage, range, resolution, settling, binary);
    [ljerror, voltage] = ljudObj.eAIN(ljhandle, channelP, 199, 0, int32(2), 8, 0, 0);
    %disp(strcat('FIO0 = ', str(voltage)))
catch e
    showErrorMessage(e)
end

end