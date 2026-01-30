
%% SetLOPressure
% 
% Date: 6/28/2025
% Inputs:
%   pressure - desired pressure in psi, max of 14
%
% Output:
%   status - message that confirms the inflation fixture has executed the 
%   command.
% 
% Objective: Function that sets the LO Proportional pressure control valve (0-1 bar) to output a 
% specified pressure (in psi) via Labjack interface 

% NOTE: if the run time of SetLOPressure becomes an issue, some time can be
% saved by removing the steps where we Make the UD .NET assembly visible in 
% MATLAB and Open the first found LabJack U6. This hasn't been removed yet
% because the response time of most soft actuators seems to be much longer
% than the computational time for the command, so it hasn't presented an
% issue YET. 

function SetLOPressure(pressure)

% Make the UD .NET assembly visible in MATLAB. 
ljasm = NET.addAssembly('LJUDDotNet');
ljudObj = LabJack.LabJackUD.LJUD;

% calculate required voltage for the desired pressure
Pin = pressure; % Input pressure should be in psi
%Vin = 10*(Pin/80.0);  
%Vin = (0.1138*5)*Pin; % needs calibration
Vin = 10*(Pin/14.7);

try
    % Read and display the UD version.
    % disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

    % Open the first found LabJack U6.
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);
    ljudObj.ePutSS(ljhandle, 'LJ_ioPUT_CONFIG', 'LJ_chTDAC_SCL_PIN_NUM', 0, 0);
    % Stop any previous stream.

    % Set the DAC A pin (connected to LO pressure control valve on
    % inflation fixture) to the calculated voltage
    ljudObj.ePutSS(ljhandle, 'LJ_ioTDAC_COMMUNICATION', 'LJ_chTDAC_UPDATE_DACA', Vin, 0);

    status = "Setting pressure to " + pressure + " psi";
    disp(status)
    
catch e
    showErrorMessage(e)
end



% may or may not need to clear labjack information as part of larger
% program depending on setup. 
clear ljasm
clear ljudObj

end