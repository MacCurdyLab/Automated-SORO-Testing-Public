%% MultiResolutionImages
% 
% Date: 5/28/2025
% Inputs:
%   None (requires USB Webcam to be connected to PC)
%
% Output:
%   TifFile - .tif file that contains a unique image for every resolution
%   offered by the camera
% 
% Objective: Create file that allows for easy comparison of available
% resolutions. 

function TifFile = MultiResolutionImages()

prompt = "Give image a name (no spaces or special characters, do not include extension):";
x = input(prompt, 's');
imString = x;

imgFile = strcat(imString, '.tif');

cam = webcam(1);

disp('Taking photos in 2 seconds...')
pause(1)
disp('Taking photos in 1 second...')
pause(1)

Resolutions = cam.AvailableResolutions;
cam.Exposure = -3; % use the same exposure value for all resolutions

% for every available resolution, take an image and add to TifFile
for i = 1:length(Resolutions)
    Resolutions{i}
    cam.Resolution = (Resolutions{i});
    img = snapshot(cam);
    pause(1)

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
TifFile = imgFile;

end