%% TakeAndNamePhoto
% 
% Date: 5/28/2025
% Inputs:
%   None (requires USB Webcam to be connected to PC)
%
% Output:
%   imgFile - image file that contains the desired image
% 
% Objective: simple function to automatically take and name a photo using
% MATLAB and the connected camera. Useful when generating test images.

function Image_Saved_To = TakeAndNamePhoto()

    disp('Taking photo in 3 seconds...')
    pause(1)
    disp('Taking photo in 2 seconds...')
    pause(1)
    disp('Taking photo in 1 second...')
    pause(1)
    
    cam = webcam(1);
    test_img = snapshot(cam);
    prompt = "Give image a name (no spaces or special characters, do not include extension):";
    x = input(prompt, 's');
    imString = x;
    prompt = "Define File Type for image (.jpg, .png, or .tif) INCLUDE DOT:";
    y = input(prompt, 's');
    fileType = y;
    fileType = '.png'
    path = pwd;
    filePath = strcat(path, '\Images\CalibrationImages\calpics_22mm_2\');

    Image_Saved_To = strcat(filePath, imString, fileType)
    imwrite(test_img, Image_Saved_To);
    clear cam

end