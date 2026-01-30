%% InitializeLabJack
% 
% Date: 5/28/2025
% Inputs:
%   None   
%
% Output:
%   ljerror, ljhandle, ljudObj - properties of the initialized Labjack U6 
% 
% Objective: Function to Initialise the Labjack U6 and create objects for
% use in other functions.


function [ljasm, ljerror, ljhandle, ljudObj] = InitializeLabJack()
% Make the UD .NET assembly visible in MATLAB.
ljasm = NET.addAssembly('LJUDDotNet');
ljudObj = LabJack.LabJackUD.LJUD;
try
    [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);
    catch e
    showErrorMessage(e)
end

end