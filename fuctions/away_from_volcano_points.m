function pts = away_from_volcano_points(center_xy, volcano_xy, N, min_dist)
%AWAY_FROM_VOLCANO_POINTS Compute N points around center, rotated from the
% "away-from-volcano" direction, with a minimum radius.
%
%   pts = away_from_volcano_points(center_xy, volcano_xy)
%   pts = away_from_volcano_points(center_xy, volcano_xy, N)
%   pts = away_from_volcano_points(center_xy, volcano_xy, N, min_dist)
%
%   INPUTS
%     center_xy : [x y] center point (double)
%     volcano_xy: [x y] volcano/brightest point (double)
%     N         : number of return points (default 1)
%     min_dist  : minimum distance from center (default 15 pixels)
%
%   OUTPUT
%     pts : N×2 array of [x y] points
%
%   Notes:
%     - Base direction is (center - volcano), i.e., away from the volcano.
%     - If ||center - volcano|| < min_dist, the vector length is set to min_dist.
%     - Points are obtained by rotating the base vector by k*360/(N+1), k=1..N,
%       and adding to center. This ensures adjacent rings don't overlap at boundaries.

    % --- Defaults ---
    if nargin < 3 || isempty(N),        N = 1;        end
    if nargin < 4 || isempty(min_dist), min_dist = 15; end

    % Handle N=0 gracefully
    if N <= 0
        pts = zeros(0,2);
        return;
    end

    % --- Base vector: towards volcano ---
    v = - (center_xy(:) - volcano_xy(:));   % column vector
    d = sqrt(sum(v.^2));

    if d < eps
        % Volcano and center coincide: pick arbitrary direction
        dir = [1; 0];
        d = 0;
    else
        dir = v / d; % unit vector
    end

    % Enforce minimum radius
    L = max(d, min_dist);
    v_scaled = dir * L;

    % --- Rotation step ---
    step_deg = 360 / (N + 1);

    % --- Generate points ---
    pts = zeros(N, 2);
    for k = 1:N
        th = deg2rad(k * step_deg);
        R = [cos(th) -sin(th); sin(th) cos(th)];
        offset = R * v_scaled;
        p = center_xy(:) + offset;
        pts(k,:) = p.';
    end
end
