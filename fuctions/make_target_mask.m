function mask_points = make_target_mask(x, y, Rmin, Rmax, img)
%MAKE_TARGET_MASK Create an annular mask around (x,y) with [Rmin, Rmax]
%
%   mask_points = make_target_mask(x, y, Rmin, Rmax)
%   mask_points = make_target_mask(x, y, Rmin, Rmax, img)
%
%   INPUTS:
%       x, y   - Center coordinates (scalars, pixels; can be non-integers)
%       Rmin   - Inner radius (pixels). Pixels with distance == Rmin are EXCLUDED
%       Rmax   - Outer radius (pixels). Pixels with distance == Rmax are INCLUDED
%       img    - (optional) image for size reference. If omitted, size = 150x150
%
%   OUTPUT:
%       mask_points - n×2 array of [x y] integer pixel coordinates inside the mask
%
%   NOTE (no-overlap guarantee):
%       We use (distance > Rmin) & (distance <= Rmax). Thus,
%       masks (x,y,R1,R2) and (x,y,R2,R3) have no shared pixels.

    % --- Defaults / size handling ---
    if nargin < 5 || isempty(img)
        img_size = [150, 150]; % [rows, cols]
    else
        img_size = size(img);
        img_size = img_size(1:2);
    end

    % --- Input checks ---
    if nargin < 4
        error('Usage: make_target_mask(x, y, Rmin, Rmax, [img])');
    end
    if ~isscalar(Rmin) || ~isscalar(Rmax) || Rmin < 0 || Rmax <= Rmin
        error('Radii must satisfy: Rmin >= 0 and Rmax > Rmin.');
    end

    % --- Coordinate grid ---
    nRows = img_size(1);
    nCols = img_size(2);
    [X, Y] = meshgrid(1:nCols, 1:nRows);

    % --- Distance test (squared for speed/precision) ---
    d2 = (X - x).^2 + (Y - y).^2;
    Rmin2 = Rmin^2;
    Rmax2 = Rmax^2;

    % Half-open annulus: [Rmin, Rmax)
    M = (d2 >= Rmin2) & (d2 < Rmax2);

    % --- Extract coordinates in [x y] order ---
    [yy, xx] = find(M);
    mask_points = [xx, yy];
end
