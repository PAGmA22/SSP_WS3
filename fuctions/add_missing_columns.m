function return_data = add_missing_columns(data, need, types, widths)
    if nargin < 4
        widths = ones(size(need));   % default scalar width
    end

    h = height(data);

    for k = 1:numel(need)
        v  = need{k};
        tk = types{k};
        wk = widths(k);

        if ~istable(data)
            error('data must be a table.');
        end

        if ~ismember(v, data.Properties.VariableNames)
            % create new column with correct type/shape
            switch lower(tk)
                case 'double'
                    if wk > 1, data.(v) = NaN(h, wk); else, data.(v) = NaN(h,1); end
                case 'string'
                    data.(v) = strings(h,1);         % "" not "0"
                case 'logical'
                    data.(v) = false(h,1);
                case 'datetime'
                    data.(v) = NaT(h,1);
                case 'cell'
                    data.(v) = cell(h,1);
                case 'categorical'
                    data.(v) = categorical(zeros(h,1)); % all <undefined>
                otherwise
                    % fallback: try class constructor on zeros, but warn
                    warning('add_missing_columns:unknownType',...
                        'Unknown type "%s" for "%s". Creating cell column.', tk, v);
                    data.(v) = cell(h,1);
            end
        else
            % if it exists but is a double with wrong width, fix shape
            if strcmpi(tk,'double')
                if size(data.(v),2) ~= wk
                    if wk > 1, data.(v) = NaN(h, wk); else, data.(v) = NaN(h,1); end
                end
            end
        end
    end

    return_data = data;
end
