% 6.) ======
% Rotate all points in list by some angle (rotation is about the origin)
% positive angle is CounterClockwise
function [xr, yr] = Rotate(X, Y, angle)
    R = [cos(angle), -sin(angle), 0;
         sin(angle),  cos(angle), 0;
         0, 0, 1];

    xr = zeros(length(X), 1);
    yr = zeros(length(Y), 1);

    for i = 1:length(X)
        pt = [X(i); Y(i); 1];

        new_pt = R * pt;
        
        xr(i) = new_pt(1);
        yr(i) = new_pt(2);
    end
end