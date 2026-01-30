%% SetHIPressure
% 
% Date: 5/28/2025
% Inputs:
%   pressure - desired pressure in psi, max of 87
%
% Output:
%   status - message that confirms the inflation fixture has executed the 
%   command.
% 
% Objective: Function that sets the HI Proportional pressure control valve 
% (0-6 bar) to output a specified pressure (in psi) via Labjack interface 

% NOTE: if the run time of SetHIPressure becomes an issue, some time can be
% saved by removing the steps where we Make the UD .NET assembly visible in 
% MATLAB and Open the first found LabJack U6. This hasn't been removed yet
% because the response time of most soft actuators seems to be much longer
% than the computational time for the command, so it hasn't presented an
% issue YET. 

function SetHIPressure(pressure)

% Make the UD .NET assembly visible in MATLAB. 
ljasm = NET.addAssembly('LJUDDotNet');
ljudObj = LabJack.LabJackUD.LJUD;

% calculate required voltage for the desired pressure
Pin = pressure; % Input pressure should be in psi
%Vin = 10*(Pin/80.0); 
Vin = 0.1138*Pin;

try
    % Read and display the UD version.
    % disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

    % Open the first found LabJack U6.
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);

    %%% Uncomment below section if valve is used to switch between HI and
    %%% LO channels. 
    % % % % togglechannel = 3; % relay to control valve that switches between HI and LO is connected to FIO3
    % % % % if pressure == 0
    % % % %     ljudObj.eDO(ljhandle, togglechannel, 0); % de-energise valve
    % % % % elseif pressure > 0 
    % % % %     ljudObj.eDO(ljhandle, togglechannel, 1); % energise valve
    % % % % end
    

    % Set the DAC B pin (connected to HI pressure control valve on
    % inflation fixture) to the calculated voltage
    ljudObj.ePutSS(ljhandle, 'LJ_ioTDAC_COMMUNICATION', 'LJ_chTDAC_UPDATE_DACB', Vin, 0);

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