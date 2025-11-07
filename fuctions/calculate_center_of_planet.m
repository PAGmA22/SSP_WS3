function return_data = calculate_center_of_planet(data)
%% Arguments
arguments
    data table = table()
end

%% Add Columns if necessary
need   = {'image_center_xy'};
types  = {'double'};
widths = [2];
data   = add_missing_columns(data, need, types, widths);

%% Calculate Center Points
for i = 1:height(data)
    try
        img = fitsread(data.path(i));
        [cx, cy] = limb_center_circle(img);
        data.image_center_xy(i,:) = [cx, cy];
    catch
        data.image_center_xy(i,:) = [NaN, NaN];
    end
end

%% Return
return_data = data;
end
