% Gabriel Spethmann
% Workshop 3 Solar System Physics


%% Add Path

% add paths
addpath("C:\Users\gabri\Documents\SolarSystemPhysics\WS1");
addpath("C:\Users\gabri\Documents\SolarSystemPhysics\WS3");
addpath("C:\Users\gabri\Documents\SolarSystemPhysics\WS3\fuctions\");


%% Start all needed Kernals

% This loads all kernals from WS1

% You may have to manually load the Kernals if this .m file is not
% avaliable to you
start_kernals


%% Initialize the main data file as table
clear data
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


%% All default operations to get the basic structure

data = collect_fits_data(data);
data = collect_spice_data(data);
data = calculate_center_of_planet(data);
data = calculate_brightest_point(data);

% get brightness values
data = calculate_volcano_brightness(data,4,7);

data = get_nonvulcanic_point(data,1,15);
data = calculate_nonvolcanic_brightness(data,6);

% seperate spectral from temporal data
spectralData = data(1:7, :); % Extract spectral data
spectralData = sortrows(spectralData, 'wavelength', 'ascend');
temporalData = data(8:end, :); % Extract temporal data
temporalData = sortrows(temporalData, 'time','ascend');

% fit plank for spectral data
temp_vul = fit_planck_from_arrays(spectralData.wavelength,spectralData.volcano_brightness);
temp_nonvul = fit_planck_from_arrays(spectralData.wavelength,spectralData.nonvolcanic_brightness);

spectralData = removevars(spectralData,"path");
spectralData;

temporalData
plot_temporal_brightness(temporalData.time,temporalData.volcano_brightness);


