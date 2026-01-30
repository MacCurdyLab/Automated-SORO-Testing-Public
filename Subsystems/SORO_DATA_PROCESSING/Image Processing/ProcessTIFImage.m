%% ProcessTIFImage
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
%   Lower_bd - lower threshold for HSV values to be detected - defines
%   color of blobs function searches for. 
%   Upper_bd - Upper threshold for HSV values to be detected - defines
%   color of blobs function searches for. 
%   NOTE: Yellow markers are assumed if color thresholds are not provided. 
%
% Output:
%   ImgProcessed - string, 'char'. points to image file with centroid markers added.
%   positionCellArray - Cell Array, 'cell'.  that includes the X, Y coordinates of
%   all centroids in all images. 
%   pixels_per_mm - float, double - estimate of how many pixels make up one
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

function [ImgProcessed, positionCellArray, pixels_per_mm] = ProcessTIFImage(ImageToProcess, Marker_Diameter, SaveDir, camPosition, minIslandSize, Lower_bd, Upper_bd)

% SaveDir = 'Keong_3';
% ImageToProcess = append(SaveDir, '_multipose_horizontal_vac_NA_TestImgs.tif');
% Marker_Diameter = 6.35;
% camPosition = 'Top';

% Check if calibration image exists or not. 
% calibrationQuestion = 'Does a calibration image already exist for this camera configuration? (Y/N): ';
% answer = input(calibrationQuestion, 's');
% if answer == 'N'
%     CalibrationImg = TakeCalibrationImage()
% end

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

% If no hsv color value bounds are given, assume yellow blobs are desired. 
if nargin == 5
    % %%GREEN BLOBS
    % Lower_bd = [0.3927, 0.6358, 0.2497];
    % Upper_bd = [0.4498, 1, 1];
    % 
    % %%BLUE BLOBS
    % Lower_bd = [0.6000, 0.9775, 0.8185];
    % Upper_bd = [0.6422, 1, 1];
    % 
    % %%RED BLOBS
    % Lower_bd = [0.9632, 0.6678, 0.6572];
    % Upper_bd = [1    1   1];

    %%YELLOW BLOBS
    Lower_bd = [0.108, 0.292, 0.599];
    Upper_bd = [0.257, 1.000, 1.000];
end

% Lower_bd = [0.108, 0.292, 0.599];
% Upper_bd = [0.257, 1.000, 1.000];

channel1Min = Lower_bd(1);
channel1Max = Upper_bd(1);

channel2Min = Lower_bd(2);
channel2Max = Upper_bd(2);

channel3Min = Lower_bd(3);
channel3Max = Upper_bd(3);

% for all images pulled from .tif file, add bounding boxes and centroid
% markers, and append to new .tif file
% Cell Array to store XY positions for every marker on every frame of .tif
% image
all_centroids_all_frames = cell(num_images, 1);
blob_areas_all_frames = cell(num_images, 1);
blob_lengths_all_frames = cell(num_images, 1);
BBs_all_frames = cell(num_images, 1); % Bounding Boxes for every frame
Average_major_axis_lengths = zeros(num_images, 1);
average_blob_area = zeros(num_images, 1);
% input_pressures = zeros(num_images, 1);


