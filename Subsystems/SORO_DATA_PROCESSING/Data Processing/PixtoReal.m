%% Convert from pixel coordinates to Real coordinates
% 
% Date: 8/4/2025
% Inputs:
%   Pixel_points - n x 2 matrix of points, where 1st column is X
%   coordinate of pixel positions and column 2 is  Y coordinate
%   pixels_per_mm - scalar value determined from image processing. defines
%   approximately how many pixels make up 1 mm in the plane that soft
%   actuators are tested in. Depends on distance from camera to actuator
%   plane.
%
% Output:
%   points - n x 2 matrix of points converted to IRL X, Y coordinates. 
% 
% Objective: function to convert from pixel points to real coordinates in
% the SORO test fixture

% note: the value used to invert the y axis will change for different image
% resolutions. The default resolution is 1600x1200, so 1200 is used for
% now. 

function points = PixtoReal(Pixel_points, pixels_per_mm)
    
    ptsx = (Pixel_points(:, 1) - Pixel_points(1, 1)) / pixels_per_mm;
    % need to invert Y-axis
    inversion = 1200; % this value may need to change based on image resolution.
    ptsy = ((abs(Pixel_points(:, 2) - 1200)) - (abs(Pixel_points(1, 2) - inversion))) / pixels_per_mm;

    points = [ptsx, ptsy];

end