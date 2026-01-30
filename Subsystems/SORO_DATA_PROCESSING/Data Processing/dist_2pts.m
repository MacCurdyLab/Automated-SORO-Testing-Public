% 1.) ======
% function to find cartesian distance between 2 points
% (x1, y1) = X, Y coordinates of first point
% (x2, y2) = X, Y coordinates of second point
function dist = dist_2pts(x1, y1, x2, y2)
    dist = sqrt( (x2-x1)^2 + (y2-y1)^2 );
end