function [cx, cy] = limb_center_circle(img, varargin)

%% testing quality of funciton xD
overwrite = false;
if overwrite
    
    cx = 75.5;
    cy = 75.5;
    return
end

%LIMB_CENTER_RADIAL  Robust planetary center via radial-gradient limb sampling.
%
%   [cx, cy] = LIMB_CENTER_RADIAL(img) returns the estimated center (cx, cy)
%   in pixel coordinates for a (roughly circular) planetary disk in a single-
%   band image. The limb points are found as the radius of the steepest
%   *radial* brightness drop around a coarse center; then a robust circle fit
%   (iteratively reweighted, Tukey biweight) yields the final center.
%
%   Optional name-value pairs:
%     'SigmaDenoise'   - Light Gaussian blur before processing (px). Default: 1.0
%     'SigmaBG'        - Large Gaussian for background removal (px). Default: 10
%     'Angles'         - Number of radial angles to sample. Default: 180
%     'Step'           - Radial sampling step along each ray (px). Default: 0.5
%     'MaxRay'         - Max radial length from initial center (px). Default: auto
%     'RaySmoothing'   - Window length for 1-D smoothing along each ray. Default: 7
%     'MADThresh'      - Outlier cut on limb radii (in MAD units). Default: 3.5
%     'IRLSIters'      - Iterations of robust circle refit. Default: 10
%     'Verbose'        - true/false diagnostics. Default: false
%
%   Notes:
%   - Returns only (cx,cy) to match your request. If you also want the radius,
%     call with three outputs: [cx,cy,R] = limb_center_radial(...)

