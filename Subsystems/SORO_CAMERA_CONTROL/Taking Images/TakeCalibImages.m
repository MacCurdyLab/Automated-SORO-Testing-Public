%% TakeAndNamePhoto
% 
% Date: 5/28/2025
% Inputs:
%   (requires USB Webcam to be connected to PC)
%   CamNum - integer, 'double'. Specifies which camera will take images.
%   Call 'webcamlist' to see list of connected cameras. 
%   folder - string, 'char'. Directory where images should be saved. 
%
% Output:
%   file_location - string, 'char'. points to directory where images are
%   saved. 
% 
% Objective: simple function to automatically take and name a photo using
% MATLAB and the connected camera. Useful when generating test images.

function file_location = TakeCalibImages(CamNum, folder)

cam = webcam(CamNum);
% cam.Exposure = -5;
% cam.Resolution = cam.AvailableResolutions{1};

for k = 1:33

 answer = 'n';

    while answer ~= 'y'
        disp('Hold Checkerboard Fiducial in front of camera at some orientation')
        disp('Taking photo in 3 seconds...')
        pause(2)
        disp('Taking photo in 1 second...')
        pause(1)
        
        img = snapshot(cam);
        disp('Photo Taken')
        
        imshow(img)
        title(append('Fiducial Image: SEE COMMAND WINDOW. Is Image OK? (y/n) ', ' Img Number: ', num2str(k)))
        
        qualityQuestion = 'Is Image OK? (y/n) ';
        answer = input(qualityQuestion, 's');
        % if answer == 'y'
        %     break
        % end
    end
    % Prepare location for file to save

    extension = append('\Images\CalibrationImages\', folder, '\');

    fileName = append('Image',num2str(k),'.png');
        
    file_location = strcat(pwd, extension, fileName);
    imwrite(img, file_location);
    
end
    

end

