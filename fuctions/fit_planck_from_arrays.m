function T = fit_planck_from_arrays(lambda_um, P)
%FIT_PLANCK_FROM_ARRAYS  Fit a scaled Planck spectrum to (lambda, brightness) data.
%   T = fit_planck_from_arrays(lambda_um, P)
%
%   INPUTS
%     lambda_um : vector of wavelengths in microns (µm)
%     P         : vector of brightness values (arbitrary units)
%
%   OUTPUT
%     T         : fitted temperature in Kelvin (scalar)
%
%   Behavior
%     - Fits y(lambda) ≈ α * B_lambda(T).
%     - Plots the data points and the fitted curve in a new figure.
%     - Figure x-axis spans 0–5 µm.
%     - Also overlays dotted yellow reference curves for T = 1000, 2000, 3000, 4000 K.
%     - Returns T (temperature).  α is not returned.

    % ---- sanity checks
    if nargin < 2
        error('Provide wavelength (µm) and brightness arrays.');
    end
    lambda_um = lambda_um(:);
    P         = P(:);
    good = isfinite(lambda_um) & isfinite(P);
    lambda_um = lambda_um(good);
    P         = P(good);

    if numel(lambda_um) < 2 || numel(P) < 2
        error('Need at least two finite data points.');
    end

    % ---- sort by wavelength
    [lambda_um, ord] = sort(lambda_um);
    P = P(ord);

    % ---- initial guesses (Wien)
    [~, imax] = max(P);
    lambda_peak_um = lambda_um(imax);
    if isfinite(lambda_peak_um) && lambda_peak_um > 0
        T0 = max(100, min(4000, 2898 / lambda_peak_um)); % clamp to [100,4000] K
    else
        T0 = 800;  % fallback
    end
    alpha0 = max(P); if ~isfinite(alpha0) || alpha0<=0, alpha0 = 1; end

    % ---- model
    model = @(p,x) alpha_planck(x, p(1), p(2)); % p = [T, alpha]

    % ---- bounds (loose but reasonable)
    lb = [100,  0];
    ub = [4000, Inf];

    % ---- fit
    p0 = [T0, alpha0];
    if exist('lsqcurvefit','file') == 2
        opts = optimoptions('lsqcurvefit','Display','off');
        p = lsqcurvefit(model, p0, lambda_um, P, lb, ub, opts);
    else
        % fminsearch with soft bounds
        cost = @(p) mean((P - model([ ...
            max(lb(1), min(ub(1), p(1))), ...
            max(lb(2), min(ub(2), p(2)))], lambda_um)).^2);
        opts = optimset('Display','off');
        p = fminsearch(cost, p0, opts);
        % clamp to bounds
        p = [max(lb(1), min(ub(1), p(1))), max(lb(2), min(ub(2), p(2)))];
    end
    T     = p(1);
    alpha = p(2);

    % ---- plot data and fitted curve (0 .. 5 µm)
    figure('Color','w'); hold on; box on; grid on;

    % scatter data
    scatter(lambda_um, P, 60, 'filled', 'DisplayName','data');

    % wavelength grid for smooth curves from ~0 to 5 µm (avoid 0 singularity)
    wgrid_plot = linspace(1e-3, 5, 1000).';

    % fitted curve over full 0–5 µm
    plot(wgrid_plot, model([T, alpha], wgrid_plot), 'LineWidth', 1.8, ...
        'DisplayName', sprintf('fit: T = %.0f K', T));

    % reference dotted yellow curves at fixed temperatures (scaled with fitted alpha for visibility)
    Trefs = [1000 2000 3000 4000];
    for Tr = Trefs
        yref = alpha_planck(wgrid_plot, Tr, alpha); % use fitted alpha for comparable scale
        plot(wgrid_plot, yref, 'y:', 'LineWidth', 1.2, ...
            'DisplayName', sprintf('T = %d K', Tr));
    end

    xlabel('Wavelength [\mum]');
    ylabel('Brightness [arb.]');
    title('Scaled Planck fit (with reference temperatures)');
    xlim([0 5]);
    legend('Location','best');
end

% --------- helper: scaled Planck function per wavelength ---------
function B = alpha_planck(lambda_um, T, alpha)
% alpha * (2hc^2 / lambda^5) * 1/(exp(hc/(lambda k T)) - 1), with lambda in µm
    % constants
    h  = 6.62607015e-34;  % J*s
    c  = 299792458;       % m/s
    kB = 1.380649e-23;    % J/K
    lambda_m = lambda_um * 1e-6;           % µm -> m
    x = (h*c) ./ (lambda_m * kB * T);      % dimensionless
    Bl = (2*h*c^2) ./ (lambda_m.^5 .* (exp(x) - 1));  % W·m^-3·sr^-1
    B = alpha * Bl;
end
