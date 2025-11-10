%% PLOT FITS IMAGES (script)

% --- Configuration ---
normalize               = false;        % true/false
show_center             = true;         % true/false
show_brightest          = true;         % true/false
show_non_vulcanic       = true;         % true/false
colormapName            = 'parula';     % e.g., 'gray','parula','hot'
clim                    = [NaN NaN];    % e.g., [0 1]; use [NaN NaN] for auto



hasCenter    = ismember('image_center_xy', data.Properties.VariableNames);
hasBrightest = ismember('brightest_point_xy', data.Properties.VariableNames);
hasnonvol    = ismember('nonvolcanic_point_xy', data.Properties.VariableNames);


for i = 1:height(data)
    fpath = string(data.path(i));
    if strlength(fpath) == 0
        warning('Row %d: empty path, skipping.', i); 
        continue
    end

    try
        img = fitsread(char(fpath));
    catch ME
        warning('Row %d (%s): fitsread failed: %s', i, fpath, ME.message);
        continue
    end

    img = double(img);
    if normalize
        finiteMask = isfinite(img);
        if any(finiteMask(:))
            mn = min(img(finiteMask));
            mx = max(img(finiteMask));
            if mx > mn
                img = (img - mn) / (mx - mn);
            else
                img(:) = 0;
            end
        else
            img(:) = 0;
        end
    end

    figName = sprintf('%s | %s', string(data.time(i)), string(data.wavelength(i)));
    figure('Name', figName, 'NumberTitle', 'off');

    imagesc(img);
    set(gca,'YDir','normal'); axis image tight;
    colormap(colormapName);
    if all(isfinite(clim)), caxis(clim); end
    xlabel('Pixel X'); ylabel('Pixel Y');
    title(figName, 'Interpreter','none');
    cb = colorbar; cb.Label.String = 'Intensity'; cb.Label.FontSize = 10;
    hold on;

    legHandles = []; 
    legLabels  = strings(0,1);

    % Optional overlays: center
    if show_center
        if ~hasCenter
            warning('Row %d: "image_center_xy" not available; center not plotted.', i);
        else
            cxy = data.image_center_xy(i,:);
            if isnumeric(cxy) && numel(cxy)==2 && all(isfinite(cxy))
                h1 = plot(cxy(1), cxy(2), 'y+', 'MarkerSize', 12, 'LineWidth', 1.5);
                legHandles(end+1) = h1; %#ok<AGROW>
                legLabels(end+1)  = "Center";
            else
                warning('Row %d: invalid image_center_xy; center not plotted.', i);
            end
        end
    end

    % Optional overlays: non volcanic
    if show_center
        if ~hasnonvol
            warning('Row %d: "non vol position" not available; point not plotted.', i);
        else
            nvxy = data.nonvolcanic_point_xy(i,:);
            if isnumeric(nvxy) && numel(nvxy)==2 && all(isfinite(nvxy))
                h1 = plot(nvxy(1), nvxy(2), 'b+', 'MarkerSize', 12, 'LineWidth', 1.5);
                legHandles(end+1) = h1; %#ok<AGROW>
                legLabels(end+1)  = "non-volcanic point";
            else
                warning('Row %d: invalid non vulcanic xy; point not plotted.', i);
            end
        end
    end

    % Optional overlays: brightest point
    if show_brightest
        if ~hasBrightest
            warning('Row %d: "brightest_point_xy" not available; brightest not plotted.', i);
        else
            bxy = data.brightest_point_xy(i,:);
            if isnumeric(bxy) && numel(bxy)==2 && all(isfinite(bxy))
                h2 = plot(bxy(1), bxy(2), 'mo', 'MarkerSize', 7, 'LineWidth', 1.5);
                legHandles(end+1) = h2; %#ok<AGROW>
                legLabels(end+1)  = "Brightest";
            else
                warning('Row %d: invalid brightest_point_xy; brightest not plotted.', i);
            end
        end
    end

    if ~isempty(legHandles)
        legend(legHandles, legLabels, 'Location','best');
    else
        legend('off');
    end
end
