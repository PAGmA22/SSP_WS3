function [T, alpha] = fit_planck_from_arrays(lambda_um, P)
%FIT_PLANCK_FROM_ARRAYS  Fit a scaled Planck spectrum α·B_λ(T) to data.
%   [T, alpha] = fit_planck_from_arrays(lambda_um, P)
%
%   INPUTS
%     lambda_um : vector of wavelengths in microns (µm)
%     P         : vector of brightness values (arbitrary units)
%
%   OUTPUTS
%     T     : fitted temperature [K]
%     alpha : fitted scale (same units as P)
%
%   Notes
%     • Robust initialization: coarse T grid with closed-form alpha(T).
%     • Refinement: lsqcurvefit if present; otherwise fminsearch.
%     • Plot spans only the [min(lambda), max(lambda)] range of data.
%
%   Gabriel-friendly: no assumptions about absolute units; α absorbs them.

    % --------------------------
    % 0) Sanity & preprocessing
    % --------------------------
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

    % sort by wavelength
    [lambda_um, ord] = sort(lambda_um);
    P = P(ord);

    if all(P == 0)
        error('All brightness values are zero; cannot fit.');
    end

    % --------------------------
    % 1) Physical/model helpers
    % --------------------------
    planck_W_m3_sr = @(lambda_um, T) local_planck_lambda(lambda_um, T); % W·m^-3·sr^-1
    model_fun      = @(p, x) p(2) * planck_W_m3_sr(x, p(1));            % p = [T, alpha]

    % For a fixed T, optimal alpha in least squares sense is closed-form:
    %   alpha*(T) = (B(T)'*P) / (B(T)'*B(T))
    alpha_for_T = @(T) local_alpha_closed_form(lambda_um, P, planck_W_m3_sr, T);

    sse_for_T = @(T) local_sse(lambda_um, P, planck_W_m3_sr, T, alpha_for_T(T));

    % --------------------------
    % 2) Coarse T search (robust init)
    % --------------------------
    % Reasonable Io thermal ranges often lie ~700–2000 K (but keep wider).
    T_lb = 200;     % K
    T_ub = 6000;    % K
    T_grid = logspace(log10(300), log10(4000), 120); % coarse but dense

    sse_vals = zeros(size(T_grid));
    for i = 1:numel(T_grid)
        sse_vals(i) = sse_for_T(T_grid(i));
    end

    [~, iBest] = min(sse_vals);
    T0     = T_grid(iBest);
    alpha0 = alpha_for_T(T0);

    % Guard against degenerate alpha0
    if ~isfinite(alpha0) || alpha0 <= 0
        alpha0 = max(P) / max(planck_W_m3_sr(lambda_um, max(T0, 300)));
        if ~isfinite(alpha0) || alpha0 <= 0
            alpha0 = 1;
        end
    end

    % --------------------------
    % 3) Refinement (2-parameter)
    % --------------------------
    lb = [T_lb,  0];
    ub = [T_ub,  Inf];
    p0 = [T0, alpha0];

    if exist('lsqcurvefit','file') == 2
        opts = optimoptions('lsqcurvefit', 'Display', 'off', 'MaxFunctionEvaluations', 2e4, 'MaxIterations', 2e3);
        p = lsqcurvefit(model_fun, p0, lambda_um, P, lb, ub, opts);
    else
        % Use fminsearch on a *bounded* reparameterization:
        %   Let t = logit((T - T_lb)/(T_ub - T_lb)), a = log(alpha)
        to_params   = @(q) [ T_lb + (T_ub - T_lb) ./ (1 + exp(-q(1))) , exp(q(2)) ];
        from_params = @(p) [ log((p(1)-T_lb)/(T_ub - p(1))) , log(max(p(2), eps)) ];

        q0 = from_params(p0);
        cost = @(q) mean((P - model_fun(to_params(q), lambda_um)).^2);
        opts = optimset('Display','off', 'MaxFunEvals', 2e5, 'MaxIter', 2e4);
        q = fminsearch(cost, q0, opts);
        p = to_params(q);
    end

    T     = p(1);
    alpha = p(2);

    % --------------------------
    % 4) Plot ONLY over data span
    % --------------------------
    figure('Color','w'); hold on; box on; grid on;
    scatter(lambda_um, P, 64, 'filled', 'DisplayName','data');

    xmin = min(lambda_um); xmax = max(lambda_um);
    if xmin == xmax
        xmin = max(1e-3, xmin - 1e-3);
        xmax = xmax + 1e-3;
    end
    wgrid = linspace(xmin, xmax, 600).';
    plot(wgrid, model_fun([T, alpha], wgrid), 'LineWidth', 1.8, ...
        'DisplayName', sprintf('fit: T = %.0f K', T));

    xlabel('Wavelength [\mum]');
    ylabel('Brightness [arb.]');
    title('Scaled Planck fit (data range)');
    legend('Location','best');

end

% =======================
% ====== HELPERS ========
% =======================

function B = local_planck_lambda(lambda_um, T)
% Planck spectral radiance per wavelength B_λ(T)
%   B_λ(T) = (2hc^2 / λ^5) * 1/(exp(hc/(λ k T)) - 1)
% Inputs:
%   lambda_um : µm
%   T         : K
% Output:
%   B         : W·m^-3·sr^-1   (units absorbed by α in the fit)
    h  = 6.62607015e-34;  % J·s
    c  = 299792458;       % m/s
    kB = 1.380649e-23;    % J/K

    lambda_m = max(lambda_um(:), eps) * 1e-6;  % column, guard 0
    x = (h*c) ./ (lambda_m * kB * T);          % dimensionless
    % numerical stability: use expm1 where helpful
    denom = expm1(x);                          % = exp(x)-1, stable near 0
    Bl = (2*h*c^2) ./ (lambda_m.^5 .* denom);  % W·m^-3·sr^-1
    B = reshape(Bl, size(lambda_um));
end

function alpha = local_alpha_closed_form(lambda_um, P, planck_fun, T)
% Closed-form least-squares α for fixed T:
%   α = (B'P) / (B'B)
    B = planck_fun(lambda_um, T);
    num = sum(B .* P, 'omitnan');
    den = sum(B .* B, 'omitnan');
    if den <= 0 || ~isfinite(den)
        alpha = NaN;
    else
        alpha = num / den;
    end
end

function s = local_sse(lambda_um, P, planck_fun, T, alpha)
% Sum of squared errors for given T and α
    if ~isfinite(alpha) || alpha <= 0
        s = inf;
        return
    end
    R = P - alpha * planck_fun(lambda_um, T);
    s = sum(R.^2, 'omitnan');
end
