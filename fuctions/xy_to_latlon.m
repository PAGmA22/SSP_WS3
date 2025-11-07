
function [lon, lat] = xy_to_latlon(x, y, radius, subearthlat, subearthlon, NPangle)
    % subearthlat, subearthlon, and NPangle all in degrees
    % x and y are coordinates relative to the center of the disk
    % the units of x, y, and radius don't matter as long as they are all the same
    % Positive X => West
    % Positive Y => North

    if nargin<6; NPangle = 0.;    end %default is 0 if missing
    if nargin<5; subearthlon = 0; end %default is 0 if missing
    if nargin<4; subearthlat = 0; end %default is 0 if missing
    if nargin<3; radius = 0;      end %default is 0 if missing
    
    dtor = pi/180;

    yE = y;
    xE = x;
    zE = sqrt(radius.^2 - xE.^2 - yE.^2);
    
    a = NPangle*dtor;
    zEp = zE;
    yEp = yE*cos(a) - xE*sin(a);
    xEp = xE*cos(a) + yE*sin(a);

    a = subearthlat*dtor;
    x2 = xEp;
    y2 = yEp*cos(a) + zEp*sin(a);
    z2 = zEp*cos(a) - yEp*sin(a);

    a = subearthlon*dtor;
    yp = y2;
    zp = z2*cos(a) + x2*sin(a);
    xp = x2*cos(a) - z2*sin(a);

    lon = mod( atan2(-xp,zp)/dtor + 360.*6. ,360.);
    lat = asin(yp/radius)/dtor;

end

    