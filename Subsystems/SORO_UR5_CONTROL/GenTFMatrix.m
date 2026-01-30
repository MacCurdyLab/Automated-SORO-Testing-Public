%% GenTFMatrix
% 
% Date: 5/28/2025
% Inputs:
%   pos - vector that contains the desired X, Y, Z coordinates of the
%   end effector. (in MILLIMETERS)
%   eulerangles - vector that contains three angles (in radians) that
%   describe the orientation of the end effector (ZYZ rotation order)
%
% Output:
%   TFmatrix - 4x4 3D transformation matrix that describes the
%   transformation between the base of the robot arm and the end effector. 
% 
% Objective: function to assemble transformation matrix from desired angles
% and position.

function [TFmatrix] = GenTFMatrix(pos, eulerangles)
    % Convert Euler Angles to Rotation Matrix
    rotmatrix = eul2rotm(eulerangles, 'ZYZ');

    % Append position vector to Rotation matrix, then append row of [0 0 0 1]
    % Transformation matrix is complete
    TF = [rotmatrix pos'];
    TMrow = [0 0 0 1];
    TFmatrix = [TF;TMrow];
end
