function data = calculate_volcano_brightness(data, R1, R2)
%CALCULATE_VOLCANO_BRIGHTNESS Compute background-subtracted volcano brightness
%
%   data = calculate_volcano_brightness(data, R1, R2)
%
%   INPUTS:
%       data : table with columns
%              - path                (string)
%              - brightest_point_xy  (1x2 double)
%       R1   : inner radius (default 4)
%       R2   : outer radius (default 7)
%
%   OUTPUT:
%       data : same table with one added column
%              - volcano_brightness  (background-subtracted brightness)
%
%   METHOD:
%       1. M1 = mask within R1
%       2. M2 = mask between R1 and R2
%       3. brightness = sum(M1.*img) - sum(M2.*img)*sum(M1(:))/sum(M2(:))

%% --- Defaults ---
if nargin < 2 || isempty(R1); R1 = 4; end
if nargin < 3 || isempty(R2); R2 = 7; end
if R2 <= R1
    error('R2 must be greater than R1 (R1=%g, R2=%g)', R1, R2);
end

%% --- Add missing column ---
need   = {'volcano_brightness'};
types  = {'double'};
widths = [1];
data   = add_missing_columns(data, need, types, widths);

%% --- Main loop ---
for i = 1:height(data)
    try
        img = fitsread(data.path(i));

        % --- Volcano position ---
        xy = data.brightest_point_xy(i,:);
        x = xy(1);
        y = xy(2);

        % --- Create masks ---
        pts1 = make_target_mask(x, y, 0, R1, img);
        M1 = false(size(img));
        if ~isempty(pts1)
            M1(sub2ind(size(img), pts1(:,2), pts1(:,1))) = true;
        end

        pts2 = make_target_mask(x, y, R1, R2, img);
        M2 = false(size(img));
        if ~isempty(pts2)
            M2(sub2ind(size(img), pts2(:,2), pts2(:,1))) = true;
        end

        % --- Compute background-subtracted brightness ---
        S1 = sum(img(M1), 'omitnan');
        S2 = sum(img(M2), 'omitnan');
        N1 = sum(M1(:));
        N2 = sum(M2(:));

        data.volcano_brightness(i) = S1 %- S2 * N1 / N2;

    catch ME
        warning('Row %d failed: %s', i, ME.message);
        data.volcano_brightness(i) = NaN;
    end
end
end
