%% TakeandAddtoTifImage
% 
% Date: 8/29/2025
% 
% Inputs:
%   cam - 'webcam' object. Points to the camera initialized in cam =
%   webcam(x)
%   nameString - string, 'char'. character string that describes name of
%   .tif file that we want to add an image to. 

% Output:
%   imgName - string, 'char'. describes name of saved file. 
%   file_location - string, 'char'. describes where the file was saved

% Objective: Take a photo and add it to a .tif file. 

function [imgName, file_location] = TakeandAddtoTifImage(cam, nameString)

% Initialize camera and take photo
img = snapshot(cam);

imgName = strcat(nameString, '.tif');
file_location = strcat(pwd, strcat('\Images\', imgName));

% if file exists in location, add to file. if not, create file

if isfile(file_location) == 1 % file exists in location
    % add to file
    imwrite(img, file_location, 'WriteMode','append');
    
else % file does not exist
    % make it exist
    imwrite(img, file_location)
end


end