Randy Peterson
May 15 2025

The intent of this folder is to contain helper functions that control the movement of the UR5 CB3 Robot Arm for the Automated Soft Actuator Testing Project. 


MoveToPose

- Function that allows for simple changes in the position and orientation of the UR5 CB3 robot arm. The MATLAB IK solver can accept other models of arms, but this function assumes a UR5 is used. 

IMPORTANT NOTE: 
the X and Y axes are reversed between Matlab and Polyscope (the software on physical/simulated arm). As of 8/27/2025, it seems that no correction is needed, but it's worthy of note. The Z axis is consistent between Matlab and Polyscope

Giving a positive X in Matlab results in a negative X in Polyscope. A positive X in MATLAB correlates to the desired area for the current test setup. 


GenTFMatrix

function to assemble transformation matrix from desired end effector angles and position.

