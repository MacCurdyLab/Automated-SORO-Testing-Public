Randy Peterson
8/27/2025

This folder contains the reference images that are used to estimate the position and distortion of the camera. Unless the camera or the lens used is replaced, these images do not need to be replaced. 

However, if the camera is moved, a single new calibration image must be taken (called calibrationImg.jpg) . This image IS stored in the calpics_22mm_1 directory. 

If the camera is MOVED, but NOT changed, calibrationImg.jpg will need to be replaced. See the script "TakeCalibrationImage.m" under SORO_CAMERA_CONTROL. This script requires a user to hold the checkerboard in front of the camera, and will automatically take an image and save the updated calibrationImg to the correct location. 

The Datum Detection folder contains 2 images of a blue dot on a grey background. This is leftover from a previous attempt to use Normalized Cross-Correlation to automatically detect where the soft actuator mounting fixture is in an image. This is no longer used, and this folder can (and should) be deleted. 

