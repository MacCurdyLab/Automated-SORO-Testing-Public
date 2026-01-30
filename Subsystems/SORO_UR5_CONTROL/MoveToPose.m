%% MoveToPose
% 
% Date: 5/28/2025
% Inputs:
%   IP - IP address of the robot arm or simulator to command
%   position - vector that contains the desired X, Y, Z coordinates of the
%   end effector. ( in METERS ) 
%   eulerangles - vector that contains three angles (in radians) that
%   describe the orientation of the end effector (ZYZ rotation order)
%   move_time - time in seconds that the arm has to complete the move. If
%   the safety speed limits do not allow the arm to complete the move
%   within this time, it will display the message 'Executing' and continue
%   to move while the script progresses. 
%
% Output:
%   [result, state] - message that confirms if the robot has executed the
%   maneuver. 
% 
% Objective: Function that allows for simple changes in the position and
% orientation of the UR5 CB3 robot arm. The MATLAB IK solver can accept
% other models of arms, but this function assumes a UR5 is used. 

% ========= READ ME =========
% IMPORTANT NOTE: the X and Y axes are reversed between Matlab and Polyscope (the
% physical/simulated arm). As of 12/5/2024, it seems that no correction is
% needed, but it's worthy of note. The Z axis is consistent between Matlab
% and Polyscope

% Giving a positive X in Matlab results in a negative X in Polyscope. 
% A positive X in MATLAB correlates to the desired area for the current 
% test setup. 
% ===========================

function [result, state] = MoveToPose(IP, position, eulerangles, move_time)

%ur = urRTDEClient('192.168.1.10','CobotName','universalUR5')
ur = urRTDEClient(IP,'CobotName','universalUR5');

ur5 = loadrobot("universalUR5");

% Generate Vector of current joint angles on arm. 
jointAnglesrad = readJointConfiguration(ur);

% Re-write the homeConfiguration joint angles to the desired angles. This
% allows us to use an existing structure for the robot configuration
% instead of creating a new one. 
jointConfig = homeConfiguration(ur5);
for j = 1:length(jointAnglesrad)
    jointConfig(j).JointPosition = (jointAnglesrad(1, j));
end

% Right Shoulder, Underhand
% ur5.Bodies{3}.Joint.PositionLimits = [-210, -130 ]*pi/180; %  80 degree range, Base 
% ur5.Bodies{4}.Joint.PositionLimits = [-160, -40 ]*pi/180;  % 120 degree range, Shoulder 
% ur5.Bodies{5}.Joint.PositionLimits = [-200, -40 ]*pi/180;  % 160 degree range, Elbow 
% ur5.Bodies{6}.Joint.PositionLimits = [-360, -80 ]*pi/180;  % 280 degree range, Wrist_1 
% ur5.Bodies{7}.Joint.PositionLimits = [ 180, 360 ]*pi/180;  % 180 degree range, Wrist_2 
% ur5.Bodies{8}.Joint.PositionLimits = [-360, 0 ]*pi/180;    % 360 degree range, Wrist_3 

if eulerangles(1) == 0
    % Left Shoulder, Underhand %%%%%
    ur5.Bodies{3}.Joint.PositionLimits = [-100,  80 ]*pi/180;  % 180 degree range, Base
    ur5.Bodies{4}.Joint.PositionLimits = [-160, -40 ]*pi/180;  % 120 degree range, Shoulder
    ur5.Bodies{5}.Joint.PositionLimits = [  40, 165 ]*pi/180;  % 125 degree range, Elbow
    ur5.Bodies{6}.Joint.PositionLimits = [-180, 120 ]*pi/180;  % 280 degree range, Wrist_1
    ur5.Bodies{7}.Joint.PositionLimits = [ -10, 180 ]*pi/180;  % 180 degree range, Wrist_2
    ur5.Bodies{8}.Joint.PositionLimits = [-180, 180 ]*pi/180;  % 360 degree range, Wrist_3
