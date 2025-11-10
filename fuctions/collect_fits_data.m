function return_data = collect_fits_data(data)

    %% Arguments
    arguments
        data table = table()
    end
    
    %% Add Columns if necessary
    need = {'path','time','wavelength'};
    types = {'string','string','double'};
    data = add_missing_columns(data,need,types);

    
    
    %% get metadata from files
    for i = 1:height(data)
    
        try
            date = string(getFitsKeywordValue(data.path(i), "DATE-OBS"));
            time = string(getFitsKeywordValue(data.path(i), "EXPSTART"));
            data.time(i) = date + " " + time;
        catch
            data.time(i) = "<missing>";
        end
    
    
        try
            data.wavelength(i) = double(string(getFitsKeywordValue(data.path(i), "CENWAVE")));
        catch
            data.wavelength(i) = "<missing>";
        end
    end

%% format time

% Convert the time column to datetime
data.time = datetime(data.time, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');

    
%% return data
return_data = data;

end
