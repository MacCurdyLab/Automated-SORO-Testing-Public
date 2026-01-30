% Multiple orders of R, T fits

%% Actuator Polar Fits 
clear; clc; close all

orders = 2:2:10;
fontsize = 14;
% orders = 4

keepoutList = {'.', '..', 'AAAAA Images', 'Calibration Functions', 'Figures', ...
    'Hainsworth_85A', 'Hainsworth_95A', 'Hainsworth_Inconsistent_95A', 'Hainsworth_staircase_95A', ...
    'Hainsworth_Banded_95A', 'Yap_95A', 'Keong_95A', 'Tawk_85A', 'Peele_95A', 'Wan_85A', ...
    'Gunawardane_T4_85A_4' 'Hainsworth_calib_test', 'ManualImagingTest', 'TestActuator', 'Sarkar_95A' ...
    'Hainsworth_Banded_95A_Speedrun', 'Hainsworth_Staircase_95A_2'
    };

directory_instance = dir('Test Data');
file_names = {directory_instance.name};

Actuators = []

for i = 1:length(file_names)
    isNotInList = ~ismember(file_names{i}, keepoutList);
    if isNotInList == 1
        Actuators = [Actuators, string(file_names(i))];
    end
end

length(Actuators)
transpose(Actuators)

%% actual actuator points
Marker_Diameter = 6.35;
% Actuators = ["Hainsworth_85A", "Hainsworth_95A", "Hainsworth_Inconsistent_95A", "Hainsworth_Staircase_95A", "Hainsworth_Banded_95A", "Yap_95A", "Keong_95A", "Tawk_85A", "Peele_95A", "Wan_85A"];
% act_lens = [63, 63, 72, 63, 63, 143.5, 154, 91, 67, 29]
% 
% Actuators = ["Yap_95A", "Keong_95A", "Tawk_85A", "Peele_95A", "Wan_85A"];
% act_lens = [143.5, 154, 91, 67, 29]
% 
% Actuators = ["Keong_95A"];
% act_lens = [154]

Actuators = ["Keong_95A_4" ,   "Peele_95A_2",    "Peele_95A_3",    "Peele_95A_4",    "Tawk_85A_2",    "Tawk_85A_3",    "Tawk_85A_4",    "Wan_85A_2",    "Wan_85A_3", "Yap_95A_2",    "Yap_95A_3",    "Yap_95A_4"]

lengthSorter = ["Dilibal", "Gunawardane", "Banded", "Inconsistent", "Staircase", "Keong", "Peele", "Tawk", "Wan", "Yap"] 
% if actuator name does not contain one of these strings, it is assumed to
% be a normal Hainsworth Actuator with a length of 63 mm. 
act_lens = [70, 70, 63, 72, 63, 154, 67, 91, 29, 143.5]

act_lens = ones(size(Actuators)) * 63;   % default if no match

for k = 1:numel(lengthSorter)
    mask = contains(Actuators, lengthSorter(k));
    act_lens(mask) = act_lens(k);
end

table = [];


