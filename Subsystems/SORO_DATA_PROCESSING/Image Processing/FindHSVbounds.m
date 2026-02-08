%% FindHSVbounds
% 
% Date: 11/17/2025
% Inputs:
%   I - matrix, 'uint8'. imageResolutionY by imageResolutionX by 3. This
%   input is an example image that the user wants to select colored points
%   to identify color thresholds   
%
% Output:
%   BW - matrix, 'logical'. imageResolutionY by imageResolutionX Binary image mask that shows 

%   lower_bd - matrix, 'double' , 1 by 3. - Lower bound of HSV values for
%   selected colors. 

%   upper_bd - matrix, 'double' , 1 by 3. - Upper bound of HSV values for
%   selected colors. 

%   RGB - matrix, 'double', n by 3, where the user selects n points
%   manually. RGB values of all selected points. 

%   HSV - matrix, 'double', n by 3, where the user selects n points
%   manually. HSV values of all selected points. 

% 
% Objective: Query user to select the colors we want to isolate. Identify
% bounds of HSV values that include all pixels similar to the user selected
% colors. Create BW mask of the image that isolates the selected color
% values and output the boundaries required to detect only regions with (approximately) the
% same color as the seleced points
function [BW, lower_bd, upper_bd, RGB, HSV] = FindHSVbounds(I)
I2 = rgb2hsv(I);


disp('Click on colors to detect. Press ENTER when complete')
[xi, yi, RGB] = impixel(I); % return x, y coordiantes of selected points
HSV = impixel(I2, xi, yi); % find hsv color values of selected points

mean_marker = mean(HSV, 1); % find mean and std hsv color values.  
std_marker = std(HSV, 1);

% estimate initial threshholds. x Standard deviations from mean
% (arbitrarily chosen threshold)
lower_bd = mean_marker - 5*std_marker;
upper_bd = mean_marker + 5*std_marker;

BW = (I2(:,:,1) >= lower_bd(1) ) & (I2(:,:,1) <= upper_bd(1)) & ...
     (I2(:,:,2) >= lower_bd(2) ) & (I2(:,:,2) <= upper_bd(2)) & ...
     (I2(:,:,3) >= lower_bd(3) ) & (I2(:,:,3) <= upper_bd(3));

n = 50;
BW = bwareaopen(BW, n); %  removes small islands ( blobs smaller than n pixels )

BW = imfill(BW, 'holes'); % fills holes in detected blobs


end