function value = getFitsKeywordValue(fits_file_path, keyword)
%GETFITSKEYWORDVALUE  Return the value of a keyword from a FITS file header
%
%   value = GETFITSKEYWORDVALUE(fits_file_path, keyword)
%
%   Example:
%       v = getFitsKeywordValue('example.fits', 'EXPSTART');

    % Read FITS file info
    info = fitsinfo(fits_file_path);

    % Collect all keyword tables (PrimaryData + extensions)
    allHeaders = {};
    if isfield(info, 'PrimaryData')
        allHeaders{end+1} = info.PrimaryData.Keywords;
    end
    if isfield(info, 'Image')
        for i = 1:numel(info.Image)
            allHeaders{end+1} = info.Image(i).Keywords;
        end
    end
    if isfield(info, 'Table')
        for i = 1:numel(info.Table)
            allHeaders{end+1} = info.Table(i).Keywords;
        end
    end

    % Search through all headers
    value = [];
    for i = 1:numel(allHeaders)
        header = allHeaders{i};
        idx = strcmp(header(:,1), keyword);
        if any(idx)
            value = header{idx,2};
            return
        end
    end

    % If not found, throw an error
    error('Keyword "%s" not found in any FITS header.', keyword);
end