for A = 1:length(Actuators)
    Actuator = Actuators(A);

    if Actuator == "Wan_85A"
        Marker_Diameter = Marker_Diameter/2;
    end

    %%%% Refactor to use stacked horizontal images to estimate actuator points.
    %%%% Refactor to rotate by whatever minimizes error

    extra = "_multipose_horizontal_vac";
    Images = strcat(Actuator, extra, '_NA_TestImgs.tif');

    % find markers on every frame of .tif file
    [ImgProcessed, positionCellArray, pixels_per_mm] = ProcessTIFImage(Images, Marker_Diameter, Actuator, 'Top', 300);

    % Separate Datum from other points
    [AllDatumPTs_Horiz, SortedPoints_cell] = DatumDetector(Images, ImgProcessed, positionCellArray, pixels_per_mm, 1);

    % convert measured points to real coordinates
    all_meas_pts = cell(length(SortedPoints_cell), 1);
    for i = 1:length(SortedPoints_cell)
        % gather real point data

        all_meas_pts{i} = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);
    end

    %% load input pressures from test data
    PressureMatFile = strcat(Actuator, extra, '_inputPressures.mat');
    matStruct = load(PressureMatFile);
    input_pressures = matStruct.AllInputPressures;
    max_pressure = max(input_pressures);
    unique_pres = unique(input_pressures);

    horizTest = append(erase(Images, '_NA_TestImgs.tif'), '_ArmOrientations.mat');
    matStruct = load(horizTest);
    Horiz_angles = matStruct.ee_angles(:, 1);
    unique_angles = unique(Horiz_angles);


    %% NEW

    all_est_pts = cell(length(unique_angles), 1);
    all_meas_pts_exp = cell(length(input_pressures), 1);
    all_horiz_X = zeros(length(SortedPoints_cell{1}), length(unique_pres), length(unique_angles));
    all_horiz_Y = all_horiz_X;
    unique_h_angles = unique(Horiz_angles);
    % rotate points from horizontal images to overlap, then find the average of
    % each point along the actuator for each inflation state.
    for i = 1:length(SortedPoints_cell)
        % gather real point data
        Horiz_pts = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);

        fix((i-1)/length(unique_pres));

        angle = Horiz_angles(i) - pi/4 - abs(2*(unique_h_angles(1)-unique_h_angles(2)))*fix((i-1)/length(unique(input_pressures)));
        [xr, yr] = Rotate(Horiz_pts(:, 1), Horiz_pts(:, 2), angle);

        column = mod(i, length(unique_pres));
        if column == 0
            column = max(length(unique_pres));
        end
        page = fix((i-1)/length(unique_pres)) + 1;
        all_horiz_X(:, column, page) = xr;
        all_horiz_Y(:, column, page) = yr;

        if i == length(SortedPoints_cell)
            mean_x = mean(all_horiz_X, 3);
            mean_y = mean(all_horiz_Y, 3);
            sz_mean_x = size(mean_x);

            for aa = 1:sz_mean_x(2)
                all_est_pts{aa} = [mean_x(:, aa), mean_y(:, aa)];
            end

        end
        % store experimental data for bend angle calculations
        all_meas_pts_exp{i} = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);
    end
    num_segments = length(SortedPoints_cell{1})-1;
    allCurves = NaturalCubicSplineFit(all_est_pts, num_segments, strcat(Actuator, '_multipose_horizontal_vac') );
    % allCurves_Horiz_exp = NaturalCubicSplineFit(all_meas_pts_exp, num_segments, strcat(Actuator, '_multipose_horizontal_vac') );
    % fit splines to sorted points
    num_segments = length(SortedPoints_cell{1})-1;
    % allCurves = NaturalCubicSplineFit(all_est_pts, num_segments, Actuator);


    %% Prepare Ray and Theta functions
    all_errs = zeros(1, length(orders));
    for ord_index = 1:length(orders)

        RAYS_ORDER = orders(ord_index);
        THETA_ORDER = orders(ord_index);

        odd_indices = 1:2:length(allCurves{1}.coefs);
        even_indices = 2:2:length(allCurves{1}.coefs);
        segments = 1:(allCurves{1}.pieces);
        all_r = [];
        all_theta = [];

        for i = 1:length(allCurves)
            thisCurve = allCurves{i};

            % gather real point data
            meas_pts = all_est_pts{i};

            % measure maximum value of theta needed to plot spiral (in polar
            % coordinates)
            end_angle = atan2( meas_pts(end, 2), meas_pts(end, 1) );
            if end_angle < 0
                end_angle = end_angle + 2*pi;
            end

            % evaluate spline curves at numerous points to create rays.
            all_x = [];
            all_y = [];

            for ia = 1:(length(thisCurve.coefs)/2)
                t_eval = linspace(0, thisCurve.breaks(ia+1)-thisCurve.breaks(ia), 50);
                y_poly = poly2sym( thisCurve.coefs( even_indices(ia), :) );
                y_eval = double(subs(y_poly, t_eval));

                x_poly = poly2sym( thisCurve.coefs( odd_indices(ia), :) );
                x_eval = double(subs(x_poly, t_eval));

                % remove repeated ray lengths
                x_eval(1) = [];
                y_eval(1) = [];

                all_x = [all_x; x_eval'];
                all_y = [all_y; y_eval'];

            end

            % measure cartesian distance from origin to spline (these are our ray
            % magnitudes)
            rays = zeros(length(all_x), 1);
            for ib = 1:length(all_x)
                rays(ib) = dist_2pts(all_x(ib), all_y(ib), 0, 0);
            end

            % measure angle theta to every point along spline
            thetas = zeros(length(all_x), 1);
            for ic = 1:length(all_x)
                theta = atan2(all_y(ic), all_x(ic));
                if theta < 0
                    theta = theta + 2*pi;
                end
                thetas(ic) = theta;
            end

            % fit function to ray length along actuator (as a percentage of length
            % along actuator)
            d = (0:(1/(length(rays)-1)):1 );
            ray_function = polyfit(d, rays, RAYS_ORDER);

            % fit function to theta along actuator
            theta_function = polyfit(d, thetas, THETA_ORDER);

            % estimate length of actuator based on breaks
            breaks_reduced = [];
            for id = segments
                this_break = thisCurve.breaks(id+1)-thisCurve.breaks(id);
                breaks_reduced = [breaks_reduced; this_break];
            end
            est_len = sum(breaks_reduced.^2);

            % save all coeffs
            all_r = [all_r; ray_function];
            all_theta = [all_theta; theta_function];
            % save measured attributes in curve struct
            thisCurve.EndAngle = end_angle;
            thisCurve.EstimatedLength = est_len;
            thisCurve.RayCoeffs = ray_function;
            thisCurve.ThetaCoeffs = theta_function;
            thisCurve.Rays = rays;
            thisCurve.Thetas = thetas;
            allCurves{i} = thisCurve;

        end

        %% pressure predicitive spiral
        % second order
        Ray_coeffs = zeros(RAYS_ORDER+1, 3);
        for q = 1:RAYS_ORDER+1
            r_coeffs = polyfit(unique_pres, all_r(:, q), 2);
            Ray_coeffs(q, 1) = r_coeffs(1);
            Ray_coeffs(q, 2) = r_coeffs(2);
            Ray_coeffs(q, 3) = r_coeffs(3);
        end


        Theta_coeffs = zeros(THETA_ORDER+1, 3);
        for g = 1:THETA_ORDER+1
            theta_coeffs = polyfit(unique_pres, all_theta(:, g), 2);
            Theta_coeffs(g, 1) = theta_coeffs(1);
            Theta_coeffs(g, 2) = theta_coeffs(2);
            Theta_coeffs(g, 3) = theta_coeffs(3);
        end


        % % function to evaluate coefficients at P_in
        % function [real_ray_length_coeff, real_theta_coeff] = Evaluate_ray(P_in, Ray_coeffs, Theta_coeffs)
        %     asize = size(Ray_coeffs);
        %     Pins = zeros(1, asize(2));
        %     for i = 1:length(Pins)
        %         Pins(i) = P_in^(length(Pins) - i);
        %     end
        %
        %     % evaluate coefficients at P_in
        %     raycoeffs = Ray_coeffs.* Pins;
        %     thetacoeffs = Theta_coeffs  .* Pins;
        %
        %     % add rows together, return column vector of sums
        %     real_ray_length_coeff = sum(raycoeffs, 2);
        %     real_theta_coeff = sum(thetacoeffs, 2);
        % end

        compare_pressures = unique_pres;
        %% plot compare pressures next to real input data
        figure()
        dimensionless = linspace(0, 1, 1000);
        % color map
        cmap2 = turbo(length(compare_pressures));
        colormap(cmap2);
        errors = zeros(length(compare_pressures), 2);
        title(num2str(orders(ord_index)), 'FontSize', fontsize)

        for aa = 1:length(compare_pressures)
            % find necessary coefficients
            P_in = compare_pressures(aa);
            [ray_length_coeff, theta_coeff] = FindPolarCoefficients(P_in, Ray_coeffs, Theta_coeffs);

            rays = polyval(ray_length_coeff, dimensionless);
            angles = polyval(theta_coeff, dimensionless);

            x_predicted = rays.*cos(angles);
            y_predicted = rays.*sin(angles);
            x_predicted = x_predicted - x_predicted(1);
            y_predicted = y_predicted - y_predicted(1);
            plot(x_predicted, y_predicted, 'color', cmap2(aa, :), 'DisplayName', append(string(compare_pressures(aa)), ' psi') )
            hold on
            axis equal
            grid on
            colorbar('Ticks',[0, 1], 'TickLabels',{'0 psi', append(num2str(max_pressure), ' psi') })
            title(append(strrep(Actuator, '_', ' '), ', Order of Fit: ', num2str(orders(ord_index))  ), 'FontSize', fontsize)
            % legend

            new_pressures = sort([unique_pres, compare_pressures(aa)]);
            pres_index = find(new_pressures == compare_pressures(aa));

            pts1 = all_est_pts{pres_index(1)};
            scatter(pts1(:, 1), pts1(:, 2), 'filled', 'MarkerFaceColor', cmap2(aa, :), 'MarkerEdgeColor', 'k', 'DisplayName', append(string(compare_pressures(aa)), ' psi, Measured Data') )

            errors(aa, 1) = dist_2pts(x_predicted(end), y_predicted(end), pts1(end, 1), pts1(end, 2));
            errors(aa, 2) = (errors(aa, 1)/est_len *100);

        end
        ylabel('millimeters')
        xlabel('millimeters')
        

        ax = gcf;
        exportgraphics(ax, append(pwd, '\Test Data\Figures\', Actuators(A), num2str(orders(ord_index)), '_OrderRTfits.pdf'))

        errors;
        Ray_coeffs;
        RAYS_ORDER;
        Theta_coeffs;
        THETA_ORDER;

        compare = linspace(0, 1, length(all_est_pts{1}));
        all_SP_errors = zeros(length(all_est_pts), 1);

        %% SSE between actuator at all Measured Pressures and predicted actuator profile at same pressures
        for ba = 1:length(all_est_pts)
            P_in = input_pressures(ba);
            [ray_length_coeff, theta_coeff] = FindPolarCoefficients(P_in, Ray_coeffs, Theta_coeffs);

            rays = polyval(ray_length_coeff, compare);
            angles = polyval(theta_coeff, compare);

            x_predicted = rays.*cos(angles);
            y_predicted = rays.*sin(angles);
            x_predicted = x_predicted - x_predicted(1);
            y_predicted = y_predicted - y_predicted(1);

            distances = zeros(length(x_predicted)-1, 1);
            for baa = 1:length(x_predicted)-1
                distances(baa) = sqrt( (x_predicted(baa)-x_predicted(baa+1))^2 + (y_predicted(baa)-y_predicted(baa+1))^2 );
            end
            est_len = sum(distances);

            x_real = all_est_pts{ba}(:, 1);
            y_real = all_est_pts{ba}(:, 2);

            errors = zeros(length(x_real), 1);

            for baa = 1:length(x_real)
                errors(baa) = dist_2pts(x_real(baa), y_real(baa), x_predicted(baa), y_predicted(baa))^2; % /(est_len*length(errors));
            end

            all_SP_errors(ba) = (1/length(x_real)) * sqrt(sum(errors));

        end

        all_SP_errors
        mean(all_SP_errors)
        var(all_SP_errors)

        %% other Error Methods

        % r
        dimensionless = linspace(0, 1, 1000);
        error_dists = zeros(length(all_est_pts), length(all_est_pts{1}));
        frame_errors = 0;
        for ba = 1:length(all_est_pts)
            P_in = input_pressures(ba);
            [ray_length_coeff, theta_coeff] = FindPolarCoefficients(P_in, Ray_coeffs, Theta_coeffs);

            rays = polyval(ray_length_coeff, dimensionless);
            angles = polyval(theta_coeff, dimensionless);

            x_predicted = rays.*cos(angles);
            y_predicted = rays.*sin(angles);
            x_predicted = x_predicted - x_predicted(1);
            y_predicted = y_predicted - y_predicted(1);

            distances = zeros(length(x_predicted)-1, 1);
            for baa = 1:length(x_predicted)-1
                distances(baa) = sqrt( (x_predicted(baa)-x_predicted(baa+1))^2 + (y_predicted(baa)-y_predicted(baa+1))^2 );
            end
            est_len = sum(distances);

            x_real = all_est_pts{ba}(:, 1);
            y_real = all_est_pts{ba}(:, 2);

            errors = zeros(length(x_real), 1);

            % build Error dist matrix
            closest_x = zeros(length(x_real), 1);
            closest_y = zeros(length(y_real), 1);
            for baa = 1:length(x_real)
                [closest_x(baa), closest_y(baa)] = closestPoint(x_real(baa), y_real(baa), x_predicted, y_predicted);

                % errors(baa) = dist_2pts(x_real(baa), y_real(baa), x_predicted(baa), y_predicted(baa))^2; % /(est_len*length(errors));

                error_dists(ba, baa) = dist_2pts(x_real(baa), y_real(baa), closest_x(baa), closest_y(baa));
            end

            % figure(1); hold on
            % scatter(closest_x, closest_y)
            % frame_error = 1/(num_entries) * sqrt(sum(frame_error_dists))

        end

        error_frames = sum(error_dists, 2);
        num_kept = round(0.75*length(all_est_pts{1}), 0);
        % keeps = [13, 13, 13, 13, 12, 12, 12, 12, 12, 11, 11, 11, 11, 11, 10, 10, 10, 10, 10, 9, 9, 9, 9, 9]
        keeps = length(SortedPoints_cell{1});
        for p = 1:length(keeps)
            num_kept = keeps(p);
            all_col_errors = zeros(length(all_est_pts), 1);
            some_col_errors = zeros(length(all_est_pts), 1);

            N = length(error_dists(1,:));
            all = size(error_dists);
            frames = 1:all(1);
            points = 1:all(2);
            r = sort([1, (randperm(all(2)-1, num_kept-1))+1]);
            % r = [1     2     3     5     7     8     9    11    13    14]
            % r = [1     2     3     4     6     7     9    10];

            for frame = 1:length(all_est_pts)
                arb_frame = frame;
                new_errors = error_dists(arb_frame, :);
                squared_errors = new_errors.^2;

                SSE = sum(squared_errors);
                error_metric_ALL_COLUMNS = sqrt(SSE/N);
                all_col_errors(frame) = error_metric_ALL_COLUMNS;
                % for every frame, add error_metric?

                % r = sort([1, (randperm(all(2)-2, num_kept-2))+2]);
                reduced_errors = zeros(length(all_est_pts), num_kept);
                for row = frames
                    for column = 1:length(r)
                        reduced_errors(row, column) = error_dists(row, r(column));
                    end
                end

                M = num_kept;
                errors2 = reduced_errors(arb_frame, :);
                squared_errors2 = errors2.^2;

                SSE2 = sum(squared_errors2);
                error_metric2_SOME_COLUMNS = sqrt(SSE2/M);
                some_col_errors(frame) = error_metric2_SOME_COLUMNS;

            end

            r
            sum_ERROR_all_col = sum(all_col_errors)
            sum_ERROR_some_col = sum(some_col_errors)

            percent_different = abs(sum_ERROR_all_col-sum_ERROR_some_col)/((sum_ERROR_all_col+sum_ERROR_some_col)/2)*100

        end

        act_len = act_lens(A)


        [ERROR] = PredictionError(error_dists, act_len)

        % mean(mean(error_dists(:, 2:end)))


        %
        %% fit new spline to predicted data points to find tangents
        dimensionless = linspace(0, 1, 1000);
        % color map
        cmap2 = winter(length(compare_pressures));
        colormap(cmap2);
        errors = zeros(length(compare_pressures), 2);

        predicted_coords = cell(length(allCurves), 1);
        for aac = 1:length(allCurves)
            % find necessary coefficients
            P_in = input_pressures(aac);
            [ray_length_coeff, theta_coeff] = FindPolarCoefficients(P_in, Ray_coeffs, Theta_coeffs);

            rays = polyval(ray_length_coeff, dimensionless);
            angles = polyval(theta_coeff, dimensionless);

            x_predicted = rays.*cos(angles);
            y_predicted = rays.*sin(angles);
            x_predicted = x_predicted - x_predicted(1);
            y_predicted = y_predicted - y_predicted(1);

            predicted_coords{aac} = [x_predicted', y_predicted'];

        end

        newCurves = NaturalCubicSplineFit(predicted_coords, 999);
        diffCurves = cell(length(allCurves), 1);

        curve_diff = fnder(newCurves{1});
        dimensionless = curve_diff.breaks(end) * linspace(0, 1, 1000);

        start_ish = dimensionless(:, 1:0.1*length(dimensionless));
        start_ish = zeros(length(dimensionless), 1);

        st_slopes = fnval(curve_diff, start_ish);

        mean_start_slope = sum(st_slopes, 2)/length(st_slopes);

        st_slope = mean_start_slope(2)/mean_start_slope(1);

        st_pt = fnval(newCurves{1}, 0);
        st_b = (st_pt(2) - st_slope*st_pt(1))

        bend_angles = FindBendAngles(Images, allCurves, num_segments, unique_pres, 1, false);

        bend_angles_degrees = bend_angles*180/pi;

        ERROR

        all_errs(ord_index) = ERROR';

    end

    all_errs
    table = [table; all_errs]
end

table = [Actuators', table]
Latex_String = MatrixToLatexMatrix(table)