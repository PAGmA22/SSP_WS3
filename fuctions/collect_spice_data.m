function return_data = collect_spice_data(data)
    

    %% Arguments
    arguments
        data table = table()
    end
    

    %% Add Columns if necessary
    need = {'central_point_lonlat','angular_diameter_arcsec'};
    types = {'double','double'};
    widths = [2,1];
    data = add_missing_columns(data,need,types,widths);

    
   %% Calculate the data
    
    for i = 1:height(data)
        try
            [lon, lat] = io_subobs_lonlat(char(data.time(i)));
            data.central_point_lonlat(i,:) = [lon, lat];
        catch
            data.central_point_lonlat(i,:) = [NaN, NaN];
        end
    
        try
            data.angular_diameter_arcsec(i) = angular_diameter('IO','EARTH', char(data.time(i)));
        catch
            data.angular_diameter_arcsec(i) = NaN;
        end
    end
    
    return_data = data;
end