% -------------------- Params & input normalization ------------------------
p = inputParser;
p.addParameter('SigmaDenoise', 1.0, @(x)isnumeric(x)&&isscalar(x)&&x>=0);
p.addParameter('SigmaBG',      10,  @(x)isnumeric(x)&&isscalar(x)&&x>=0);
p.addParameter('Angles',       180, @(x)isnumeric(x)&&isscalar(x)&&x>=8);
p.addParameter('Step',         0.5, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('MaxRay',       [],  @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('RaySmoothing', 7,   @(x)isnumeric(x)&&isscalar(x)&&x>=3);
p.addParameter('MADThresh',    3.5, @(x)isnumeric(x)&&isscalar(x)&&x>0);
p.addParameter('IRLSIters',    10,  @(x)isnumeric(x)&&isscalar(x)&&x>=1);
p.addParameter('Verbose',      false, @(x)islogical(x)&&isscalar(x));
p.parse(varargin{:});
sDen   = p.Results.SigmaDenoise;
sBG    = p.Results.SigmaBG;
nAng   = p.Results.Angles;
dr     = p.Results.Step;
RmaxIn = p.Results.MaxRay;
wRay   = p.Results.RaySmoothing;
madK   = p.Results.MADThresh;
nIRLS  = p.Results.IRLSIters;
verb   = p.Results.Verbose;

% grayscale double
if ~isfloat(img), img = im2double(img); end
if ndims(img)==3, img = rgb2gray(img); end
I = img;
if sDen>0, I = imgaussfilt(I, sDen); end

% Remove large-scale background to suppress interior bright structures
Ibg = (sBG>0) * imgaussfilt(I, sBG);
Ihp = I - Ibg;
Ihp(Ihp<0) = 0;

[h, w] = size(Ihp);
% Initial center guess = image center (robust vs interior hotspots)
cx0 = (w+1)/2;
cy0 = (h+1)/2;

% Determine allowable maximum radius so rays stay inside image
if isempty(RmaxIn)
    Rmax = floor(min([cx0-1, cy0-1, w-cx0, h-cy0])) - 2;
else
    Rmax = min([RmaxIn, floor(min([cx0-1, cy0-1, w-cx0, h-cy0])) - 2]);
end
if Rmax < 10
    error('Image too small or center too close to border for radial sampling.');
end

% -------------------- Radial-gradient limb sampling -----------------------
theta = linspace(0, 2*pi, nAng+1); theta(end) = []; % exclude duplicate 2π
rvec  = 0:dr:Rmax;

% Precompute for interp2
[Xg, Yg] = meshgrid(1:w, 1:h);

limbPts = nan(nAng, 2);
rStar   = nan(nAng, 1);

for k = 1:nAng
    t  = theta(k);
    xL = cx0 + rvec .* cos(t);
    yL = cy0 + rvec .* sin(t);

    % Sample along the ray (linear interp, NaN outside)
    vals = interp2(Xg, Yg, Ihp, xL, yL, 'linear', NaN);

    % Clean NaNs at the end if any
    m = ~isnan(vals);
    if nnz(m) < 10, continue; end
    xL = xL(m); yL = yL(m); vals = vals(m);

    % Smooth 1-D signal along the ray and get derivative
    if wRay > 1
        vals = movmean(vals, wRay, 'Endpoints','shrink');
    end
    % Use central differences
    dvals = gradient(vals, dr);

    % We expect a *negative* jump at the limb (inside->outside): pick min(dI/dr)
    [~, idx] = min(dvals);  % most negative slope
    if isempty(idx) || idx<=1 || idx>=numel(rvec)-1
        continue
    end

    limbPts(k,:) = [xL(idx), yL(idx)];
    % Save radius (for outlier rejection by MAD)
    rStar(k)     = hypot(xL(idx)-cx0, yL(idx)-cy0);
end

good = all(isfinite(limbPts), 2);
if nnz(good) < 30
    error('Too few limb points found. Consider lowering ''SigmaBG'' or increasing ''Angles''.');
end
limbPts = limbPts(good, :);
rStar   = rStar(good);

% -------------------- Outlier rejection on radii (MAD) --------------------
rm = median(rStar);
s  = 1.4826 * median(abs(rStar - rm));
keep = abs(rStar - rm) <= madK * max(s, eps);
Pts = limbPts(keep, :);

if size(Pts,1) < 20
    warning('Few limb points after outlier rejection (%d). Result may be noisy.', size(Pts,1));
end

% -------------------- Robust circle fit (IRLS, Tukey) ---------------------
% initial algebraic circle fit (unweighted)
[cx, cy, R] = circle_fit_algebraic(Pts);

for it = 1:nIRLS
    % radial residuals
    d = hypot(Pts(:,1)-cx, Pts(:,2)-cy);
    res = d - R;

    % scale via MAD
    s = 1.4826 * median(abs(res - median(res)));
    s = max(s, 1e-6);

    % Tukey biweight weights
    c = 4*s;  % tuning constant
    u = res ./ c;
    w = (abs(u) < 1) .* (1 - u.^2).^2;
    w = w + 1e-6; % avoid singular

    [cx, cy, R] = circle_fit_algebraic(Pts, w);
end

if verb
    fprintf('[limb_center_radial] Npts=%d -> center=(%.3f, %.3f), R=%.3f px\n', ...
        size(Pts,1), cx, cy, R);
end

% Return only center as requested
if nargout < 3
    clear R
end




end

% ============================ Helpers =====================================

function [cx, cy, R] = circle_fit_algebraic(P, w)
% Weighted algebraic circle fit:
% Solve x^2 + y^2 = 2*cx*x + 2*cy*y + c0  for [cx cy c0]
X = P(:,1); Y = P(:,2);
A = [2*X, 2*Y, ones(size(X))];
b = X.^2 + Y.^2;

if nargin < 2
    W = eye(size(A,1));
else
    W = spdiags(w(:), 0, numel(w), numel(w));
end

theta = (A' * W * A) \ (A' * W * b);
cx = theta(1);
cy = theta(2);
c0 = theta(3);
R  = sqrt(max(eps, cx.^2 + cy.^2 + c0));
end
