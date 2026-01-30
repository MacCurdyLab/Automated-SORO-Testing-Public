Randy Peterson
May 15 2025

The intent of this folder is to contain helper functions that control the pressure supplied by the inflation fixture for the Automated Soft Actuator Testing Project. 

SENSOR CALIBRATION

CalibrateLoadCell.m
function to automatically generate a calibration function (polynomial that converts voltage/current to weight(grams)) for a given load cell. User will be asked to place 10 objects on the load cell or an adapter plate (basically just an object that widens the area where we can set weights)

CalibratePressureSensor.m
function to automatically generate a calibration function for a pressure sensor that is connected to the main air output of the inflation fixture. The pressure will increase in 20 steps from 0 to whatever is specified as the max pressure when calling the function. For each pressure step, one reading will be taken of the pressure sensor's 

WaterColumnCalibration.m 
Script to guide a user through the steps of calibrating a pressure sensor using a column of water. Attach the pressure sensor to the bottom of a clear tube of known diameter, then start the script. Follow the prompts and input the information as requested. 


READING DATA FROM DAQ (Labjack U6)

ReadAINchannel.m
Function to read analog input voltage from various sensor types connected to the inflation fixture. 

NOTE: This function re-initializes the Labjack every time it is called. This slows the function, and may make it a poor choice for when a user is attempting to collect "live" data in a loop, or when the sensor input is changing often. In these cases, please see FastReadAINchannel or LJSream functions instead. However, This function is still occasionally useful when troubleshooting.

FastReadAINchannel.m
Function to read analog input voltage from various sensor types connected to the inflation fixture. similar to ReadAINchannel, but assumes that the labjack has already been initialized and saves time by not restarting it. Runs and returns voltage in approximately half the time of ReadAINchannel, but is slightly more cumbersome to use. 

InitializeLabJack.m - 
Function to Initialise the Labjack U6 and save properties for use in other functions.

LJStream.m
Script to start and stop data stream from labjack across requested channels, at requested scan rate. This method for streaming data allows data rates much faster than either of the ReadAINchannel functions. 


AIR CONTROL

RemoveAir.m - 
function to remove air from actuators in a single line call. The system is exposed to the Vacuum line, Input pressure is set to 0, then the vacuum valve is closed again. This ultimately results in most of the air being removed from the system, effectively a "reset" when the actuator is pressurized. 

SetHIPressure.m
Function that sets the HI Proportional pressure control valve (0-6 bar) to output a specified pressure (in psi) via Labjack interface. Assumes that the LabJack has not been initialized, so the function must first initialize the LabJack. This slightly increases runtime, but the response time of the proportional pressure control valve is long enough that it is not an issue in comparison. In cases where runtime must be reduced, use FastSetHIPressure Instead. 

FastSetHIPressure.m
Function that sets the HI Proportional pressure control valve (0-6 bar) to output a specified pressure (in psi) via Labjack interface. Assumes that the LabJack has been initialized already, and requires LabJack properties as input. 

SetLOPressure.m
Function that sets the LO Proportional pressure control valve (0-1 bar) to output a specified pressure (in psi) via Labjack interface 

SetPressure.m
Function that sets a Proportional pressure control valve to output a specified pressure (in psi) via Labjack interface. If the pressure can be controlled by the LO pressure valve, this is preferred as it is more accurate. If not, use HI pressure valve. May want to only energize coil for HI pressure valve, depending on pressure ranges

ToggleVacuumChannel.m
Function that switches a valve from the pressurized line to the vacuum line (or vice versa) until the function is called again.

VacuumDuration.m
Function that switches a valve from the pressurized line to the vacuum line for some duration. 