clear all

% --- Define file list ---
files = [
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckBra_15jan12_bra10_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckBrac_15jan12_brac13_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckH2O_15jan12_hho16_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckKc_15jan12_kc1_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckLp_15jan12_lp4_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckMs_15jan12_ms7_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckPAH_15jan12_pah19_GW.fits"
];
%{
% --- Start Kernels ---
addpath("C:\Users\gabri\Documents\SolarSystemPhysics\WS1");
start_kernals;

% --- Preallocate table with column names ---
fitsData = table('Size',[numel(files),6], ...
    'VariableTypes', {'string','string','double','double','double','double'}, ...
    'VariableNames', {'path','time','lon','lat', 'ang_dia','wavelength'});

% --- Extract / Calculate Data ---
for i = 1:numel(files)
    f = files(i);
    fitsData.path(i) = f;

    try
        date = string(getFitsKeywordValue(f, "DATE-OBS"));
        start = string(getFitsKeywordValue(f, "EXPSTART"));
        fitsData.time(i) = date + " " + start;

    catch
        fitsData.time(i) = "<missing>";
    end

    try
       
        [lon, lat] = io_subobs_lonlat(char(fitsData.time(i)));
        fitsData.lon(i) = lon;
        fitsData.lat(i) = lat;
    catch
        fitsData.lon(i) = NaN;
        fitsData.lat(i) = NaN;
    end

    try
        fitsData.ang_dia(i) = angular_diameter('IO','Earth',fitsData.time(i));
    catch
        fitsData.ang_dia(i) = "<missing>";
    end

    try
        fitsData.wavelength(i) = string(getFitsKeywordValue(f, "TARGWAVE"));
    catch
        fitsData.wavelength(i) = "<missing>";
    end


        
 

end

% --- sort ---
fitsData = sortrows(fitsData, "wavelength", "ascend");



% --- Display results nicely ---
disp(fitsData);
%}
for i = 1:7
    fitsdisp(files(i),Mode="full")
end
