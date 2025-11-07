% Gabriel Spethmann
% Workshop 3 Solar System Physics

%% Start all needed Kernals

% This loads all kernals from WS1

% You may have to manually load the Kernals if this .m file is not
% avaliable to you
start_kernals

%% Initialize the main data file as table
files = [
    % Spectral data
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckBra_15jan12_bra10_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckBrac_15jan12_brac13_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckH2O_15jan12_hho16_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckKc_15jan12_kc1_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckLp_15jan12_lp4_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckMs_15jan12_ms7_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\spectral_files\KeckPAH_15jan12_pah19_GW.fits"
    % Temporal data
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_17jan03_ms31_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_15nov23_ms7_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_15mar31_ms42_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_15jan12_ms7_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_15apr02_ms48_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_14feb10_ms37_GW.fits"
    "C:\Users\gabri\Documents\SolarSystemPhysics\WS3\temporal_files\KeckMs_14dec02_ms7_GW.fits"
];


data = table('Size',[numel(files),1], ...
    'VariableTypes', {'string'}, ...
    'VariableNames', {'path'});

data.path = files;

data = collect_fits_data(data);
data = collect_spice_data(data);
data = calculate_center_of_planet(data);
data = calculate_brightest_point(data);


% Convert the time column to datetime
data.time = datetime(data.time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

% Sort ascending by time
data = sortrows(data, 'time');

data.time

X = data.brightest_point_xy - data.image_center_xy;
X(4:8,:)