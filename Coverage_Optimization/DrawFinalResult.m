% =========================================================================
%  Sensor Deployment Visualization
%  WSN Simulation: Coverage Optimization
%
%  Repository: WSN-Puma-Optimization
%  File: Coverage_Optimization/DrawFinalResult.m
%
%  Description:
%    Draws the final optimized sensor placement on a 2-D grid, showing:
%      - Sensing range circles (blue)
%      - Communication range circles (green, dashed)
%      - Sensor node positions (red markers)
%
%  Inputs:
%    position    : 1 × (2*Nsensors) optimal position vector
%    SensRange   : sensing radius
%    CommRange   : communication radius
%    Region_Size : grid dimension
% =========================================================================

function DrawFinalResult(position, SensRange, CommRange, Region_Size)

global Nsensors

hold on;
axis([0 Region_Size 0 Region_Size]);
axis square;
xlabel('X (pixels)');
ylabel('Y (pixels)');
grid on;

theta = linspace(0, 2*pi, 360);

for i = 1:Nsensors
    x = round(min(max(round(position(2*i - 1)), 1), Region_Size));
    y = round(min(max(round(position(2*i)),     1), Region_Size));

    % --- Sensing range circle (blue, solid) ---
    xs = x + SensRange * cos(theta);
    ys = y + SensRange * sin(theta);
    plot(xs, ys, 'b-', 'LineWidth', 0.8);

    % --- Communication range circle (green, dashed) ---
    xc = x + CommRange * cos(theta);
    yc = y + CommRange * sin(theta);
    plot(xc, yc, 'g--', 'LineWidth', 0.6);

    % --- Sensor node marker ---
    plot(x, y, 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 5);
end

legend({'Sensing range', 'Communication range', 'Sensor node'}, ...
       'Location', 'northeastoutside');
hold off;

end
