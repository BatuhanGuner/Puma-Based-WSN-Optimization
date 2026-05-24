% =========================================================================
%  Coverage & Connectivity Cost Function
%  WSN Simulation: Coverage Optimization
%
%  Repository: WSN-Puma-Optimization
%  File: Coverage_Optimization/Calculate_Cost.m
%
%  Description:
%    Evaluates the cost of a sensor deployment given by the decision
%    vector `position`.  The cost combines area-coverage rate and a
%    connectivity penalty for isolated sensors.
%
%  Inputs:
%    position : 1 × (2*Nsensors) vector
%               [x1, y1, x2, y2, ..., xN, yN]
%
%  Outputs:
%    cost : scalar minimization objective
%           cost = (1/Rate) + PenaltyCoef * ConnectivityPenalty
%    Rate : fraction of Region covered by at least one sensor  [0,1]
%
%  Global variables (set in main_coverage.m):
%    Region, Region_Size, Nsensors, SensRange, CommRange, PenaltyCoef, Area
% =========================================================================

function [cost, Rate] = Calculate_Cost(position)

global Region Region_Size Nsensors SensRange CommRange PenaltyCoef Area

% 3-D coverage / communication maps  (row × col × sensor)
cover = zeros(Region_Size, Region_Size, Nsensors);
comm  = zeros(Region_Size, Region_Size, Nsensors);

% Sensor coordinate matrix  (Nsensors × 2)
Sensors = zeros(Nsensors, 2);

%% --- Extract & Clip Sensor Coordinates ---
for i = 1:Nsensors
    x = round(position(2*i - 1));
    y = round(position(2*i));
    x = min(max(x, 1), Region_Size);
    y = min(max(y, 1), Region_Size);
    Sensors(i, :) = [x, y];
end

%% --- Coverage Computation ---
% Cone parameters: full circle (−180° to 180°)
theta1 = -180;  theta2 = 180;
r_min  = 0;

[xG, yG] = meshgrid(1:Region_Size);

for s = 1:Nsensors
    x0 = Sensors(s, 1);
    y0 = Sensors(s, 2);
    r_max = SensRange;

    mask = (xG - x0).^2 + (yG - y0).^2 <= r_max^2  & ...
           (xG - x0).^2 + (yG - y0).^2 >= r_min^2  & ...
           atan2(yG - y0, xG - x0) >= theta1        & ...
           atan2(yG - y0, xG - x0) <= theta2;

    cover(:,:,s) = mask .* Region;
end

% Union coverage across all sensors
TotalCover = any(cover, 3);
Rate = sum(TotalCover(:)) / Area;

%% --- Communication Computation ---
for s = 1:Nsensors
    x0 = Sensors(s, 1);
    y0 = Sensors(s, 2);
    r_max = CommRange;

    mask = (xG - x0).^2 + (yG - y0).^2 <= r_max^2  & ...
           (xG - x0).^2 + (yG - y0).^2 >= r_min^2  & ...
           atan2(yG - y0, xG - x0) >= theta1        & ...
           atan2(yG - y0, xG - x0) <= theta2;

    mask(x0, y0) = 0;          % A node cannot communicate with itself
    comm(:,:,s)  = mask .* Region;
end

TotalCommunicate = any(comm, 3);

%% --- Connectivity Penalty ---
uncoveredSensors = 0;
for s = 1:Nsensors
    x = Sensors(s, 1);
    y = Sensors(s, 2);
    if TotalCommunicate(x, y) == 0
        uncoveredSensors = uncoveredSensors + 1;
    end
end

Penalty = uncoveredSensors / Nsensors;

%% --- Final Cost ---
cost = (1 / Rate) + (PenaltyCoef * Penalty);

end
