function [lon_deg, lat_deg] = io_subobs_lonlat(utc_str)

% returns the point on Io as seen from earth in earth time.
% Planetocentric
% West-Positive
% Kernal needs to be loaded ET Kernal and Jup (Io) Kernal jup365 is good
    % Improvement could be made here (Check and in case missing => load)

    arguments
        utc_str (1,:) char
    end

    % Convert time to ET
    et = cspice_str2et(utc_str);

    % Sub-observer point on Io's ellipsoid in body-fixed frame
    [spoint, ~, ~] = cspice_subpnt( ...
        'Intercept: ellipsoid', ...    % method
        'IO', ...                      % target
        et, ...                        % epoch (ET)
        'IAU_IO', ...                  % body-fixed frame
        'LT+S', ...                    % light-time + stellar aberration
        'EARTH');                      % observer

    % Planetocentric lon and lat
    [ ~, lon, lat ] =cspice_reclat( spoint ) ;

    % in degree
    lon_deg = lon * cspice_dpr;
    lat_deg = lat * cspice_dpr;

    % Adjust longitude to be west-positive
    lon_deg = mod(360-lon_deg,360);

    
end
