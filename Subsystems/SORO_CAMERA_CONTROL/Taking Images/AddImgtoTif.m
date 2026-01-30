%% TakeandAddtoTifImage
% 
% Date: 8/29/2025
% 
% Inputs:
%   img - Image data, 'uint8'. Obtained by cam = webcam(x), img = snapshot(cam). 
%   nameString - string, 'char'. character string that describes name of
%   .tif file that we want to add an image to. 

% Output:
%   imgName - string, 'char'. describes name of saved file. 
%   file_location - string, 'char'. describes where the file was saved

% Objective: Add an image to a specified .tif file. If the .tif file does 
% not exist, make it exist. 

% NOTE: This function does NOT overwrite existing .tif files. If it is used
% without first deleting the images from a previous test with the same file
% name, the images from two separate tests will be appended into one file. 
% This function uses an image that has already been taken as an input, and 
% doesn't strictly need to use the camera.

function [imgName, file_location] = AddImgtoTif(img, nameString)

imgName = strcat(nameString, '.tif');
file_location = strcat(pwd, imgName);

% if file exists in location, Delete first. if not, create file
if isfile(file_location) == 1 % file exists in location
    % add to file
    imwrite(img, file_location, 'WriteMode','append');
    
else % file does not exist
    % make it exist
    imwrite(img, file_location)
end


end