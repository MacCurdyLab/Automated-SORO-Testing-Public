%% TiftoGif
% 
% Date: 5/28/2025
% Inputs:
%   tifFile - String, filename of the file to convert (i.e.: 'filename.tif')
%   frametime - integer/float, how long each frame will display in seconds
%   reverse - boolean true/false. reverse = true will play the frames in
%   reverse after the last frame is reached. false will make frames play
%   from beginning to end only. 
%
% Output:
%   gifFile - .gif file that animates all the frames in a .tif file 
% 
% Objective: Function to play all frames of a .tif file as an animation.
% Useful for presenting information. 

function gifFile = TiftoGif(tifFile, frametime, reverse)

num_images = size(imfinfo(tifFile), 1);
%frametime = (framerate)^-1;

if reverse == false 
    entries = 1:num_images;
elseif reverse == true 
    entries = [1:num_images num_images:-1:1];
end

for j = 1:length(entries)
    frame = imread(tifFile, entries(j));
    [A,map] = rgb2ind(frame,256);
    
    if j == 1
        % Prepare location for file to save
        Path = pwd;
        extension = '\Images\';

        % Remove.tif from file name
        fileTitle = erase(tifFile, '.tif');
        
        % add ".gif" to the file name
        newFileTitle = strcat(fileTitle, '.gif');

         % complete file path and save to path
        file_location = strcat(Path, extension, newFileTitle);

        imwrite(A,map, file_location, "gif", LoopCount=Inf, DelayTime=frametime)
    else
        imwrite(A,map, file_location, "gif", WriteMode="append", DelayTime=frametime)
    end
end 

gifFile = newFileTitle;

end % function