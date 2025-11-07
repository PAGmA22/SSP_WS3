function [x, y] = latlon_to_xy(lon, lat, radius, subearthlat, subearthlon, NPangle)
    % LATLON_TO_XY  Convert planetocentric longitude/latitude to image-plane (x, y)
    %
    % INPUT:
    %   lon, lat       - planetocentric longitude and latitude (deg)
    %   radius         - apparent radius of the disk (same units as desired x, y)
    %   subearthlat    - sub-Earth latitude (deg)
    %   subearthlon    - sub-Earth longitude (deg)
    %   NPangle        - north pole position angle, deg CCW from up (North)
    %
    % OUTPUT:
    %   x, y           - coordinates on the projected disk
    %
    % Convention: 
    %   Positive X => West
    %   Positive Y => North
    %
    %   Inverse of xy_to_latlon()

    if nargin<6; NPangle = 0.;    end
    if nargin<5; subearthlon = 0; end
    if nargin<4; subearthlat = 0; end

    dtor = pi/180;

    % ---- Step 1: compute 3D coordinates on sphere in planet frame ----
    x =  radius .* cos(lat*dtor) .* sin(lon*dtor);
    y =  radius .* sin(lat*dtor);
    z =  radius .* cos(lat*dtor) .* cos(lon*dtor);

    % ---- Step 2: rotate by -subearthlon about Y ----
    a = -subearthlon*dtor;
    x2 =  x.*cos(a) + z.*sin(a);
    y2 =  y;
    z2 = -x.*sin(a) + z.*cos(a);

    % ---- Step 3: rotate by -subearthlat about X ----
    a = -subearthlat*dtor;
    x3 =  x2;
    y3 =  y2.*cos(a) - z2.*sin(a);
    z3 =  y2.*sin(a) + z2.*cos(a);

    % ---- Step 4: rotate by -NPangle about Z ----
    a = -NPangle*dtor;
    x4 =  x3.*cos(a) - y3.*sin(a);
    y4 =  x3.*sin(a) + y3.*cos(a);

    % ---- Step 5: projection to image plane ----
    x = x4;
    y = y4;

    % Points on far side will have imaginary values (z3 < 0)
    zobs = z3;
    x(zobs < 0) = NaN;
    y(zobs < 0) = NaN;
end
