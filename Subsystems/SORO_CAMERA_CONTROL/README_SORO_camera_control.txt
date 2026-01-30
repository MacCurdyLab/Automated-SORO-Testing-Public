Randy Peterson
Updated: 29 August 2025

This folder (SORO_CAMERA_CONTROL) contains helper functions that assist with using the USB webcam in the SORO testing setup. 

===================="Camera Property Tests"====================

 sub-folder contains functions that automatically cycle through certain camera properties (Exposure time and resolution), taking an image for each option. This allows a user to view the images for their current physical setup and select the best properties for their needs. 

- MultiExposureImages.m 
-- Function to automatically cycle through all exposure values that the USB webcam permits, take an image at each, and save all images to one .tif file. This allows users to easily compare exposure settings and decide which works best for their lighting conditions. Exposure values may range from -1 to -13, where these numbers correspond to the exponential time that the camera shutter is open (i.e., an exposure setting of -4 corresponds to 10^-4 seconds of exposure time. Lower exposure times = less light captured = darker images). 

- MultiResolutionImages.m
-- Function to automatically cycle through all Image resolutions that the USB webcam permits, take an image at each, and save all images to one .tif file. Allows users to decide what resolution is needed for their purposes. Tradeoff is that larger resolutions = larger file sizes. 

===================="Taking Images"====================

 sub-folder contains a few helper functions that can streamline the writing of new tests that require images to be taken. Basically, these functions are all slight variations of the same idea: take an image, then add it to a .tif or .jpg file. 

- AddImgtoTif.m
-- Add an image to a specified .tif file. If the .tif file does not exist, make it exist. 
NOTE: This function does NOT overwrite existing .tif files. If it is used without first deleting the images from a previous test with the same file name, the images from two separate tests will be appended into one file. 
This function uses an image that has already been taken as an input, and doesn't strictly need to use the camera. 

- StartTifImage.m
-- Outdated function to create a .tif file for other images to be added to. Updating "AddImgtoTif.m" to create .tif files that don't exist when the function is called make this function redundant. 

- TakeandAddtoTifImage.m
-- Very similar to AddImgtoTif.m, but this function does NOT take an image as input. It instead takes the desired camera as an input, and takes the image that is added to the desired .tif file. 

- TakeAndNamePhoto.m
-- Function to take an image and save to a file named based on prompt inputs. Useful when troubleshooting the camera. Quickly take an image and manually observe it.  

- TakeCalibrationImage.m
-- Function to take calibration image after 3 second delay. A user must hold or place the calibration checkerboard near the plane that is to be photographed. Calling this function to generate calibration images should give a consistent file name, extension, location, and parameters for later un-distortion functions to use. New calibration images are needed whenever the camera is moved or physically adjusted (aperture opening, focus, etc.)



