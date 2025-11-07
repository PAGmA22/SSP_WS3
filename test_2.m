% Constants
PLATESCALE_ARCSEC_PER_PX = 0.009942;    % Keck NIRC2 narrow (arcsec/pixel)
NPangle = 0;                            % default, not in table

% Preallocate new columns
fitsData.CenterX     = nan(height(fitsData),1);
fitsData.CenterY     = nan(height(fitsData),1);
fitsData.BrightX     = nan(height(fitsData),1);
fitsData.BrightY     = nan(height(fitsData),1);
fitsData.dX          = nan(height(fitsData),1);
fitsData.dY          = nan(height(fitsData),1);
fitsData.Dist_px     = nan(height(fitsData),1);
fitsData.NormDist    = nan(height(fitsData),1);
fitsData.AngleDeg    = nan(height(fitsData),1);
fitsData.Radius_px   = nan(height(fitsData),1);
fitsData.MaxLat      = nan(height(fitsData),1);
fitsData.MaxLon      = nan(height(fitsData),1);

close all

for i = 1:height(fitsData)
    % --- Load image ---
    fpath  = fitsData.path(i);
    img    = fitsread(fpath);

    % --- Metadata from table ---
    subLon = fitsData.lon(i);        % sub-Earth longitude (deg)
    subLat = fitsData.lat(i);        % sub-Earth latitude (deg)
    angDia = fitsData.ang_dia(i);    % apparent angular diameter (arcsec)

    % --- Limb fit ---
    try
        [cx, cy, Rfit] = limb_center_circle(img);
        R_px = Rfit;
    catch
        [cx, cy] = limb_center_circle(img);
        % if R not available, derive from angular diameter and plate scale
        R_px = (angDia/2) / PLATESCALE_ARCSEC_PER_PX;
    end

    % --- Brightest pixel ---
    [~, idxMax] = max(img(:));
    [yMax, xMax] = ind2sub(size(img), idxMax);

    % --- Differences ---
    dx = xMax - cx;
    dy = yMax - cy;
    dist_px = hypot(dx, dy);
    normDist = dist_px / R_px;
    angleDeg = atan2d(dy, dx);

    % --- Convert to lat/lon on Io (flip dx for east-positive) ---
    [lonMax, latMax] = xy_to_latlon(-dx, dy, R_px, subLat, subLon, NPangle);

    % --- Write results directly into fitsData ---
    fitsData.CenterX(i)   = cx;
    fitsData.CenterY(i)   = cy;
    fitsData.BrightX(i)   = xMax;
    fitsData.BrightY(i)   = yMax;
    fitsData.dX(i)        = dx;
    fitsData.dY(i)        = dy;
    fitsData.Dist_px(i)   = dist_px;
    fitsData.NormDist(i)  = normDist;
    fitsData.AngleDeg(i)  = angleDeg;
    fitsData.Radius_px(i) = R_px;
    fitsData.MaxLat(i)    = latMax;
    fitsData.MaxLon(i)    = lonMax;

    % --- Plot (optional diagnostic) ---
    figure('Name', fpath);
    imagesc(img); set(gca,'YDir','normal'); axis equal tight
    xlabel('Pixel X'); ylabel('Pixel Y');
    title(sprintf('Center & Brightest Point: %s', fpath), 'Interpreter','none');
    hold on; c = colorbar; c.Label.String = 'Intensity [counts]';
    plot(cx, cy, 'y*', 'MarkerSize', 12, 'LineWidth', 1.5);
    plot(xMax, yMax, 'r+', 'MarkerSize', 10, 'LineWidth', 1.5);
    quiver(cx, cy, dx, dy, 0, 'w', 'LineWidth', 1, 'MaxHeadSize', 0.7);
    txt = sprintf(['Δx=%.2f  Δy=%.2f\nr=%.2f px  (%.3f R)\nθ=%.1f°  Lat=%.2f°  Lon=%.2f°'], ...
                  dx, dy, dist_px, normDist, angleDeg, latMax, lonMax);
    text(xMax+3, yMax, txt, 'Color','w', 'FontSize',9, ...
         'BackgroundColor','k', 'Margin',3, 'VerticalAlignment','middle');
end

% --- Done ---
disp(fitsData);

% Optionally save new table
% writetable(fitsData, 'fitsData_with_latlon.csv');
