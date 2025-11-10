function data = calculate_nonvolcanic_brightness(data, R)
%CALCULATE_NONVOLCANIC_BRIGHTNESS Mean brightness around the precomputed non-volcanic point.
%
%   data = calculate_nonvolcanic_brightness(data, R)
%
%   INPUTS
%     data : table with columns
%            - path                    (string/char) FITS path
%            - nonvolcanic_point_xy    (1x2 double) [x y] background point (precomputed)
%     R    : mask radius in pixels (disk of radius R)
%
%   OUTPUT
%     data : same table with one added/updated column
%            - nonvolcanic_brightness (double) mean brightness in the R-disk
%
%   Notes
%     - Uses add_missing_columns and make_target_mask.
%     - No subtraction here (unlike volcanic brightness routines); this
%       stores the mean brightness inside the aperture centered at the
%       non-volcanic point.
%
%   Dependencies
%     - add_missing_columns(nameCell, typeCell, widthArray)
%     - make_target_mask(x, y, Rmin, Rmax, img) -> [N x 2] pixel list [x y]

    arguments
        data table
        R (1,1) double {mustBePositive}
    end

    % --- ensure required input columns exist (create if missing to avoid hard error) ---
    need_in   = {'path','nonvolcanic_point_xy'};
    types_in  = {'string','double'};
    widths_in = [1,2];
    if exist('add_missing_columns','file') == 2
        data = add_missing_columns(data, need_in, types_in, widths_in);
    else
        % fallback creation
        if ~ismember('path', data.Properties.VariableNames)
            data.path = strings(height(data),1);
        end
        if ~ismember('nonvolcanic_point_xy', data.Properties.VariableNames)
            data.nonvolcanic_point_xy = nan(height(data),2);
        end
    end

    % --- ensure output column exists ---
    need_out   = {'nonvolcanic_brightness'};
    types_out  = {'double'};
    widths_out = [1];
    if exist('add_missing_columns','file') == 2
        data = add_missing_columns(data, need_out, types_out, widths_out);
    else
        if ~ismember('nonvolcanic_brightness', data.Properties.VariableNames)
            data.nonvolcanic_brightness = nan(height(data),1);
        end
    end

    % --- iterate rows ---
    for i = 1:height(data)
        try
            % read image
            pth = data.path(i);
            if ismissing(pth); pth = ""; end
            if isstring(pth) || ischar(pth)
                img = fitsread(char(pth));
            else
                error('Invalid path type at row %d.', i);
            end

            % get background point
            bg_xy = data.nonvolcanic_point_xy(i,:);
            if ~isnumeric(bg_xy) || numel(bg_xy) ~= 2 || any(~isfinite(bg_xy))
                data.nonvolcanic_brightness(i) = NaN;
                continue
            end
            x = bg_xy(1); y = bg_xy(2);

            % construct disk mask (0..R]
            pix = make_target_mask(x, y, 0, R, img);
            if isempty(pix) || size(pix,2) ~= 2
                data.nonvolcanic_brightness(i) = NaN;
                continue
            end

            % guard: ensure indices are within bounds
            [nrows, ncols] = size(img);
            inb = pix(:,1) >= 1 & pix(:,1) <= ncols & pix(:,2) >= 1 & pix(:,2) <= nrows ...
                  & isfinite(pix(:,1)) & isfinite(pix(:,2));
            pix = pix(inb, :);
            if isempty(pix)
                data.nonvolcanic_brightness(i) = NaN;
                continue
            end

            % build logical mask and compute mean
            M = false(size(img));
            idx = sub2ind(size(img), pix(:,2), pix(:,1));
            M(idx) = true;

            data.nonvolcanic_brightness(i) = mean(img(M), 'omitnan');

        catch ME
            warning('calculate_nonvolcanic_brightness: row %d failed: %s', i, ME.message);
            data.nonvolcanic_brightness(i) = NaN;
        end
    end
end
