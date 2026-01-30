%% addSOROpaths
% 
% Date: 8/27/2025
% Inputs:
%   Requires the MATLAB path to be set to the folder that addSOROpaths.m
%   resides in. All SORO directories from the git repo should also be in 
%   this folder.
%
% Output:
%   PathsAdded - string array that contains the file path for every folder
%   added to MATLAB file path
% 
% Objective: short script to automatically add folders and their subfolders
% into the MATLAB path. This allows a user to call all helper functions
% used in the SORO test process while also allowing these functions to be
% grouped by their major functions. Almost all SORO testing with the system
% as designed will need to start by calling this function and making the
% other functions available. 

function PathsAdded = addSOROpaths()
    format compact
    
    % addpath(genpath(pwd)) % add all folders in repository

    mainPath = string(pwd);

    helperFunctionTests = append(mainPath, "\FunctionTests");
    genUtility = append(mainPath, "\General Utility");
    notesAndDev = append(mainPath, "\Notes and Development");
    calibImageStorage = append(mainPath, "\Images");
    SORO_characterization = append(mainPath, "\Soft Actuator Characterization Tests");
    figures = append(mainPath, "\Figures");
    sub = append(mainPath, "\SubSystems");
    testData = append(mainPath, "\Test Data");
    

    PathsToAdd = [helperFunctionTests;
        genUtility;
        notesAndDev;
        calibImageStorage;
        SORO_characterization;
        figures;
        sub;
        testData];

    PathsAdded = string(zeros(length(PathsToAdd), 1));

    for i = 1:length(PathsToAdd)
        addpath(PathsToAdd(i)) % adds folder to path
        addpath(genpath(PathsToAdd(i))) % adds all subfolders in folder to path
        PathsAdded(i) = PathsToAdd(i);
    end

end



