%% HoughMarkerDetection
% 
% Date: 5/28/2025
% Inputs:
%   ImageToProcess - string, 'char'. includes file name and extension of a .tif file 
%   that contains images of a soft actuator at multiple different bend states. 
%   Marker_Diameter - float, 'double'. Diameter in MILLIMETERS of the
%   circular markers attached to the actuator under test
%   SaveDir - string, 'char'. Specifies which actuator directory the images
%   to process are in. 
%   camPosition - string, 'char'. Specifies which camera was used to take the
%   images that are being processed. 
%   lowerRadBound - float, double - lower bound of radii that are targeted
%   for detection 
%   upperRadBound - float, double - upper bound of radii that are targeted
%   for detection 
%
% Output:
%   ImgProcessed - string, 'char'. points to image file with centroid markers added.
%   positionCellArray - Cell Array, 'cell'.  that includes the X, Y coordinates of
%   all centroids in all images. 
%   pixels_per_mm - float, 'double' - estimate of how many pixels make up one
%   millimeter in real space. 
% 
% Objective: Function to identify fiducial markers in .tif image set of soft
% robotic actuator. Process does blob detection (assumes YELLOW blobs are
% attached), then reports centroids of detected blobs in a cell array.  
% - Each cell represents a different frame, and within each cell is an Nx2 array of numbers. 
% These numbers represent the X, Y coordinates of the blob centroids in PIXEL coordinates 
% (origin is in TOP LEFT, RIGHT = Positive X direction, DOWN = Positive Y direction)
% X = 1st column, Y = 2nd column.
% - "Processing" includes image un-distortion and marking of fiducial
% centroids. 

function [ImgProcessed, positionCellArray, pixels_per_mm] = HoughMarkerDetection(ImageToProcess, Marker_Diameter, SaveDir, camPosition, lowerRadBound, upperRadBound)

%% Load the pre-existing camera calibration images
% These images are specific to a unique USB Webcam, and will need to be
% replaced for a new camera. They each depict the fiducial checkerboard in
% different positions and orientations.
% startCamIntrinsics = tic;
numImages = 33;
files = cell(1, numImages);
for i = 1:numImages
    files{i} = [pwd,'\Images\CalibrationImages\calpics_22mm_', camPosition, '\Image',num2str(i),'.png'];
end
I = imread(files{1});
magnification = 25;

%% Calibrate the Camera (Instrinsics)
%only necessary once for each camera to be used, but is easier to
%re-calculate Camera Parameters than to store and load them. 

% Detect the checkerboard corners in the images.
[imagePoints, boardSize] = detectCheckerboardPoints(files);

% Generate the world coordinates of the checkerboard corners in the
% pattern-centric coordinate system, with the upper-left corner at (0,0).
squareSize = 22; % in millimeters
worldPoints = generateCheckerboardPoints(boardSize, squareSize);

% Calibrate the camera.
imageSize = [size(I, 1), size(I, 2)];
cameraParams = estimateCameraParameters(imagePoints, worldPoints, ...
                                     'ImageSize', imageSize);

% Evaluate calibration accuracy.
% figure; showReprojectionErrors(cameraParams);
% title('Reprojection Errors');

%% Calculate Camera Extrinsics (pose)
%This must be performed any time the camera pose is modified
%This uses calibrationImg, a picture of the small calibration grid on the
%wooden insert, taken from the final camera pose
calibrationImg = imread(['calibrationImg', camPosition, '.jpg']); 
%[a b] = size(ActuatorImg)
calibrationImgResized = imresize(calibrationImg, [1200, 1600]);

%% Undistort Fiducial Calibration Image
% Since the lens introduced little distortion, use 'full' output view to illustrate that
% the image was undistored. If we used the default 'same' option, it would be difficult
% to notice any difference when compared to the original image. Notice the small black borders.
[fiducialUndistorted, newOrigin_fid] = undistortImage(calibrationImgResized, cameraParams, 'OutputView', 'full');
% figure; imshow(fiducialUndistorted, 'InitialMagnification', magnification);
% title('Undistorted Image');

%% Calculate Camera Pose from Fiducial

% Detect the checkerboard.
[imagePointsFid, boardSizeFid] = detectCheckerboardPoints(fiducialUndistorted);
squareSizeFid = 9.4; % in millimeters
worldPointsFid = generateCheckerboardPoints(boardSizeFid, squareSizeFid);
% Adjust the imagePoints so that they are expressed in the coordinate system
% used in the original image, before it was undistorted.  This adjustment
% makes it compatible with the cameraParameters object computed for the original image.
imagePointsFid = imagePointsFid + newOrigin_fid.PrincipalPoint; % adds newOrigin to every row of imagePoints

