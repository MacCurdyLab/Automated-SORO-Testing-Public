%% Multiple Circle Fits

clear; clc; close all; format long


%% actual actuator points
Marker_Diameter = 6.35;
Actuators = ["Hainsworth_95A_1"];

act_lens = [63];

table = []
all_errs = zeros(length(Actuators), 1);

for A = 1:length(Actuators)
    Actuator = Actuators(A)
    act_len = act_lens(A)


    if Actuator == "Wan_85A"
        Marker_Diameter = Marker_Diameter/2;
    end

    extra = "_multipose_horizontal_vac";
    Images = strcat(Actuator, extra, '_NA_TestImgs.tif');

    % find markers on every frame of .tif file
    [ImgProcessed, positionCellArray, pixels_per_mm] = ProcessTIFImage(Images, Marker_Diameter, Actuator, 'Top');

    % Separate Datum from other points
    [AllDatumPTs, SortedPoints_cell] = DatumDetector(Images, ImgProcessed, positionCellArray, pixels_per_mm, 1);

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

    % % convert measured points to real coordinates
    % all_meas_pts = cell(length(SortedPoints_cell), 1);
    % for i = 1:length(SortedPoints_cell)
    %     % gather real point data
    %
    %     all_meas_pts{i} = PixtoReal(SortedPoints_cell{i}, pixels_per_mm);
    % end

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

        angle = Horiz_angles(i) - pi/4 - abs(2*(unique_h_angles(1)-unique_h_angles(2)))*fix((i-1)/length(unique_pres));
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
    num_segments = length(SortedPoints_cell{1})-1;
    allCurves = NaturalCubicSplineFit(all_est_pts, num_segments, append(Actuator, extra));

    num_frames = length(allCurves);
    num_markers = length(all_est_pts{1});


    %% fit circles to every set of points
    [All_radii, All_centers] = FitCircles(all_est_pts);

    %% fit functions to changes in Radius and X, Y coordinates of circle center based on input pressure

    % radius_model_fun = @(b, x) (b(1) * b(2).^(b(3) * x) + b(4));
    % beta_0 = [160, 0.75, 1, 20];
    % model_fun = @(b, x) b(1) * exp( -b(2) * x ) + b(3)
    % beta_0 = [100, 0.5, 20]
    %
    % rad_model = fitnlm(input_pressures(:), All_radii(:), radius_model_fun, beta_0);
    % Radii_coeffs = rad_model.Coefficients.Estimate;
    % radii_fit = feval(radius_model_fun, Radii_coeffs, pressure_possible);
    %
    % % X and Y
    % coordinate_model_fun = @(c, x) c(1)*log( c(2) * ( x-c(3) ) ) - c(4);
    % c_0 = [2, 0.001, 1, 5];
    %
    % x_model = fitnlm(input_pressures(:), All_centers(:, 1), coordinate_model_fun, c_0);
    % y_model = fitnlm(input_pressures(:), All_centers(:, 2), coordinate_model_fun, c_0);
    %
    % x_coeffs = x_model.Coefficients.Estimate;
    % y_coeffs = y_model.Coefficients.Estimate;
    %
    % x_fit = feval(coordinate_model_fun, x_coeffs, pressure_possible);
    % y_fit = feval(coordinate_model_fun, y_coeffs, pressure_possible);

    pressure_possible = linspace(min(unique_pres), max(unique_pres), 1000)';
    splin_rad = spline(unique_pres, All_radii);
    splin_x = spline(unique_pres, All_centers(:, 1));
    splin_y = spline(unique_pres, All_centers(:, 2));

    % figure()
    % plot(unique_pres, All_radii)
    % title('Radius')
    % grid on
    % % hold on
    % % plot(pressure_possible, radii_fit)
    % hold on
    % plot(pressure_possible, ppval(splin_rad, pressure_possible))
    % legend('Data', 'Auto', 'Spline')

    % figure()
    % plot(input_pressures, All_centers(:, 1))
    % title('X')
    % grid on
    % hold on
    % plot(pressure_possible,ppval(splin_x, pressure_possible))
    %
    % figure()
    % plot(input_pressures, All_centers(:, 2) )
    % title('Y')
    % grid on
    % hold on
    % plot(pressure_possible, ppval(splin_y, pressure_possible))

    %% estimate center with lsqnonlin
    index = 10;
    pres_in = unique_pres(index);
    radius = ppval(splin_rad, pres_in);
    x_real = all_est_pts{index}(:, 1);
    y_real = all_est_pts{index}(:, 2);
    f_center = @(center) sqrt( (x_real - center(1)).^2 + (y_real - center(2)).^2 ) - radius;
    center_intitial = [mean(x_real), mean(y_real)];
    center_est = lsqnonlin(f_center, center_intitial)


    %% use models to predict circle fit based on desired input pressure
    index = 15;
    SSEs = zeros(length(unique_pres), 1);
    for index = 1:length(unique_pres)
        P_in = unique_pres(index);

        x_real = all_est_pts{index}(:, 1);
        y_real = all_est_pts{index}(:, 2);
        radius_predicted = ppval(splin_rad, P_in);
        center_x_predicted = ppval(splin_x, P_in);
        center_y_predicted = ppval(splin_y, P_in);

        errors = zeros(length(x_real), 1);
        for j = 1:length(x_real)
            errors(j) = dist_2pts(center_x_predicted, center_y_predicted, x_real(j), y_real(j)) - radius_predicted;
        end

        errors;
        SSEs(index) = sum(errors);


    end

    %% use models to predict circle fit based on desired input pressure
    index = 20;
    SSEs2 = zeros(length(unique_pres), 1);

    % FMINCON to find optimal angle to rotate points by
    disp('STARTING FMINCON')
    options = optimoptions('fmincon', 'Display','iter');
    obj_fun_for_fmincon = @(rot_angle) Circrotate_error_for_fmincon(rot_angle, all_est_pts, unique_pres, allCurves, splin_rad, act_len);
    rot_init=0;
    [final_angle, final_error] = fmincon(obj_fun_for_fmincon, rot_init, [], [], [], [], -5, 5, [], options)

    all_dists_circ = zeros(num_frames, num_markers);

    for index = 1:length(unique_pres)
        P_in = unique_pres(index);

        x_real = all_est_pts{index}(:, 1);
        y_real = all_est_pts{index}(:, 2);

        curve = allCurves{index};
        act_length = curve.EstimatedLength;

        radius_predicted = ppval(splin_rad, P_in);

        center = [0, radius_predicted];

        betas = linspace(0, (act_length/radius_predicted)*1.1, 1000) ;

        x_predicted = center(1) + radius_predicted * sin(betas);
        y_predicted = center(2) - radius_predicted * cos(betas);

        [x_predicted, y_predicted] = Rotate(x_predicted, y_predicted, (135-final_angle)*pi/180 );
        [c1, c2] = Rotate(center(1), center(2), (135-final_angle)*pi/180 );
        center = [c1, c2];

        errors = zeros(length(x_real), 1);
        closest_pts = zeros(length(x_real), 2);
        for j = 1:length(x_real)
            [closest_pts(j, 1), closest_pts(j, 2)] = closestPoint(x_real(j), y_real(j), x_predicted, y_predicted);
            errors(j) = dist_2pts(closest_pts(j, 1), closest_pts(j, 2), x_real(j), y_real(j))/(act_length*length(x_real));
            all_dists_circ(index, j) = dist_2pts(closest_pts(j, 1), closest_pts(j, 2), x_real(j), y_real(j));
        end

        errors;
        SSEs2(index) = sum(errors);

        %% Plot Fit and data
        % figure()
        % scatter(x_real, y_real, 'x')
        % hold on, axis equal % fit circle % centerpoint
        % scatter(x_predicted, y_predicted)
        % % f_circle = @(x, y) (x-center(1)).^2 + (y-center(2)).^2 - radius_predicted^2;
        % % fimplicit(f_circle, [center(1)-radius_predicted-20, center(1)+radius_predicted+20, center(2)-radius_predicted-20, center(2)+radius_predicted+20])
        % scatter(center(1), center(2), 'x', 'red')
        % % scatter(center_est(1), center_est(2), 'green')
        %
        % radstr = sprintf('Pred. Radius = %.2f', radius_predicted);
        % legend('meas. pts.', 'pred. circle fit', 'center', 'lsq est. cen.')
        % annotation('textbox',[0.2 0.1 0.1 0.1],'string',radstr,'fitboxtotext','on');

    end

    %% Plot Fit and data
    figure()
    scatter(x_predicted, y_predicted, "red", '.')
    hold on, axis equal % fit circle % centerpoint
    scatter(x_real, y_real, 'filled', 'blue')
    scatter(closest_pts(:, 1), closest_pts(:, 2), "green", '*')
    % f_circle = @(x, y) (x-center(1)).^2 + (y-center(2)).^2 - radius_predicted^2;
    % fimplicit(f_circle, [center(1)-radius_predicted-20, center(1)+radius_predicted+20, center(2)-radius_predicted-20, center(2)+radius_predicted+20])
    scatter(center(1), center(2), 'x', 'magenta')
    % scatter(center_est(1), center_est(2), 'green')
    grid on

    radstr = sprintf('Pred. Radius = %.2f', radius_predicted);
    legend('Predicted circle fit', 'Measured pts.', 'Closest pts.', 'Center', 'Location', 'southeast')
    % annotation('textbox',[0.2 0.1 0.1 0.1],'string',radstr,'fitboxtotext','on');
    title(append(strrep(Actuator, '_', ' '), ', Circle Fit ' ))
    ylabel('millimeters')
    xlabel('millimeters')

    ax = gcf;
    exportgraphics(ax, append(pwd, '\Test Data\Figures\', Actuators(A), '_Circlefit.pdf'))

    SSEs
    SSEs2

    norm_circle_1 = mean(SSEs)
    norm_circle_2 = mean(SSEs2)

    ERROR = PredictionError(all_dists_circ, act_len)

    
    all_errs(A) = ERROR

end
