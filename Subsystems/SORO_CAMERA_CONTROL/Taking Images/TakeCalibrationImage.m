%% TakeCalibrationImage
% 
% Date: 5/28/2025
% Inputs:
%   requires at least 1 USB Webcam to be connected to PC
%   requires the user to hold a checkerboard in front of the camera,
%   approximately in the plane that the users is interested in imaging. 
%   CamNum - integer, 'double'. Specifies which camera will take images.
%   Call 'webcamlist' to see list of connected cameras. 
%   folder - string, 'char'. Directory where images should be saved. 
%
% Output:
%   calibrationImg - .jpg file that (ideally) shows the checkerboard 
% pattern used to determine the camera's orientation and distortion.  
% 
% Objective: Function to take calibration image after 3 second delay. Calling
% this function to generate calibration images should give a consistent 
% file name, extension, location, and parameters for later un-distortion 
% functions to use.

function calibrationImg = TakeCalibrationImage(CamNum, camPosition, folder)
    answer = 'n';

    while answer ~= 'y'
        disp('Hold Checkerboard Fiducial in front of camera')
        disp('Taking photo in 3 seconds...')
        pause(2)
        disp('Taking photo in 1 second...')
        pause(1)
        
        cam = webcam(CamNum);
        cam.Exposure = -4;
        img = snapshot(cam);
        disp('Photo Taken')
        
        imshow(img)
        title('Fiducial Image: SEE COMMAND WINDOW. Is Image OK? (y/n)')
        
        qualityQuestion = 'Is Image OK? (y/n) ';
        answer = input(qualityQuestion, 's');
        % if answer == 'y'
        %     break
        % end
    end
    % Prepare location for file to save
    Path = pwd;
    extension = append('\Images\CalibrationImages\', folder, '\');

    imString = 'calibrationImg';
    fileType = '.jpg';
    calibrationImg = strcat(imString, camPosition, fileType);
    
    file_location = strcat(Path, extension, calibrationImg);
    imwrite(img, file_location);
    clear cam
end