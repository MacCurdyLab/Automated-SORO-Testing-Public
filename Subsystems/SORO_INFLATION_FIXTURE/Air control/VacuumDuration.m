%% VacuumDuration
% 
% Date: 5/28/2025
% Inputs:
%   duration - time in seconds
%
% Output:
%   status - unused for now. 
% 
% Objective: Function that switches a valve from the pressurized line to the vacuum
% line for some duration. 

% NOTE: if the run time of VacuumDuration becomes an issue, some time can be
% saved by removing the steps where we Make the UD .NET assembly visible in 
% MATLAB and Open the first found LabJack U6. This hasn't been removed yet
% because the response time of most soft actuators seems to be much longer
% than the computational time for the command, so it hasn't presented an
% issue YET. This may become important if we try to use PWM control to
% control pressures below 0 psig. 
% NOTE 2: there is no control over how strong the vacuum is. the vacuum air
% line in the lab is approximately -10psi. 

function VacuumDuration(duration)

% Make the UD .NET assembly visible in MATLAB.
ljasm = NET.addAssembly('LJUDDotNet');
ljudObj = LabJack.LabJackUD.LJUD;

try
    % Read and display the UD version.
    % disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

    % Open the first found LabJack U6.
    [~, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);

    % Set the state of FIO2.
    channel = 2;
    state = 1;
    ljudObj.eDO(ljhandle, channel, state);
    disp("Vacuum Open")
    %disp(['FIO3 set to ' num2str(state)]);
    pause(duration)
    state = 0;
    ljudObj.eDO(ljhandle, channel, state);
    %disp(['FIO3 set to ' num2str(state)]);
    disp("Vacuum Closed")

catch e
    showErrorMessage(e)
end

end