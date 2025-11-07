%% FUNCTION ws3_fitsReading_comet
%  version/date : version 00, 20221013
%  author       : Lorenz Roth - lorenzr@kth.se
%  for KTH course EF2243 - Workshop 3              
%   modified by XXX

%% DESCRIPTION
%
%  INPUT:   DATADIR         Path
%           OBSERVATION     Name fits-file.
% 
%  OUTPUT:  FITSDATASET     FITS-Image + additional Information
%  (header) about dispersion, central wavelength, etc.
%



%  Example:
           DATADIR     = './spectral_files/';
           FITSFILE = 'KeckPAH_15jan12_pah19_GW';           % root name of file
           
    FITSDF     = [ DATADIR FITSFILE '.fits' ] ;
    
    
% Read FITS-file:
     
    FITSINFO     = fitsinfo(FITSDF);   % read header information into structure
        
    FITSDATASET   = fitsread(FITSDF);  % spectral irradiance per pixel I(x, y) [counts]
    
    [row,col]       = size(FITSDATASET); % Number of rows and column / image dimension


%% --- Plot raw image ----

    img_plot=FITSDATASET; % multiply with 1e15 to be close to 1

    figure(1);
    
    imagesc(img_plot); 
      
    set(gca,'ydir','nor') ;  % Define y axis to increase from bottom to top
    axis equal
    xlim([1 col]);
    ylim([1 row]); 
    xlabel('pixel');
    ylabel('pixel'); 

    % display colorbar
    c = colorbar;
    c.Label.String = 'Intensity [GW]';
    c.Label.FontSize = 11;
    clear c
    caxis; % set colormap axis limits
     
    
 