else
    % % Left Shoulder, Underhand %%%%% %% HORIZONTAL PLANE
    ur5.Bodies{3}.Joint.PositionLimits = [-100,  80 ]*pi/180;  % 180 degree range, Base
    ur5.Bodies{4}.Joint.PositionLimits = [-160, -40 ]*pi/180;  % 120 degree range, Shoulder
    ur5.Bodies{5}.Joint.PositionLimits = [  40, 165 ]*pi/180;  % 125 degree range, Elbow
    ur5.Bodies{6}.Joint.PositionLimits = [-180, 80 ]*pi/180;  % 280 degree range, Wrist_1
    ur5.Bodies{7}.Joint.PositionLimits = [ -30, 180 ]*pi/180;  % 180 degree range, Wrist_2
    ur5.Bodies{8}.Joint.PositionLimits = [-180, 180 ]*pi/180;  % 360 degree range, Wrist_3
end

% ur5.Bodies{3}.Joint.PositionLimits = [-100,  45 ]*pi/180;  % 180 degree range, Base 
% ur5.Bodies{4}.Joint.PositionLimits = [-160, -70 ]*pi/180;  % 120 degree range, Shoulder 
% ur5.Bodies{5}.Joint.PositionLimits = [  70, 160 ]*pi/180;  % 125 degree range, Elbow 
% ur5.Bodies{6}.Joint.PositionLimits = [ -170,120 ]*pi/180;  % 280 degree range, Wrist_1 
% ur5.Bodies{7}.Joint.PositionLimits = [   0,  90 ]*pi/180;  % 180 degree range, Wrist_2 
% ur5.Bodies{8}.Joint.PositionLimits = [-180, 180 ]*pi/180;  % 360 degree range, Wrist_3 


% Left Shoulder, Overhand
% ur5.Bodies{3}.Joint.PositionLimits = [ -100, 80 ]*pi/180;  % 160 degree range, Base 
% ur5.Bodies{4}.Joint.PositionLimits = [-160, -40 ]*pi/180;  % 120 degree range, Shoulder 
% ur5.Bodies{5}.Joint.PositionLimits = [  40, 155 ]*pi/180;  % 115 degree range, Elbow 
% ur5.Bodies{6}.Joint.PositionLimits = [-160,  60 ]*pi/180;  % 200 degree range, Wrist_1 
% ur5.Bodies{7}.Joint.PositionLimits = [ 180, 360 ]*pi/180;  % 180 degree range, Wrist_2 
% ur5.Bodies{8}.Joint.PositionLimits = [-360,   0 ]*pi/180;  % 360 degree range, Wrist_3 

% Specify desired [X Y Z] coordinates of end effector in vector
%position = [0.25 -0.1  0.375];



% Specify orientation of end effector in Euler Angles (in radians)
%eulerangles = [0 3*pi/4 pi/4]; % ZYZ Euler rotation order

TFmatrix = GenTFMatrix(position, eulerangles)

% Create Inverse Kinematics solver using the ur5 RigidBodyTree model we
% created earlier
ik = inverseKinematics("RigidBodyTree",ur5, SolverAlgorithm="LevenbergMarquardt");

% Set all weights to 1 to ensure that none of the Axes or angles are
% disregarded. 
weights = [1 1 1 1 1 1];

% Use the joint configuration created earlier as the initial guess/starting
% position in the IK solver.  
initialguess = jointConfig;

% Run the IK solver using the Transformation Matrix, Weights, and starting
% point. 
[configSoln,solnInfo] = ik("tool0",TFmatrix,weights,initialguess);

% Use the UR5 RigidBodyTree model to plot a visualization of the arm using
% the final joint angles.
figure(Name = 'End Pose Preview')
show(ur5,configSoln,PreservePlot=false);
title("Pose Preview")

% Pull Joint Angles out of IK Solution, then put joint angles into a vector
SolnJointAngles = zeros(1, 6);
for a = 1:6
    SolnJointAngles(a) = configSoln(a).JointPosition;
end

SolnJointAnglesDegrees = SolnJointAngles.*180/pi


% % set as configurable input?
% prompt = 'Is pose OK? (y/n): ';
% x = input(prompt, 's');
% 
% if x == 'y'
%     pass = true;
% else
%     clear SolnJointAngles
%     clear ur
%     close
% end

% Send solution joint angles to robot or URSim
[result,state] = sendJointConfigurationAndWait(ur,SolnJointAngles,'EndTime',move_time)

clear ur

