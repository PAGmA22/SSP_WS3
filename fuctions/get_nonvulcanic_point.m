function data = get_nonvulcanic_point(data, N, min_dist)
%GET_NONVULCANIC_POINT Add a non-volcanic (background) point per row to 'data'.
%   data = GET_NONVULCANIC_POINT(data)
%   data = GET_NONVULCANIC_POINT(data, N)
%   data = GET_NONVULCANIC_POINT(data, N, min_dist)
%
%   Uses away_from_volcano_points(center_xy, volcano_xy, N, min_dist)
%   to pick a point (or N candidate points) in the direction opposite
%   to the volcano. If N>1, the function stores the MEAN of those points.
%
%   INPUTS
%     data      : table with at least:
%                 - image_center_xy       (1x2 double per row)
%                 - brightest_point_xy    (1x2 double per row)
%     N         : number of candidate points to generate (default 1)
%     min_dist  : minimum radius [px] for the away-from-volcano points (default 10)
%
%   OUTPUT
%     data : same table with new column:
%            - nonvolcanic_point_xy  (1x2 double per row)
%
%   Notes
%     - If inputs are missing/invalid for a row, stores [NaN NaN].
%     - Requires helper: add_missing_columns, away_from_volcano_points

    arguments
        data table
        N (1,1) double {mustBePositive, mustBeInteger} = 1
        min_dist (1,1) double {mustBeNonnegative} = 10
    end

    % Ensure output column exists
    need_out   = {'nonvolcanic_point_xy'};
    types_out  = {'double'};
    widths_out = [2];
    data = add_missing_columns(data, need_out, types_out, widths_out);

    % Loop over rows
    for i = 1:height(data)
        pt = [NaN NaN]; % default if something goes wrong

        try
            center_xy   = data.image_center_xy(i,:);
            volcano_xy  = data.brightest_point_xy(i,:);

            % Validate inputs
            if ~isnumeric(center_xy) || numel(center_xy)~=2 || any(~isfinite(center_xy))
                data.nonvolcanic_point_xy(i,:) = pt; %#ok<AGROW>
                continue
            end
            if ~isnumeric(volcano_xy) || numel(volcano_xy)~=2 || any(~isfinite(volcano_xy))
                data.nonvolcanic_point_xy(i,:) = pt; %#ok<AGROW>
                continue
            end

            % Generate away-from-volcano candidate points
            pts = away_from_volcano_points(center_xy, volcano_xy, N, min_dist);

            % Handle output: mean if multiple points, single otherwise
            if isempty(pts) || ~isnumeric(pts) || size(pts,2) ~= 2
                % keep [NaN NaN]
            else
                if size(pts,1) > 1
                    pt = mean(pts, 1, 'omitnan');
                else
                    pt = pts(1,:);
                end
                if any(~isfinite(pt)) || numel(pt) ~= 2
                    pt = [NaN NaN];
                end
            end

            data.nonvolcanic_point_xy(i,:) = pt; %#ok<AGROW>

        catch
            % On any error, keep NaNs for this row and continue
            data.nonvolcanic_point_xy(i,:) = pt; %#ok<AGROW>
        end
    end
end
