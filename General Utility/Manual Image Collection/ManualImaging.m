%% ManualImaging
% 
% Date: 11/11/2025
% Inputs:
%   N/A, handled in Setup Section 
%
% Output:
%   N/A 
% 
% Objective: Script to take a specified number of images of an actuator
% using a manual trigger. This demonstration can be used to show our
% process for taking photos of actuators and the data we can take from
% them. a user-specified number of images are taken, then the centroids of
% all detected fiducial markers are plotted from a single frame. 

clear; clc; close all

%% Setup
TestName = 'ManualImagingTest'

camOrder = [1, 2]; % [frontCam, topCam]
    FrontCam = camOrder(1);
    TopCam = camOrder(2);

camPosition = 'Front';

cam = webcam(FrontCam);

numImages = 10;

% Show a plot of the detected points from this frame
displayFrame = 10;

%% Main

for i = 1:numImages

    % replace button press with some other trigger (timer, etc) if desired.
    disp('Press any key or click the mouse to take an image...');
    while ~waitforbuttonpress
        % Loop continues until a button press or key press occurs
    end
    disp('Image Taken');

    % take and show image
    image = snapshot(cam);
    imshow(image)
    title(append('Image Number ', num2str(i), ' out of ', num2str(numImages)))
    
    % Save images in .tif file
    % if i == 1 (first image), create directory for .tif file. Else, add to
    % .tif file.
    if  i==1 % if this is the first image, create file. else, add to file
        Path = pwd;
        imgDirectory = strcat(Path, '\Test Data\', TestName, '\Images\');
        [status, msg, id] = mkdir(imgDirectory);
        imgFile = strcat(TestName, '.tif');
        file_location = strcat(imgDirectory, imgFile);
        addpath(imgDirectory)
        imwrite(image, file_location);
    else
        imwrite(image, file_location, 'WriteMode','append');
    end

end

close all

%% Process captured images
Marker_Diameter = 6.35; % mm

[ImgProcessed, positionCellArray, pixels_per_mm] = ProcessTIFImage(imgFile, Marker_Diameter, TestName, camPosition);

% pick a frame

pts = positionCellArray{displayFrame};

figure()
scatter(pts(:, 1), abs(pts(:, 2)-1200), 'red', '*')
legend('Detected Points')

% Datum Detection / point sorting? 