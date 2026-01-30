Randy Peterson
Updated: 27 August 2025

The intent of this folder is to contain scripts that utilize multiple major components (i.e. camera control, UR5 arm movement, image processing, etc) for the Automated Soft Actuator Testing Project. 

Essentially, scripts that execute a specific test using the helper functions included in the other SORO folders should be placed here. 

AllImages.m is a function that will automatically command the UR5, inflation fixture, and cameras in concert to take all required images of an actuator under test. 

AllImages_Test.m is a script that calls AllImages.m and processes the images to create a model of the actuator under test (R and T matrices). 

MultiBendLoadCellTest_9_22.m is a script that uses the actuator model (R and T matrices) to approach a load cell at a manually input position relative to the base of the UR5 for in-plane bend testing

OffAxisLoadCellTest_9_25.m is a script that uses the actuator model (R and T matrices) to approach a load cell at a manually input position relative to the base of the UR5 for out-of-plane bend testing