% =========================================================================
%  WSN Coverage Optimization using Puma Optimizer Algorithm (POA)
%
%  Repository: WSN-Puma-Optimization
%  File: Coverage_Optimization/main_coverage.m
%
%  Problem:
%    Optimal placement of N sensors to maximize area coverage while
%    maintaining network connectivity (communication coverage).
%
%  Decision Variables:
%    2*Nsensors continuous variables representing (x,y) coordinates
%    of each sensor in a Region_Size × Region_Size grid.
%
%  Objective (minimization):
%    cost = (1 / CoverageRate) + PenaltyCoef * ConnectivityPenalty
%
%  Usage:
%    Run this script directly. Results and figures are saved to Results/.
%
%  Dependencies:
%    Algorithm/Puma.m, Algorithm/Exploration.m, Algorithm/Exploitation.m,
%    Coverage_Optimization/Calculate_Cost.m,
%    Coverage_Optimization/DrawFinalResult.m
% =========================================================================

clear all; close all; clc %#ok

%% -----------------------------------------------------------------------
%  Global Network Parameters
% -----------------------------------------------------------------------
global Region Region_Size Nsensors SensRange CommRange PenaltyCoef Area

Region_Size  = 160;                    % Grid dimension (pixels)
Region       = ones(Region_Size);      % 1 = coverable cell, 0 = obstacle
Nsensors     = 60;                     % Number of sensors to deploy
SensRange    = 10;                     % Sensing radius (pixels)
CommRange    = 20;                     % Communication radius (pixels)
PenaltyCoef  = 1;                      % Weight for connectivity penalty
Area         = sum(Region(:));         % Total coverable area

%% -----------------------------------------------------------------------
%  Puma Optimizer Parameters
% -----------------------------------------------------------------------
Npop   = 50;                           % Population size
Max_it = 500;                          % Maximum iterations
nD     = 2 * Nsensors;                 % Decision-variable dimension

lb   = ones(1, nD);                    % Lower bound: coordinate >= 1
ub   = Region_Size * ones(1, nD);      % Upper bound: coordinate <= Region_Size
fobj = @Calculate_Cost;

%% -----------------------------------------------------------------------
%  Run Optimization
% -----------------------------------------------------------------------
tic;
[Puma_X, Puma_C, Convergence] = Puma(Npop, Max_it, lb, ub, nD, fobj);
elapsedTime = toc;

fprintf('\nTotal computation time : %.2f seconds\n', elapsedTime);

%% -----------------------------------------------------------------------
%  Convergence Plot
% -----------------------------------------------------------------------
figure('Name', 'POA Convergence – Coverage');

subplot(2,1,1)
plot(Convergence, 'b', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Best Fitness (Cost)');
title('POA Convergence Curve');
grid on;

%% -----------------------------------------------------------------------
%  Final Coverage Rate
% -----------------------------------------------------------------------
[~, finalRate] = Calculate_Cost(Puma_X);
fprintf('Final coverage rate    : %.2f%%\n', finalRate * 100);

%% -----------------------------------------------------------------------
%  Visualize Optimal Sensor Deployment
% -----------------------------------------------------------------------
figure('Name', 'Optimal Sensor Deployment');
DrawFinalResult(Puma_X, SensRange, CommRange, Region_Size);
title(sprintf('Optimal Sensor Placement  |  Coverage Rate: %.2f%%', finalRate * 100));
