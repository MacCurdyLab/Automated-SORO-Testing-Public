%% Remove Air


% Date: 7/14/2025
% Inputs:
%   None
%
% Output:
%   None 
% 
% Objective: function to remove air from actuators in a single line call.
% The system is exposed to the Vacuum line, Input pressure is set to 0,
% then the vacuum valve is closed again. This ultimately results in most of
% the air being removed from the system, effectively a "reset" when the
% actuator is pressurized. 

function RemoveAir()
    [ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack();
    ToggleVacuumChannel(1); 
    SetHIPressure(0); 
    SetLOPressure(0); 
    pause(1); 
    ToggleVacuumChannel(0)
    ljudObj.eDO(ljhandle, 3, 0);

end