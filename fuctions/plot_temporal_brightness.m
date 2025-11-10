function plot_temporal_brightness(dates, brightness, varargin)
%PLOT_TEMPORAL_BRIGHTNESS  Plot brightness as a function of observation time.
%
%   plot_temporal_brightness(dates, brightness)
%   plot_temporal_brightness(dates, brightness, 'Title', 'Volcano brightness')
%
%   INPUTS
%     dates       : array of datetimes, strings, or char (e.g. "2025-01-12 15:46:12.821")
%     brightness  : numeric array of same length
%
%   OPTIONAL NAME-VALUE PAIR
%     'Title'     : title text (default: 'Temporal brightness evolution')
%
%   BEHAVIOR
%     • Converts string/char dates to datetime automatically.
%     • Sorts data chronologically.
%     • Plots with dots + connecting line.
%     • Labels axes and uses readable time ticks.

    % --- Parse optional title
    p = inputParser;
    addParameter(p, 'Title', 'Temporal brightness evolution', @ischar);
    parse(p, varargin{:});
    plotTitle = p.Results.Title;

    % --- Validate inputs
    if nargin < 2
        error('Provide both date and brightness arrays.');
    end
    if numel(dates) ~= numel(brightness)
        error('dates and brightness must have the same length.');
    end

    % --- Convert dates if needed
    if iscellstr(dates) || isstring(dates) || ischar(dates)
        try
            dates = datetime(dates, 'InputFormat','yyyy-MM-dd HH:mm:ss.SSS', 'TimeZone','UTC');
        catch
            % fallback if milliseconds missing
            dates = datetime(dates, 'InputFormat','yyyy-MM-dd HH:mm:ss', 'TimeZone','UTC');
        end
    end

    % --- Sort chronologically
    [dates, idx] = sort(dates);
    brightness = brightness(idx);

    % --- Plot
    figure('Color','w'); hold on; box on; grid on;
    plot(dates, brightness, '-o', 'LineWidth', 1.4, 'MarkerSize', 6, ...
        'MarkerFaceColor', [0.2 0.5 0.9], 'Color', [0.2 0.5 0.9]);
    xlabel('Observation Time (UTC)');
    ylabel('Brightness [arb. units]');
    title(plotTitle);
    datetick('x','keepticks');
    grid minor;

    % --- Adjust axes & annotate extrema
    xlim([min(dates) max(dates)]);
    [maxVal, iMax] = max(brightness);
    text(dates(iMax), maxVal, sprintf('  Max: %.2f', maxVal), 'VerticalAlignment','bottom');
    [minVal, iMin] = min(brightness);
    text(dates(iMin), minVal, sprintf('  Min: %.2f', minVal), 'VerticalAlignment','top');

end
