%% StartTifImage
% 
% Date: 8/29/2025
% 
% Inputs:
%   name - string, 'char'. character string that describes name of
%   .tif file that we want to add an image to. 

% Output:
%   imgName - string, 'char'. describes name of saved file. 
%   file_location - string, 'char'. describes where the file was saved

% Objective: Take a photo and add it to a .tif file. 

function [imgName, file_location] = StartTifImage(name)

cam = webcam(1);
img = snapshot(cam);

% Prepare location for file to save
imgName = strcat(name, '.tif');
Path = pwd;
extension = '\Images\Other\';
file_location = strcat(Path, extension, imgName);

imwrite(img, file_location);
        
end