%% Multiple Bend Angle Fits

clear; clc; close all


%% actual actuator points
Marker_Diameter = 6.35;
Actuators = ["Hainsworth_95A_1"];

act_lens = [63];

% Actuators = ["Hansell_Endo_30A"];
% 
% act_lens = [70]

all_errs = zeros(length(Actuators), 2);

syms xc yc;

for index = 1:length(Actuators)

    Actuator = Actuators(index);
    act_len = act_lens(index);

    if Actuator == "Wan_85A"
        Marker_Diameter = Marker_Diameter/2;
    end

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

    %% END NEW

    % fit splines to sorted points
    % num_segments = length(SortedPoints_cell{1})-1;
    % allCurves = NaturalCubicSplineFit(all_meas_pts, num_segments, Actuator);
    %
    num_frames = length(allCurves);
    num_markers = length(all_est_pts{1});

    %% Select some input pressure to use for comparison
    chosen = 5;
    P_in = unique_pres(chosen);

    %% BA 1 - Simple Endpoint Angle
    SE_angles = zeros(length(allCurves), 1);
    % points = cell(length(allCurves), 1);
    % init_angle = atan2(all_meas_pts{1}(end, 2), all_meas_pts{1}(end, 1));
    init_angle = 135 * pi/180;
    for j = 1:length(all_est_pts)
        SE_angle = atan2(all_est_pts{j}(end, 2), all_est_pts{j}(end, 1));
        if SE_angle < 0
            SE_angle = 2*pi + SE_angle;
        end
        SE_angles(j) = SE_angle - init_angle;

    end

    % generate fit that describes change in bend angle with respect to
    % pressure.
    SE_fit = polyfit(unique_pres, SE_angles, 2);

    radii = zeros(length(all_est_pts), 1);
    all_SE_errors = zeros(length(all_est_pts), 1);
    dot_angles = zeros(length(all_est_pts), 1);

    all_dists_SE = zeros(num_frames, num_markers);
    for ja = 1:length(all_est_pts)
        P_in = unique_pres(ja);

        est_Act_len = allCurves{ja}.EstimatedLength;
        t1 = polyval(SE_fit, P_in);

        X_se = [0, est_Act_len/t1 * sin(t1) * cos(t1)];
        Y_se = [0, est_Act_len/t1 * sin(t1) * sin(t1)];
        radius = est_Act_len / (2*t1);
        radii(ja) = radius;

        [X_se, Y_se] = Rotate(X_se, Y_se, 135*pi/180);
        % f_center = @(center) sqrt( (X_se - center(1)).^2 + (Y_se - center(2)).^2 ) - radius;
        % center_intitial = [mean(X_se), mean(Y_se)];
        % center_est = lsqnonlin(f_center, center_intitial);
        % returns 2 possible centers

        x_real = all_est_pts{ja}(:, 1);
        y_real = all_est_pts{ja}(:, 2);

        syms xc yc;
        e1 = (X_se(1)-xc)^2 + (Y_se(1)-yc)^2 == radius^2;
        e2 = (X_se(2)-xc)^2 + (Y_se(2)-yc)^2 == radius^2;

        [cenx, ceny] = solve([e1, e2], [xc, yc]);
        cenx = double(cenx);
        ceny = double(ceny);

        A = [x_real'; y_real'];
        % ID Coope method for fitting a circle
        % https://ir.canterbury.ac.nz/server/api/core/bitstreams/89e305b2-12b0-4156-ad16-1a5c7ce93bc9/content
        [n,m] = size(A);
        y = [A', ones(m, 1)]\sum(A.*A)';
        center = .5*y(1:n);

        % need to find some way to select correct center, and avoid using atan2
        % to find angles.
        % use both centers and select one with lowest error?
        center_est = [0; 0];
        [center_est(1), center_est(2)] = closestPoint(mean(x_real), mean(y_real), cenx, ceny);
        [center_est(1), center_est(2)] = closestPoint(center(1), center(2), cenx, ceny);

        cenx = round(cenx, 5);
        ceny = round(ceny, 5);
        cen = intersect(cenx, ceny);

        center_est = [cen; cen];
        V1 = [X_se(1); Y_se(1)] - [center_est];
        V2 = [X_se(2); Y_se(2)] - [center_est];
        angle = acos(dot(V1, V2) / (norm(V1) * norm(V2)));

        % if ja ~= 1
        %     if angle < dot_angles(ja-1)
        %         angle = 2*pi - angle;
        %     elseif abs(angle - dot_angles(ja-1)) < 2*pi/180
        %         angle = 2*pi - angle;
        %     end
        %
        % end

        dot_angles(ja) = angle;

        start = atan2((X_se(1) - center_est(2)), (X_se(1) - center_est(1)));
        % angle_end = start + angle;
        % angles = linspace(start, angle_end, length(all_meas_pts{1}));

        angles = linspace(start, t1*2+start, length(all_est_pts{1}));



        x_s1 = center_est(1) + radius * cos(angles);
        y_s1 = center_est(2) + radius * sin(angles);

        errors = zeros(length(x_s1), 1);
        for jaa = 1:length(x_s1)
            errors(jaa) = dist_2pts(x_real(jaa), y_real(jaa), x_s1(jaa), y_s1(jaa))/(est_Act_len*length(x_real) );
            % all_dists_SE(ja, jaa) = dist_2pts(x_real(jaa), y_real(jaa), x_s1(jaa), y_s1(jaa));
        end
        all_SE_errors1 = sum(errors);


        x_s2 = center_est(1) - radius * cos(angles);
        y_s2 = center_est(2) - radius * sin(angles);

        errors = zeros(length(x_s2), 1);
        for jaa = 1:length(x_s2)
            errors(jaa) = dist_2pts(x_real(jaa), y_real(jaa), x_s2(jaa), y_s2(jaa))/(est_Act_len*length(x_real) );
            % all_dists_SE(ja, jaa) = dist_2pts(x_real(jaa), y_real(jaa), x_s2(jaa), y_s2(jaa));
        end
        all_SE_errors2 = sum(errors);

        if all_SE_errors2 < all_SE_errors1
            all_SE_errors(ja) = all_SE_errors2;
            x_s = x_s2;
            y_s = y_s2;
        else
            all_SE_errors(ja) = all_SE_errors1;
            x_s = x_s1;
            y_s = y_s1;
        end

        for jaa = 1:length(x_s2)
            all_dists_SE(ja, jaa) = dist_2pts(x_real(jaa), y_real(jaa), x_s(jaa), y_s(jaa));
        end

    end

    figure()
    scatter(x_s, y_s, 'filled', 'green')
    axis equal, grid on, hold on
    % scatter(X_se, Y_se, '*')
    % scatter(center_est(1), center_est(2), '+', 'red')
    
    scatter(x_real, y_real, '*', 'b');
    for plotter = 1:length(x_s)
        wedge_y = [y_s(plotter), center_est(1)];
        wedge_x = [x_s(plotter), center_est(2)];
        plot(wedge_x, wedge_y, '-.r')
    end
    f_circle = @(x, y) (x-center_est(1)).^2 + (y-center_est(2)).^2 - radius^2;
    fimplicit(f_circle, [center_est(1)-radius-20, center_est(1)+radius+20, center_est(2)-radius-20, center_est(2)+radius+20], '--r')
    title(append(strrep(Actuator, '_', ' '), ', SE Bend Angle Fit ' ))
    ylabel('millimeters')
    xlabel('millimeters')
    legend('Predicted Points','Measured Points', 'Location', 'southeast')

    ax = gcf;
    exportgraphics(ax, append(pwd, '\Test Data\Figures\', Actuators(index), '_SEBendFit.pdf'))

    all_SE_errors;


    %% BA 2 - Distal Tangent Angle
    % measure angle between lines tangent to start and end of splines.

    %% find DTA of every spline
    DT_angles = zeros(length(allCurves), 1);
    % points = cell(length(allCurves), 1);
    % [bend_angles, matFileLocation] = FindBendAngles(Images, allCurves, num_segments, input_pressures, moving_angle, save_data)

    DT_angles = FindBendAngles(Images, allCurves, num_segments, input_pressures, 1, false)

    DT_fit = polyfit(unique_pres, DT_angles, 2); % IN RADIANS
    % % now use DT_coeffs to estimate positions of points along curve, assuming
    % % consistent rate of curvature

    % figure()
    % plot(unique_pres, DT_angles, LineWidth=2)
    % grid on, hold on
    % poly_DT = poly2sym(DT_fit);
    % fplot(poly_DT, ':')

    % FMINCON to find optimal angle to rotate points by
    disp('STARTING FMINCON')
    options = optimoptions('fmincon', 'Display','iter');
    obj_fun_for_fmincon = @(rot_angle) DTrotate_error_for_fmincon(rot_angle, all_est_pts, unique_pres, allCurves, DT_fit, act_len);
    rot_init=0;
    [final_angle, final_error] = fmincon(obj_fun_for_fmincon, rot_init, [], [], [], [], -5, 5, [], options);


    all_DT_errors = zeros(length(all_est_pts), 1);
    all_dists_DT = zeros(num_frames, num_markers);
    for kb = 1:length(all_est_pts)
        P_in = unique_pres(kb);
        curve = allCurves{kb};

        DT_angle_at_Pin = polyval(DT_fit, P_in);

        % segment_angles = linspace(0, DT_angle_at_Pin, num_segments);
        segment_angles = ones(1, length(all_est_pts{1})-1) * DT_angle_at_Pin/num_segments;
        % segment_angles(4) = segment_angles(4) *1.4

        estimated_points = zeros(length(all_est_pts{1}), 2);

        est_segment_lengths = ones(1, length(all_est_pts{1})-1) * curve.EstimatedLength/(num_segments);
        % est_segment_lengths = [0; curve.SegmentLengths]

        [final_TF_matrix, all_TF_matrices] = makeTFMatrix(segment_angles, est_segment_lengths);

        prev_tfs = eye(3);
        for kbb = 1:(length(estimated_points)-1)
            origin = [0; 0; 1];
            prev_tfs = prev_tfs * all_TF_matrices{kbb};
            pt = prev_tfs * origin;
            estimated_points(kbb+1, 1) = pt(1);
            estimated_points(kbb+1, 2) = pt(2);
        end

        [estimated_points(:, 1), estimated_points(:, 2)] = Rotate(estimated_points(:, 1), estimated_points(:, 2), ((135-final_angle)*pi/180));

        errors = zeros(length(estimated_points), 1);
        for kbc = 1:length(estimated_points)
            errors(kbc) = dist_2pts(all_est_pts{kb}(kbc, 1), all_est_pts{kb}(kbc, 2), estimated_points(kbc, 1), estimated_points(kbc, 2))/(length(all_est_pts{kb}) * sum(est_segment_lengths));
            all_dists_DT(kb, kbc) = dist_2pts(all_est_pts{kb}(kbc, 1), all_est_pts{kb}(kbc, 2), estimated_points(kbc, 1), estimated_points(kbc, 2));
        end

        all_DT_errors(kb) = sum(errors);

    end
    all_DT_errors;


    figure()
    plot(all_est_pts{kb}(:, 1), all_est_pts{kb}(:, 2), '-o')
    axis equal; grid on; hold on
    plot(estimated_points(:, 1), estimated_points(:, 2), '-o')
    legend('Measured', 'Predicted', 'Location', 'southeast')
    title(append(strrep(Actuator, '_', ' '), ', DT Bend Angle Fit ' ))
    ylabel('millimeters')
    xlabel('millimeters')
   
    ax = gcf;
    exportgraphics(ax, append(pwd, '\Test Data\Figures\', Actuators(index), '_DTBendFit.pdf'))

    % r = curve.EstimatedLength/(2 * polyval(SE_fit, P_in));

    BA1 = mean(all_SE_errors);

    BA2 = mean(all_DT_errors);

    all_dists_SE;
    all_dists_DT;

    SE_ERROR = PredictionError(all_dists_SE, act_len)
    DT_ERROR = PredictionError(all_dists_DT, act_len)

    all_errs(index, 1) = SE_ERROR
    all_errs(index, 2) = DT_ERROR
    %% BA 3 - Arc Radius Angle
    % really the same as 1, due to the circle assumption

end

all_errs

table = [Actuators', all_errs]
Latex_String = MatrixToLatexMatrix(table)