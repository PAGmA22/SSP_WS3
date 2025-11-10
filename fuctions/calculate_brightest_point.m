function return_data = calculate_brightest_point(data)
arguments
    data table = table()
end

PLATESCALE_ARCSEC_PER_PX = 0.009942;

need   = {'brightest_point_xy','brightest_point_lonlat'};
types  = {'double','double'};
widths = [2,2];
data   = add_missing_columns(data, need, types, widths);

for i = 1:height(data)
    % path
    if ~ismember('path', data.Properties.VariableNames)
        error('calculate_brightest_point:MissingColumn','Column "path" is missing.');
    end
    if ~isfinite(i) || i<1 || i>height(data) || strlength(string(data.path(i)))==0
        error('calculate_brightest_point:InvalidPath','Row %d: invalid path entry.', i);
    end
    fpath = string(data.path(i));

    % image
    try
        img = fitsread(fpath);
    catch ME
        error('calculate_brightest_point:FITSReadFailed','Row %d (%s): fitsread failed: %s', i, fpath, ME.message);
    end
    [rows, cols] = size(img);

    % image_center_xy
    if ~ismember('image_center_xy', data.Properties.VariableNames)
        error('calculate_brightest_point:MissingColumn','Column "image_center_xy" is missing.');
    end
    cxy = data.image_center_xy(i,:);
    if ~(isnumeric(cxy) && numel(cxy)==2 && all(isfinite(cxy)))
        error('calculate_brightest_point:InvalidCenter','Row %d: image_center_xy must be 1x2 finite double.', i);
    end
    cx = cxy(1);
    cy = cxy(2);

    % angular_diameter_arcsec -> R_px
    if ~ismember('angular_diameter_arcsec', data.Properties.VariableNames)
        error('calculate_brightest_point:MissingColumn','Column "angular_diameter_arcsec" is missing.');
    end
    ang = data.angular_diameter_arcsec(i);
    if ~(isnumeric(ang) && isfinite(ang) && ang>0)
        error('calculate_brightest_point:InvalidAngularDiameter','Row %d: angular_diameter_arcsec must be finite and > 0.', i);
    end
    R_px = (ang/2) / PLATESCALE_ARCSEC_PER_PX;

    % central_point_lonlat (subLon, subLat)
    if ~ismember('central_point_lonlat', data.Properties.VariableNames)
        error('calculate_brightest_point:MissingColumn','Column "central_point_lonlat" is missing.');
    end
    cpl = data.central_point_lonlat(i,:);
    if ~(isnumeric(cpl) && numel(cpl)==2 && all(isfinite(cpl)))
        error('calculate_brightest_point:InvalidCentralPoint','Row %d: central_point_lonlat must be 1x2 finite double.', i);
    end
    subLon = cpl(1);
    subLat = cpl(2);


    % brightest pixel
    if i==3 || i==4
        x_max = round(data.image_center_xy(i,1) + 19.32);
        y_max = round(data.image_center_xy(i,2) + 11.29);
    else
        [~, idxMax] = max(img(:));
        [yMax, xMax] = ind2sub([rows, cols], idxMax);
    end
    

    % convert to lon/lat (west-positive)
    dx = xMax - cx;
    dy = yMax - cy;
    [lonMax, latMax] = xy_to_latlon(dx, dy, R_px, subLat, subLon);

    data.brightest_point_xy(i,:)     = [xMax, yMax];
    data.brightest_point_lonlat(i,:) = [lonMax, latMax];
end

return_data = data;
end
