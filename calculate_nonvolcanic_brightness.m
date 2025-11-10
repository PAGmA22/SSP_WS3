function data = calculate_nonvolcanic_brightness(data, R, N)
%CALCULATE_NONVOLCANIC_BRIGHTNESS Mean brightness in regions away from volcano
%
%   data = calculate_nonvolcanic_brightness(data, R [, N])
%
%   INPUTS
%     data : table with columns
%            - path               (string/char) FITS path
%            - image_center_xy    (1x2 double) center of body in image
%            - brightest_point_xy (1x2 double) volcano/brightest point
%     R    : mask radius in pixels (disk of radius R)
%     N    : number of "away-from-volcano" sample points (default: 1)
%
%   OUTPUT
%     data : same table with one added/updated column
%            - nonvolcanic_brightness (double) mean over N regions
%
%   Uses: away_from_volcano_points, make_target_mask, add_missing_columns

% --- defaults ---
if nargin < 3 || isempty(N), N = 1; end
if nargin < 2 || isempty(R), error('Provide mask radius R.'); end

% --- required columns ---
req = {'path','image_center_xy','brightest_point_xy'};
for k = 1:numel(req)
    if ~ismember(req{k}, data.Properties.VariableNames)
        error('Input table is missing required column "%s".', req{k});
    end
end

% --- add output column if needed ---
need   = {'nonvolcanic_brightness'};
types  = {'double'};
widths = [1];
if exist('add_missing_columns','file') == 2
    data = add_missing_columns(data, need, types, widths);
else
    if ~ismember('nonvolcanic_brightness', data.Properties.VariableNames)
        data.nonvolcanic_brightness = nan(height(data),1);
    end
end

% --- process rows ---
for i = 1:height(data)
    try
        img = fitsread(data.path(i));
        center_xy  = data.image_center_xy(i,:);
        volcano_xy = data.brightest_point_xy(i,:);

        % generate N points away from the volcano (min_dist default inside helper)
        pts = away_from_volcano_points(center_xy, volcano_xy, N);

        % compute mean brightness for each point's R-disk
        vals = nan(N,1);
        for k = 1:N
            px = pts(k,1); py = pts(k,2);

            pix = make_target_mask(px, py, 0, R, img);   % disk (0..R]
            if isempty(pix)
                continue
            end

            M = false(size(img));
            M(sub2ind(size(img), pix(:,2), pix(:,1))) = true;
            N = sum(M(:));


            vals(k) = mean(img(M), 'omitnan');
        end

        % mean over all valid points
        data.nonvolcanic_brightness(i) = mean(vals, 'omitnan');

    catch ME
        warning('Row %d failed: %s', i, ME.message);
        data.nonvolcanic_brightness(i) = NaN;
    end
end
end
