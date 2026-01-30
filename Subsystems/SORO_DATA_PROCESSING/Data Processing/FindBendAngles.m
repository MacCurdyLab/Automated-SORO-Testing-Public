



function [bend_angles, matFileLocation] = FindBendAngles(Images, allCurves, num_segments, input_pressures, moving_angle, save_data)

genericFile = erase(Images, '_NA_TestImgs.tif');
Actuator = erase(genericFile, '_multipose_horizontal_vac');
Actuator = erase(Actuator, '_multipose_vac');

arm_angMatFile = strcat(genericFile, '_ArmOrientations');
matStruct = load(arm_angMatFile);
ee_angles = matStruct.ee_angles(:, moving_angle);

pressure_settings = unique(input_pressures);
num_pressure_settings = length(pressure_settings);

positions = length(allCurves)/(num_pressure_settings);

rotated_points = cell(length(allCurves), 1);

% rotate splines so that the actuator bases align, regardless of
% orientation that images were taken in.
for j = 1:num_pressure_settings 
    % counter = 0;
    for k = 1:length(allCurves)

        if allCurves{k}.InputPressure == pressure_settings(j)
            % counter = counter +1;
            coeffs = allCurves{k}.coefs;
            breaks = allCurves{k}.breaks;
            points_per_segment = 25;

            [X, Y] = SplineCoeffEval_2D(coeffs, breaks, points_per_segment);

            angle = - ee_angles(k) + pi/4;
            [Xr, Yr] = Rotate(X, Y, angle);
            rotated_points{k} = [Xr, Yr];

        end

    end
end

%% find angle between lines tangent to tip and base for each frame. 
newCurves = NaturalCubicSplineFit(rotated_points, num_segments, genericFile);

X_all = [];
Y_all = [];

pieces = newCurves{1}.pieces;
points_per_segment = 25;

angles = zeros(length(newCurves), 1);
for a = 1:length(newCurves)
    coeffs = newCurves{a}.coefs;
    breaks = newCurves{a}.breaks;
    
    [X, Y] = SplineCoeffEval_2D(coeffs, breaks, points_per_segment);
    X_all = [X_all; X];
    Y_all = [Y_all; Y];

    % angles1 = zeros(length(X_all), 1);
    % for aa = 1:(length(X)-1)
    %     angle_iter = angle_2pts(X(aa), Y(aa), X(aa+1), Y(aa+1)) - sum(angles1);
    %     angles(a) = angle_iter;
    % end

end

base_x = X_all(1, 1) - X_all(1, round(0.1*length(X_all)));
base_y = Y_all(1, 1) - Y_all(1, round(0.1*length(Y_all)));
base_vec = [base_x, base_y];

bend_angles = zeros(length(newCurves), 1);
for b = 1:length(newCurves)
    tip_x = X_all(b, round(0.9*length(X_all))) - X_all(b, length(X_all));
    tip_y = Y_all(b, round(0.9*length(Y_all))) - Y_all(b, length(Y_all));

    tip_vec = [tip_x, tip_y];

    beta = acos( dot(base_vec,tip_vec)/(norm(base_vec) * norm(tip_vec) ) );

    % account for bend angles beyond 180 degrees. 
    if b ~= 1 
        if beta < bend_angles(b-1) && beta > pi/4
            beta = 2*pi - beta;
        end        
    end

    bend_angles(b) = beta;

end

if save_data == true
    length(input_pressures)
    length(ee_angles)
    length(bend_angles)
    
    Test_data = [input_pressures', ee_angles, bend_angles];
    
    matFileLocation = append(pwd, '\Test Data\', Actuator, '\MAT Files\');
    meas_matFileName = strcat(genericFile, '_MeasuredBendAngles');
    save(strcat(matFileLocation, meas_matFileName, '.mat'), 'Test_data')
else
    
    bend_angles = bend_angles;
end


end