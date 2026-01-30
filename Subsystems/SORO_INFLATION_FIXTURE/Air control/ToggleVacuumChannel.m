%% ToggleVacuumChannel
% 
% Date: 6/6/2025 
% Inputs:
%   None
%
% Output:
%   status - Whether the vacuum valve is open to the vacuum or pressurized
%   air lines. 
% 
% Objective: Function that switches a valve from the pressurized line to the vacuum
% line (or vice versa) until the function is called again. 

% NOTE: there is no control over how strong the vacuum is. The vacuum air
% line in the lab is approximately -10psi.

% AVOID DRAWING VACUUM FOR MORE THAN 3 MINUTES STRAIGHT: THE SOLENOID
% VALVE COIL HEATS UP, AND CAN REACH UP TO 40 C IN ~3 MINUTES

function status = ToggleVacuumChannel(state)
[ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack();
% Make the UD .NET assembly visible in MATLAB.
% ljasm = NET.addAssembly('LJUDDotNet');
% ljudObj = LabJack.LabJackUD.LJUD;

try
    % Read and display the UD version.
    disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])

    % Open the first found LabJack U6.
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);

    % Vacuum solenoid valve is connected to channel FIO2
    channel = 2;

    ljudObj.eDO(ljhandle, channel, state);

    % % Read the state of FIO2 with FIO4
    % state = 0;
    % [ljerror, state] = ljudObj.eDI(ljhandle, 4, state)
    % 
    % 
    % % Set the state of FIO2.    
    % if state == int32(0) 
    %     ljudObj.eDO(ljhandle, channel, 1);
    %     status = 'Vacuum Open';
    % 
    % elseif state == int32(1)
    %     ljudObj.eDO(ljhandle, channel, 0);
    %     status = 'Vacuum Closed';
    % end

catch e
    showErrorMessage(e)
end

end