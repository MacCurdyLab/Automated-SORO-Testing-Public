%% LJStream (Stream Data from LabJack)
% 
% Date: 7/8/2025
% Inputs:
%   channels - nx2 matrix of integers that describe channels to be
%   streamed (in first column) and their relevant excitation voltages (second column) 
%          Example: channels = [1, 10; 4, 10; 5, 1] for sensors on channel
%          1 and 4 that require 10 V excitation, and a sensor on channel 5
%          that requires 1V excitation. Note: channel rows do not need to be in
%          order, but each row needs to describe a single channel. 
%   scan_rate - integer, in Hz that describes desired scan rate  % number of samples instead?
%   step_time - integer/float, amount of time in seconds for stream to run
%   ljasm, ljerror, ljhandle, ljudObj - Labjack attributes, obtained from
%   InitializeLabJack.m
%
% Output:
%   Data - matrix, 'double'. with readings from every specified channel. each column
%   represents a different channel, in the order specified in channels
%   vector. 
%   actualDataRate - float, 'double'. how many total samples were gathered across all
%   channels per second
% 
% Objective: Script to start and stop data stream from labjack. assumes
% labjack was initialized already, takes LJ parameters as inputs

function [Data, actualDataRate] = LJStream(channels, scanRate, step_time, ljasm, ljerror, ljhandle, ljudObj)

dblCommBacklog = 0;
dblUDBacklog = 0;
numScans = step_time * scanRate;

