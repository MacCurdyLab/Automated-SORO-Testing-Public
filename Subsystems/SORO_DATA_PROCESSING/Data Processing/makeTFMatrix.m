% 8.) ======
% function to generate 2D transformation matrix between actuator base and tip,
% and all intermediate matrices. 
% uses list of angles between all points (each angle is the angle between X axis and line drawn between 2 points) and distances between all points
% as input. 
% this function is the critical part, it generates the transformation
% matrix from our startpoint to our endpoint. 
function [final_TF_matrix, all_TF_matrices] = makeTFMatrix(angles, distances)
    matrices = cell(length(angles), 1);
    for i = 1:length(angles)
        Ri = [cos(angles(i)), -sin(angles(i)), 0;
              sin(angles(i)),  cos(angles(i)), 0;
              0, 0, 1];
        Ti = [1, 0, distances(i);
              0, 1, 0;
              0, 0, 1];
        Ei = Ri * Ti;
        matrices{i} = Ei;
    end

    C = eye(3);
    for j = 1:length(angles)
        Ej = matrices{j};
        C = C * Ej;
    end
    all_TF_matrices = matrices;
    final_TF_matrix = C;
end