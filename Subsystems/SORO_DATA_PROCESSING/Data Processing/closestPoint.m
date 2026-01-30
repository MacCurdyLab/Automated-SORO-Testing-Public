% 10.) ======
% function to find the closet point in a list (X, Y) to some given point
% (x, y)
% X = list of X coordinates for all points in list
% Y = list of Y coordinates for all points in list
function [ptx, pty] = closestPoint(x, y, X, Y)
    table = zeros(length(X), 3);
    % X
    % length(X)
    % Y
    % length(Y)
    for i = 1:length(X)
        table(i, 1) = X(i);
        table(i, 2) = Y(i);
        dist = dist_2pts(x, y, X(i), Y(i));
        table(i, 3) = dist;
    end

    sorted = sortrows(table, 3, "ascend");
    ptx = sorted(1, 1);
    pty = sorted(1, 2);
end