% Compute rotation and translation of the camera.
[R, t] = extrinsics(imagePointsFid, worldPointsFid, cameraParams);
% camExtrinsics = estimateExtrinsics(imagePointsFid, worldPointsFid, cameraParams)
% loadTime = toc(startCamIntrinsics)

%% Prepare to process images in specified .tif file

% Gather information about image we want to process
info = imfinfo(ImageToProcess);
% find number of images in .tif file
num_images = numel(info);

%% Resize, then Undistort each image in ImageToProcess
all_images = cell(1, num_images);
for j = 1:num_images
    indiv_img = imread(ImageToProcess, j);
    indiv_img_resize = imresize(indiv_img, [1200 1600]);
    [indiv_img_undistorted, newOrigin_finger] = undistortImage(indiv_img_resize, cameraParams, 'OutputView', 'full');
    all_images{j} = indiv_img_undistorted;
    % size(indiv_img_resize)
    % size(indiv_img_undistorted)
end

%% Calculate Tracking Point Positions

% If no radius bounds are given, assume 12-100 pixel blobs
if nargin == 4
    radiusRange = [12, 100];
else
    radiusRange = [lowerRadBound, upperRadBound];
end

markers_detected = zeros(1, length(all_images));
all_centroids_all_frames = cell(num_images, 1);
all_radii_all_frames = cell(num_images, 1);

fontSize = 20;

figure()
for k = 1:num_images
    image = all_images{k};

    [centers, radii, metric] = imfindcircles(image, radiusRange, 'ObjectPolarity', 'bright');

    markers_detected(k) = length(radii);
    all_centroids_all_frames{k} = centers;
    all_radii_all_frames{k} = radii;

    % Draw points on image. Can't change thickness of lines, so plot a few
    % of them on top of each other. 
    thicken = [-1, -1; -1, 0; -1, 1; 
                0, -1;  0, 0;  0, 1;
                1, -1;  1, 0;  1, 1];
    Marked_frame = image;
    for oscill = 1:9
        Marked_frame = insertMarker(Marked_frame, centers+thicken(oscill, :), "+", MarkerColor="red", Size=12);
    end
       
    imshow(Marked_frame)
    axis on;
    hold on;
    caption = sprintf('Frame %d, %d blobs found', k, num_images);
    title(caption, 'FontSize', fontSize);
    drawnow;

    if k == 1
        % Prepare location for file to save
        Path = pwd;
        ActuatorDirectory = strcat(Path, '\Test Data\', SaveDir);
        
        % Remove.tif from file name
        fileTitle = erase(ImageToProcess, '.tif');
        % add "Processed.tif" to the file name
        newFileTitle = strcat(fileTitle, 'Processed.tif');

        ImgProcessed = newFileTitle;

        [status, msg, id] = mkdir(append(ActuatorDirectory, '\Images\Processed Images\'));
        imgFileLocation = strcat(append(ActuatorDirectory, '\Images\Processed Images\'));
        addpath(imgFileLocation)

        file_location = strcat(ActuatorDirectory, '\Images\Processed Images\', newFileTitle)
        imwrite(Marked_frame, file_location)
        % imwrite(imghold_axes.cdata, axesFileTitle)
        
    else
        imwrite(Marked_frame, file_location, 'WriteMode','append');
    end
    
end

all_radii = cell2mat(all_radii_all_frames);
mean_radii = mean(all_radii);

pixels_per_mm = 2*mean_radii/Marker_Diameter;

% estimate pixels per mm in plane occupied by calibration image
Checker_lengths = zeros(length(imagePointsFid)-1, 1);
% measure distance between each consecutive point
for chkpt = 1:(length(imagePointsFid)-1)
        Checker_lengths(chkpt) = dist_2pts(imagePointsFid(chkpt, 1), imagePointsFid(chkpt, 2), imagePointsFid(chkpt+1, 1), imagePointsFid(chkpt+1, 2));
end
% remove any measured distances greater than 2x the first measured distance
% (these are lines that go diagonally from one column on the checkerboard to another)
Checker_lengths(Checker_lengths > Checker_lengths(1)*2) = [];

% find mean, divide by the known size of checkerboards to find pixels per
% mm. 
Checker_length_Pixels = mean(Checker_lengths);

pixels_per_mm_2 = Checker_length_Pixels/squareSizeFid;

positionCellArray = all_centroids_all_frames;

mean_pts_per_frame = length(all_radii)/num_images

end
