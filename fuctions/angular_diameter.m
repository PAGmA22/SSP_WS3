function ang_diam_arcsec = angular_diameter(target, observer, utc_str)
%ANGULAR_DIAMETER  Apparent angular diameter (arcseconds) of target as seen from observer.
%
%   ang_diam_arcsec = angular_diameter('IO','EARTH','2015-01-12 15:46:12.821')
%
% Inputs:
%   target   - name or NAIF ID of the target body (e.g. 'IO', 'JUPITER')
%   observer - name or NAIF ID of the observer (e.g. 'EARTH', 'CASSINI')
%   utc_str  - UTC time string ('YYYY-MM-DD HH:MM:SS[.fff]')
%
% Output:
%   ang_diam_arcsec - apparent angular diameter [arcseconds]
%
% Requires:
%   Furnished SPICE kernels: LSK, PCK, and SPKs covering both bodies.

    % Convert UTC → ET
    et = cspice_str2et(char(utc_str));

    % Apparent position (target→observer) with light-time + stellar aberration
    [pos, ~] = cspice_spkpos(target, et, 'J2000', 'LT+S', observer);
    range = norm(pos);  % [km]

    % Mean radius of the target
    radii = cspice_bodvrd(target, 'RADII', 3);
    Rmean = mean(radii);  % [km]

    % Angular diameter [radians]
    ang_rad = 2 * asin(Rmean / range);

    % Convert radians → arcseconds (1 rad = 206,264.806 arcsec)
    ang_diam_arcsec = ang_rad * 206264.806;
end
