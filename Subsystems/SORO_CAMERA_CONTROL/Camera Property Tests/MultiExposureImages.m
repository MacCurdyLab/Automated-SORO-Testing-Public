%% MultiExposureImages
% 
% Date: 5/28/2025
% Inputs:
%   None (requires USB camera to be connected to PC)
%
% Output:
%   TifFile - .tif file that contains 13 images, one for each exposure
%   setting. 
% 
% Objective - function to take image at all available exposure settings and 
% store in .tif file for manual comparison. Assists with selecting exposure
% value for ambient lighting conditions

function TifFile = MultiExposureImages()

prompt = "Give image a name (no spaces or special characters, do not include extension):";
x = input(prompt, 's');
imString = x;

imgFile = strcat(imString, '.tif');

% if webcam fails to initialize, restart MATLAB and try again. 
cam = webcam(1);

disp('Taking photos in 2 seconds...')
pause(1)
disp('Taking photos in 1 second...')
pause(1)

exposureSettings = -1:-1:-13; 

% iterate through all exposure settings, take a photo, and add to .tif file
for i = 1:length(exposureSettings)
    exposureSettings(i)
    cam.Exposure = (exposureSettings(i));
    pause(1)
    img = snapshot(cam);
    
    if i == 1
        % Prepare location for file to save
        Path = pwd;
        extension = '\Images\CameraPropertyTests\';
        file_location = strcat(Path, extension, imgFile);
        imwrite(img, file_location);
    else
        imwrite(img, file_location, 'WriteMode','append');
    end
end


%clear cam
Saved_to = file_location
TifFile = imgFile;

end