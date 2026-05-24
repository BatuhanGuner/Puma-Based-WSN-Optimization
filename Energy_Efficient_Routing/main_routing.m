% =========================================================================
%  WSN Energy-Efficient Routing using Puma Optimizer Algorithm (POA)
%
%  Repository: WSN-Puma-Optimization
%  File: Energy_Efficient_Routing/main_routing.m
%
%  Problem:
%    Select m Cluster Heads (CHs) from N sensor nodes to minimise a
%    multi-objective fitness (energy, coverage, BS proximity, degree,
%    centrality).  Network lifetime is then simulated round-by-round
%    using a first-order radio energy model.
%
%  Decision Variables:
%    m continuous values in [1, N], each representing a CH node index.
%
%  Dependencies:
%    Algorithm/Puma.m, Algorithm/Exploration.m, Algorithm/Exploitation.m,
%    Energy_Efficient_Routing/ObjectiveFunction.m,
%    Energy_Efficient_Routing/NetworkLifetime.m
% =========================================================================

clc; clear all; close all; %#ok

%% -----------------------------------------------------------------------
%  Network Parameters
% -----------------------------------------------------------------------
networkDim    = 100;                    % Area dimension (m)
N             = 50;                     % Number of sensor nodes
BS_positions  = [100, 50; 100, 100];   % Dual base-station coordinates
InitialEnergy = 1.5;                   % Initial energy per node (J)

%% -----------------------------------------------------------------------
%  Radio Energy Model Parameters  (first-order model)
% -----------------------------------------------------------------------
packetSize = 4000;       % Packet size (bits)
Eelec      = 50e-9;      % Electronics energy  (J/bit)
Eamp       = 0.0013e-12; % Amplifier energy – multi-path fading (J/bit/m^4)
xi_free    = 10e-12;     % Amplifier energy – free-space model (J/bit/m^2)
d0         = 35;         % Cross-over distance (m)

%% -----------------------------------------------------------------------
%  Cluster Head Selection Parameters
% -----------------------------------------------------------------------
CHpercent = 0.15;
m         = round(N * CHpercent);   % Number of CHs

dim = m;
lb  = ones(1, dim);
ub  = N * ones(1, dim);

%% -----------------------------------------------------------------------
%  Random Node Deployment
% -----------------------------------------------------------------------
rng(42);   % Fix seed for reproducibility
nodePositions = networkDim * rand(N, 2);
nodeEnergy    = InitialEnergy * ones(N, 1);

%% -----------------------------------------------------------------------
%  Objective Function Handle
% -----------------------------------------------------------------------
weights = [0.25, 0.25, 0.20, 0.15, 0.15];

CostFunction = @(CH_vector) ObjectiveFunction( ...
    round(CH_vector), nodePositions, BS_positions, nodeEnergy, ...
    networkDim, weights, packetSize, Eelec, Eamp, xi_free, d0, N);

%% -----------------------------------------------------------------------
%  Run Puma Optimizer
% -----------------------------------------------------------------------
nSol    = 30;
MaxIter = 500;

fprintf('Running Puma Optimizer for CH selection...\n');
[Puma_X, Puma_C, Convergence] = Puma(nSol, MaxIter, lb, ub, dim, CostFunction);

CH_IDs = unique(round(Puma_X));
CH_IDs(CH_IDs < 1) = 1;
CH_IDs(CH_IDs > N) = N;

fprintf('\nOptimal Cluster Head IDs:\n');
disp(CH_IDs);
fprintf('Best objective function value: %.6f\n\n', Puma_C);

%% -----------------------------------------------------------------------
%  Convergence Plot
% -----------------------------------------------------------------------
figure('Name', 'POA Convergence – Routing');
plot(Convergence, 'b', 'LineWidth', 2);
xlabel('Iteration');
ylabel('Objective Function Value');
title('POA Convergence Curve – Energy-Efficient Routing');
grid on;

%% -----------------------------------------------------------------------
%  Network Lifetime Simulation
% -----------------------------------------------------------------------
fprintf('Simulating network lifetime...\n');
[aliveNodes, deadNodes, totalEnergy, deathRound] = ...
    NetworkLifetime(nodePositions, nodeEnergy, CH_IDs, BS_positions, ...
                    N, packetSize, Eelec, Eamp, xi_free, d0);

%% -----------------------------------------------------------------------
%  Lifetime Results
% -----------------------------------------------------------------------
firstDeadRound = find(aliveNodes < N, 1);
if isempty(firstDeadRound)
    fprintf('No node died during simulation.\n');
else
    fprintf('First node died at round %d.\n', firstDeadRound);
end

fprintf('\nNode death rounds:\n');
for i = 1:N
    fprintf('  Node %3d  -->  round %5d\n', i, deathRound(i));
end

%% -----------------------------------------------------------------------
%  Network Lifetime Plots
% -----------------------------------------------------------------------
maxRounds = length(aliveNodes);

figure('Name', 'Network Lifetime Results');

subplot(3,1,1)
plot(1:maxRounds, aliveNodes, 'g', 'LineWidth', 1.5);
xlabel('Round'); ylabel('Alive Nodes');
title('Number of Alive Nodes vs. Round');
grid on;

subplot(3,1,2)
plot(1:maxRounds, deadNodes, 'r', 'LineWidth', 1.5);
xlabel('Round'); ylabel('Dead Nodes');
title('Number of Dead Nodes vs. Round');
grid on;

subplot(3,1,3)
plot(1:maxRounds, totalEnergy, 'b', 'LineWidth', 1.5);
xlabel('Round'); ylabel('Total Remaining Energy (J)');
title('Total Network Energy vs. Round');
grid on;