figure()
for k = 1:num_images
    image = all_images{k};

    % imshow(image)
    
    % Convert RGB image to chosen color space
    I = rgb2hsv(image);
    %imshow(I);

    % Process image to read pressure from file
    % ocrResults = ocr(image);
    % 
    % Image_Label = ocrResults.Text;
    % input_pressures(k) = str2num(Image_Label(17:21));

    % Create mask based on chosen histogram thresholds
    sliderBW = (I(:,:,1) >= channel1Min ) & (I(:,:,1) <= channel1Max) & ...
               (I(:,:,2) >= channel2Min ) & (I(:,:,2) <= channel2Max) & ...
               (I(:,:,3) >= channel3Min ) & (I(:,:,3) <= channel3Max);

    BW = sliderBW;
    BW = bwareaopen(BW, minIslandSize);
    %BW = bwareafilt(BW,1);
    BW = imfill(BW, 'holes'); %fill holes

    % ===================================
    % Watershed Algorithm for Separating Overlapping Markers - 12/9/2025
    D = bwdist(~BW); % For each pixel in BW, assign a value that is the Euclidean distance from the selected pixel to the nearest non-zero pixel
    D = -D;

    h = 1;
    D = imhmin(D,h);  % Prevent oversegmentation, suppress regional minima

    A = watershed(D); % Calculate watershed transform

    A(~BW) = 0; % remove background from A

    rgb = label2rgb(A,'jet',[0 0 0]);

    % figure()
    % imshow(rgb)
    % 
    % figure()
  
    A = mean(rgb, 3);
    A(A ~= 0) = 1;
    A = bwareaopen(A, minIslandSize); % remove small islands re-introduced by watershed algorithm
   
    CC = bwconncomp(A);
    % watershedtime = toc(startwater)
    % ===================================

    % S = regionprops(CC, 'BoundingBox', 'Centroid', 'Area', 'MajorAxisLength');
    % centers = cat(1, S.Centroid);
    
    % AddImgtoTif(BW, 'BlackAndWhite')
    % imshow(BW)
    % pause(5)
    % CC = bwconncomp(BW); %find connected regions
    %CC = bwboundaries(BW);
    
    % if k == 52 % Show a specific mask
    %     figure()
    %     imshow(BW)
    % end
    %do you want an example plotted or not?
    plotflag = true;
    
    fontSize = 20;
    
    if CC.NumObjects >= 1
        S = regionprops(CC, 'BoundingBox', 'Centroid', 'Area', 'MajorAxisLength');

        % if CC.NumObjects ~= 17
        %     stop = here
        % end

        % if plotflag == true
        %     imshow(all_images{k});
        %     axis on;
        %     hold on;
        %     caption = sprintf('Frame %d, %d blobs found', k, CC.NumObjects);
        %     title(caption, 'FontSize', fontSize);
        %     drawnow;
        % end

        all_centroids_this_frame = zeros(CC.NumObjects, 2);
        blob_areas_this_frame =  zeros(CC.NumObjects, 1);
        blog_lengths_this_frame = zeros(CC.NumObjects, 1);
        BoundingBoxes_this_frame = zeros(CC.NumObjects, 4);

        %This is a loop to bound the colored objects in a rectangular box.
        for g = 1 : CC.NumObjects
            
            % Find location for this blob.
            BoundingBoxes_this_frame(g, :) = S(g).BoundingBox;
	        thisBB = S(g).BoundingBox;
	        thisCentroid = S(g).Centroid;
            blob_areas_this_frame(g) = S(g).Area;
            blog_lengths_this_frame(g) = S(g).MajorAxisLength;
            % save location of blob centroid
            all_centroids_this_frame(g, 1) = thisCentroid(1);
            all_centroids_this_frame(g, 2) = thisCentroid(2);

            
            % Plot centroid and bounding box on image frame. 
            % if plotflag == true
            %     hRect(g) = rectangle('Position', thisBB, 'EdgeColor', 'b', 'LineWidth', 1.5);
            %     hSpot = plot(thisCentroid(1), thisCentroid(2), 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
            %     % % hText(g) = text(thisBB(1)-30, thisBB(2)+(-1)^g*20-40, strcat('X: ', num2str(round(thisCentroid(1))), '  Y: ', num2str(round(thisCentroid(2)))));
            %     hText(g) = text(thisBB(1)+30, thisBB(2)-10, strcat('X: ', num2str(round(thisCentroid(1))), '  Y: ', num2str(round(thisCentroid(2)))));
            %     set(hText(g), 'FontName', 'Arial', 'FontWeight', 'bold', 'FontSize', 8, 'Color', 'yellow');
            % end
            

        end
        all_centroids_all_frames{k} = all_centroids_this_frame;
        blob_areas_all_frames{k} = blob_areas_this_frame;
        blob_lengths_all_frames{k} = blog_lengths_this_frame;
        BBs_all_frames{k} = BoundingBoxes_this_frame;

        Average_major_axis_lengths(k) = mean(blog_lengths_this_frame);
        average_blob_area(k) = mean(blob_areas_this_frame);
        
        if plotflag == true
            hold off
            drawnow;
            
        end
    else
        S = 0;
    end
    
    % Draw points on image. Can't change thickness of lines, so plot a few
    % of them on top of each other. 
    thicken = [-1, -1; -1, 0; -1, 1; 
                0, -1;  0, 0;  0, 1;
                1, -1;  1, 0;  1, 1];
    Marked_frame = image;
    for oscill = 1:9
        Marked_frame = insertMarker(Marked_frame, all_centroids_this_frame+thicken(oscill, :), "+", MarkerColor="red", Size=12);
    end
    label = '';
    Marked_frame = insertObjectAnnotation(Marked_frame, 'rectangle', BoundingBoxes_this_frame, label, 'Color', 'blue', 'LineWidth', 3);
    
    imshow(Marked_frame)
    axis on;
    hold on;
    caption = sprintf('Frame %d, %d blobs found', k, CC.NumObjects);
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
        
        % [status, msg, id] = mkdir(append(ActuatorDirectory, '\Images\Processed Images\'));
        % imgFileLocation = strcat(append(ActuatorDirectory, '\Images\Processed Images\'));
        % addpath(imgFileLocation)
        % 
        % exportgraphics(ax, strcat(ActuatorDirectory, '\SingleFrame.tif')); % overwrite this every loop, add to allframes.tif before movinng on
        % file_location = strcat(ActuatorDirectory, '\Images\Processed Images\', newFileTitle);
        % 
        % this_frame = imread('SingleFrame.tif');
        % imwrite(this_frame, file_location)
        %imwrite(imghold_axes.cdata, axesFileTitle)   

        % complete file path and save to path

        % [status, msg, id] = mkdir(append(ActuatorDirectory, '\Images\Processed Images\'));
        % imgFileLocation = strcat(append(ActuatorDirectory, '\Images\Processed Images\'));
        % addpath(imgFileLocation)
        % 
        % file_location = strcat(ActuatorDirectory, '\Images\Processed Images\', newFileTitle)
        % imwrite(imghold.cdata, file_location)
        % % imwrite(imghold_axes.cdata, axesFileTitle)

    else
        imwrite(Marked_frame, file_location, 'WriteMode','append');
        
        % exportgraphics(ax, strcat(ActuatorDirectory, 'SingleFrame.tif'));% overwrite this every loop, add to allframes.tif before movinng on
        % this_frame = imread('SingleFrame.tif');
        % imwrite(this_frame, file_location, 'WriteMode','append')

        % imwrite(imghold.cdata, file_location, 'WriteMode','append');
        %imwrite(imghold_axes.cdata, axesFileTitle, 'WriteMode','append');
    end
    % close all

end

all_blob_lengths = cell2mat(blob_lengths_all_frames);
mean_blob = mean(all_blob_lengths);

% figure(); histogram(all_blob_lengths)
% all_blob_lengths(all_blob_lengths > mean_blob+2) = [];
% figure(); histogram(all_blob_lengths)
% mean_blob2 = mean(all_blob_lengths)
% pixels_per_mm_datum_removed = mean_blob2/Marker_Diameter;

upper95CIbound = mean_blob + 1.96 * std(all_blob_lengths)/sqrt(length(all_blob_lengths));
lower95CIbound = mean_blob - 1.96 * std(all_blob_lengths)/sqrt(length(all_blob_lengths));


pixels_per_mm = mean_blob/Marker_Diameter;

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

end


