% Assumes: fitsData = table('Size',[numel(files),6], ...
%   'VariableTypes', {'string','string','double','double','double','double'}, ...
%   'VariableNames', {'path','time','lon','lat','ang_dia','wavelength'});

close all

% Preallocate results as a struct array for speed
results = struct( ...
    'path', {}, 'time', {}, 'wavelength', {}, 'ang_dia', {}, ...
    'CenterX', {}, 'CenterY', {}, ...
    'BrightX', {}, 'BrightY', {}, ...
    'dX', {}, 'dY', {}, 'Dist', {}, 'AngleDeg', {}, ...
    'MaxLon', {}, 'MaxLat', {} );

for i = 1:height(fitsData)
    % --- Inputs from fitsData ---
    fpath   = fitsData.path(i);
    tstamp  = fitsData.time(i);
    subLon  = fitsData.lon(i);       % sub-Earth longitude (deg)
    subLat  = fitsData.lat(i);       % sub-Earth latitude (deg)
    angDia  = fitsData.ang_dia(i);   % angular diameter (deg or arcsec; not required for xy_to_latlon)
    lambda  = fitsData.wavelength(i);

    % --- Load image ---
    img = fitsread(fpath);

    % --- Center (and radius if available) ---
    cx = NaN; cy = NaN; R = NaN;
    try
        % Prefer a version of your function that returns radius too:
        [cx, cy, R] = limb_center_circle(img);
    catch
        % Fallback if your function only returns (cx,cy)
        [cx, cy] = limb_center_circle(img);
        % Heuristic radius in pixels (better: modify limb_center_circle to return R)
        R = 0.48 * min(size(img));   % conservative disk estimate
    end

    % --- Brightest pixel & deltas (image coords: +y is down) ---
    [~, idxMax] = max(img(:));
    [yMax, xMax] = ind2sub(size(img), idxMax);
    dx = xMax - cx;
    dy = yMax - cy;
    dist = hypot(dx, dy);
    angleDeg = atan2d(dy, dx);  % 0° = +x, CCW positive

    % --- Convert to planet lon/lat (note the -dy to flip image y-up) ---
    NPangle = 0;  % not provided in your table; defaults to 0 per your function
    [lonMax, latMax] = xy_to_latlon(dx, -dy, R, subLat, subLon, NPangle);

    % --- Plot (optional) ---
    figure('Name', fpath);
    imagesc(img); set(gca,'YDir','normal'); axis equal tight
    xlabel('Pixel X'); ylabel('Pixel Y');
    title(sprintf('Center & Brightest: %s', fpath), 'Interpreter','none');
    hold on; c = colorbar; c.Label.String = 'Intensity [counts]';
    plot(cx, cy, 'y*', 'MarkerSize', 12, 'LineWidth', 1.5);
    plot(xMax, yMax, 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
    quiver(cx, cy, dx, dy, 0, 'w', 'LineWidth', 1, 'MaxHeadSize', 0.7);
    txt = sprintf('Δx=%.2f  Δy=%.2f\nr=%.2f px  θ=%.1f°\nLon=%.2f°  Lat=%.2f°', ...
                  dx, dy, dist, angleDeg, lonMax, latMax);
    text(xMax+3, yMax, txt, 'Color','w', 'FontSize',9, ...
         'BackgroundColor','k', 'Margin',3, 'VerticalAlignment','middle');

    % --- Store row ---
    results(i).path        = fpath;
    results(i).time        = tstamp;
    results(i).wavelength  = lambda;
    results(i).ang_dia     = angDia;
    results(i).CenterX     = cx;
    results(i).CenterY     = cy;
    results(i).BrightX     = xMax;
    results(i).BrightY     = yMax;
    results(i).dX          = dx;
    results(i).dY          = dy;
    results(i).Dist        = dist;
    results(i).AngleDeg    = angleDeg;
    results(i).MaxLon      = lonMax;
    results(i).MaxLat      = latMax;

    fprintf('%2d/%d %s  Center=(%.2f,%.2f)  Bright=(%d,%d)  Δ=(%.2f,%.2f)  r=%.2f  θ=%.1f°  Lon=%.2f  Lat=%.2f\n', ...
        i, height(fitsData), fpath, cx, cy, xMax, yMax, dx, dy, dist, angleDeg, lonMax, latMax);
end

% --- Table out ---
resultTable = struct2table(results);

% (Optional) persist
% writetable(resultTable, 'results_lonlat_max.csv');

disp(resultTable);