try
    % % Read and display the UD version.
    % disp(['UD Driver Version = ' num2str(ljudObj.GetDriverVersion())])
    % 
    % % Open the first found LabJack U6.
    % [ljerror, ljhandle] = ljudObj.OpenLabJackS('LJ_dtU6', 'LJ_ctUSB', '0', true, 0);

    % Stop any previous stream.
    try
        ljudObj.eGet(ljhandle, 'LJ_ioSTOP_STREAM', 0, 0, 0);
    catch
    end
    
    % measure number of channels
    size_channels = size(channels); % if including excitation voltages, must include extra column and use size(channels) for number of rows

    % Configure the resolution of the analog inputs (pass a non-zero value for quick sampling).
    % See section 2.6 / 3.1 for more information.
    ljudObj.AddRequestSS(ljhandle, 'LJ_ioPUT_CONFIG', 'LJ_chAIN_RESOLUTION', 0, 0, 0);

    % Define the scan list from "channels" array
    % size_channels = length(channels); % if including ecitation voltages, must include extra column and use size(channels) for number of rows

    % Configure the analog input range on channels for bipolar +-10 volts (LJ_rgBIP10V).
    for j = 1:size_channels(1)
        excitation = channels(j, 2); % second column includes excitation voltages. 

        % Configure the analog input range based on required excitation
        % determine input_range
        if excitation == 0.01
            input_range = ljudObj.StringToConstant('LJ_rgBIPP01V');    % 1000x Gain +/- 0.01V
        elseif excitation == 0.1
            input_range = ljudObj.StringToConstant('LJ_rgBIPP1V');      % 100x Gain +/- 0.1V
        elseif excitation == 1
            input_range = ljudObj.StringToConstant('LJ_rgBIP1V');        % 10x Gain +/- 1V
        elseif excitation == 10
            input_range = ljudObj.StringToConstant('LJ_rgBIP10V');      % 1x Gain +/- 10V
        end
        % add request to LabJack Stream
        ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_AIN_RANGE', 0, input_range, 0, 0);
    end

    % for j = 1:size_channels(1)
    %     LJ_rgBIP10V = ljudObj.StringToConstant('LJ_rgBIP10V');
    %     ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_AIN_RANGE', 0, LJ_rgBIP10V, 0, 0);
    % end
    LJ_rgBIP10V = ljudObj.StringToConstant('LJ_rgBIP10V');
    ljudObj.AddRequestS(ljhandle, 'LJ_ioPUT_AIN_RANGE', 0, LJ_rgBIP10V, 0, 0);

    % Set the scan rate.
    ljudObj.AddRequestSS(ljhandle, 'LJ_ioPUT_CONFIG', 'LJ_chSTREAM_SCAN_FREQUENCY', scanRate, 0, 0);

    % Give the driver a buffer (scanRate * channels * seconds).
    buffer = scanRate*size_channels(1)*step_time;
    ljudObj.AddRequestSS(ljhandle, 'LJ_ioPUT_CONFIG', 'LJ_chSTREAM_BUFFER_SIZE', buffer*2, 0, 0);

    % Configure reads to retrieve whatever data is available with waiting.
    LJ_swSLEEP = ljudObj.StringToConstant('LJ_swSLEEP');
    ljudObj.AddRequestSS(ljhandle, 'LJ_ioPUT_CONFIG', 'LJ_chSTREAM_WAIT_MODE', LJ_swSLEEP, 0, 0);

    ljudObj.AddRequestS(ljhandle, 'LJ_ioCLEAR_STREAM_CHANNELS', 0, 0, 0, 0);

    % add requests to read specified channels
    for k = 1:size_channels(1)
        ljudObj.AddRequestS(ljhandle, 'LJ_ioADD_STREAM_CHANNEL', channels(k, 1), 0, 0, 0); % IMPORTANT
    end
    
    % Execute the list of requests.
    ljudObj.GoOne(ljhandle);

    % Get all the results just to check for errors.
    LJE_NO_MORE_DATA_AVAILABLE = ljudObj.StringToConstant('LJE_NO_MORE_DATA_AVAILABLE');
    finished = false;
    while finished == false
        try
            [ljerror, ioType, channel, dblValue, dummyInt, dummyDbl] = ljudObj.GetNextResult(ljhandle, 0, 0, 0, 0, 0);
        catch e
            if(isa(e, 'NET.NetException'))
                eNet = e.ExceptionObject;
                if(isa(eNet, 'LabJack.LabJackUD.LabJackUDException'))
                    % If we get an error, report it. If the error is
                    % LJE_NO_MORE_DATA_AVAILABLE we are done.
                    if(int32(eNet.LJUDError) == LJE_NO_MORE_DATA_AVAILABLE)
                        finished = true;
                    end
                end
            end
            % Report non NO_MORE_DATA_AVAILABLE error.
            if(finished == false)
                throw(e)
            end
        end
    end

    start = tic;
    % Start the stream.
    disp('Starting Stream')
    [ljerror, dblValue] = ljudObj.eGetS(ljhandle, 'LJ_ioSTART_STREAM', 0, 0, 0);

    % Get the enums for LJ_ioGET_STREAM_DATA and LJ_chALL_CHANNELS which we use
    % in the read stream data loop.
    typeIO = ljasm.AssemblyHandle.GetType('LabJack.LabJackUD.LJUD+IO');
    LJ_ioGET_STREAM_DATA = typeIO.GetEnumValues.Get(22);  % Use enum index for GET_STREAM_DATA 
    typeCHANNEL = ljasm.AssemblyHandle.GetType('LabJack.LabJackUD.LJUD+CHANNEL');
    LJ_chALL_CHANNELS = typeCHANNEL.GetEnumValues.Get(99);  % Use the enum index for ALL_CHANNELS
   
    % Init array to store data.
    adblData = NET.createArray('System.Double', size_channels(1)*numScans);  %Max buffer size (#channels*numScansRequested)

    % Read the data. The array we pass must be sized to hold enough SAMPLES,
    % and the Value we pass specifies the number of SCANS to read.
    numScansRequested = numScans;

    % Use eGetPtr when reading arrays in 64-bit MATLAB. Also compatible with
    % 32-bits.
    [ljerror, numScansRequested] = ljudObj.eGetPtr(ljhandle, LJ_ioGET_STREAM_DATA, LJ_chALL_CHANNELS, numScansRequested, adblData);

    %Convert the .NET datatype into a MATLAB array 
    Data = reshape(double(adblData),[size_channels(1),numScansRequested])';
    
    % Stop the stream
    ljudObj.eGetS(ljhandle, 'LJ_ioSTOP_STREAM', 0, 0, 0);

    disp('Done')
catch e
    showErrorMessage(e)
end
time = toc(start);
Datasize = size(Data);
% actualDataRate is the total number of samples retrieved (across all
% channels) divided by the time it takes for the program to run. 
actualDataRate = (Datasize(1) * Datasize(2))/time;

end