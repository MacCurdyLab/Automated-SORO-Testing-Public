%% Camera Identification

clear; clc; close all

cams = length(webcamlist);

othercams = [];
for i = 1:cams 
    figure()
    cam = webcam(i);
    img = snapshot(cam);
    imshow(img)

    title(append('CAMERA NUMBER ', num2str(i), ' : WHICH CAMERA IS IT?'))
        
    qualityQuestion = 'WHICH CAMERA TOOK THE SHOWN IMAGE? (f - FRONT, t - TOP, n - OTHER) ';
    answer = input(qualityQuestion, 's');

    if answer == 'f'
        FrontCam = i;
    elseif answer == 't'
        TopCam = i;
    else
        othercams = [othercams; i];
    end

end

FrontCam
TopCam
othercams;

CamList = [FrontCam, TopCam]

