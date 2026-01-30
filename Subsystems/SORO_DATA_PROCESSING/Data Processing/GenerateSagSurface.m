
function [SagSurface, max_sag, min_sag] = GenerateSagSurface(Actuator, Vacuum)
% Actuator = 'Hainsworth_95A'
% Vacuum = true

if Vacuum == true
    dataset_vert = append(Actuator, '_multipose_vac');
    dataset_horiz = append(Actuator, '_multipose_horizontal_vac');
elseif Vacuum == false
    dataset_vert = append(Actuator, '_multipose_novac');
    dataset_horiz = append(Actuator, '_multipose_horizontal_novac');
end

file1MatFile = strcat(dataset_horiz, '_MeasuredBendAngles.mat');
matStruct = load(file1MatFile); 
horiz = matStruct.Test_data;

file2MatFile = strcat(dataset_vert, '_MeasuredBendAngles.mat');
matStruct = load(file2MatFile); 
vert = matStruct.Test_data;

% analyze data sets 

sz_H = size(horiz);
in_pres_H = horiz(:, 1);
ee_angles_H = (horiz(:, 2));
bend_angles_H = horiz(:, 3);

sz_V = size(vert);
in_pres_V = vert(:, 1);
ee_angles_V = (vert(:, 2));
bend_angles_V = vert(:, 3);

% Find average sag for input pressure in horizontal case, then make a
% matrix with the same number of entries as vertical case. 
unique_pres = unique(in_pres_V);
bend_angles_H_mat = reshape(bend_angles_H, [length(unique_pres), length(bend_angles_H)/length(unique_pres)]);
avg_bend = mean(bend_angles_H_mat, 2);
avg_bend_surface = avg_bend.*ones(length(unique_pres) , length(unique(ee_angles_V)));

% find indices of middle wedge
index_start = (sz_V(1) - sz_H(1))/2; 
index_interest = index_start+1:index_start+sz_H(1);

% Subtract Horizontal bend angles from Vertical 
ang_interest = bend_angles_V(index_interest);
difference = bend_angles_V-reshape(avg_bend_surface, length(bend_angles_V), 1);
mean_VAC = mean(difference)
var_vac = var(difference)
mean_VAC * 180/pi

max_sag = max(difference);
min_sag = min(difference);

% Sag decreases slightly as pressure increases, but decreases more
% substantially as ee_orientation increases

% fit surface to difference
SagSurface = fit([in_pres_V, ee_angles_V], difference, 'poly23');

% some_plane 
x_range = linspace(min(in_pres_V), max(in_pres_V), 1000);
y_range = linspace(min(ee_angles_V), max(ee_angles_V), 1000);
[X, Y] = meshgrid(x_range, y_range);
Z = SagSurface(X, Y);
coeffs1 = coeffvalues(SagSurface);

end