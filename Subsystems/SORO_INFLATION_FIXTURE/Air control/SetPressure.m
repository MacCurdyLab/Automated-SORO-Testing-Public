%% SetPressure
% 
% Date: 7/15/2025
% Inputs:
%   pressure - desired pressure in psi, max of 87
%
% Output:
%   status - message that confirms the inflation fixture has executed the 
%   command.
% 
% Objective: Function that sets a Proportional pressure control valve to output a 
% specified pressure (in psi) via Labjack interface. If the pressure can be
% controlled by the LO pressure valve, this is preferred as it is more
% accurate. If not, use HI pressure valve. May want to only energize coil
% for HI pressure valve, depending on pressure ranges

% note: as of 8/27/2025, the extra relay needed to use this function has not
% been added to the inflation fixture. 

function SetPressure(pressure)

% Make the UD .NET assembly visible in MATLAB.
ljasm = NET.addAssembly('LJUDDotNet');
ljudObj = LabJack.LabJackUD.LJUD;

try
    % Open the first found LabJack U6.
    [~, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);


    % Prepare to Set the state of FIO3. (relay control connected to FIO3 
    % on physical inflation fixture)
    togglechannel = 3;   

catch e
    showErrorMessage(e)
end

% Do something based on input pressure
if pressure == 0 % turn both pressures to 0, set valve to be open to LO
    SetLOPressure(0)
    SetHIPressure(0)
    
    state = 0;
    ljudObj.eDO(ljhandle, togglechannel, state);
    disp("Set to LO control valve")

elseif pressure < 0 % as of 7/15, vacuum control not included. May be done with PWM?
    disp('Vacuum Control Not Included')

elseif 0 < pressure && pressure < 14
    % actuate relay to change valve to LO Pressure line
    state = 0;
    ljudObj.eDO(ljhandle, togglechannel, state);
    disp("Set to LO control valve")

    Pin = pressure; % Input pressure should be in psi
    Lo_Vin = 10*(Pin/14.7); % convert to voltage (need to re-calibrate)

    % Set the DAC A pin (connected to LO pressure control valve on
    % inflation fixture) to the calculated voltage
    ljudObj.ePutSS(ljhandle, 'LJ_ioTDAC_COMMUNICATION', 'LJ_chTDAC_UPDATE_DACA', Lo_Vin, 0);

    % Set the DAC B pin (connected to HI pressure control valve on
    % inflation fixture) to 0
    ljudObj.ePutSS(ljhandle, 'LJ_ioTDAC_COMMUNICATION', 'LJ_chTDAC_UPDATE_DACB', 0, 0);

    status = "Setting pressure to " + pressure + " psi";
    disp(status)

else
    % actuate relay to change valve to HI Pressure line
    state = 1;
    ljudObj.eDO(ljhandle, togglechannel, state);
    disp("Set to HI control valve")

    Pin = pressure; % Input pressure should be in psi
    Hi_Vin = 0.1138*Pin; % convert to voltage (need to re-calibrate)

    % Set the DAC B pin (connected to HI pressure control valve on
    % inflation fixture) to the calculated voltage
    ljudObj.ePutSS(ljhandle, 'LJ_ioTDAC_COMMUNICATION', 'LJ_chTDAC_UPDATE_DACB', Hi_Vin, 0);

    % Set the DAC A pin (connected to LO pressure control valve on
    % inflation fixture) 0
    ljudObj.ePutSS(ljhandle, 'LJ_ioTDAC_COMMUNICATION', 'LJ_chTDAC_UPDATE_DACA', 0, 0);

    status = "Setting pressure to " + pressure + " psi";
    disp(status)

end



end