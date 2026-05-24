% =========================================================================
%  Multi-Objective Fitness Function for CH Selection
%  WSN Simulation: Energy-Efficient Routing
%
%  Repository: WSN-Puma-Optimization
%  File: Energy_Efficient_Routing/ObjectiveFunction.m
%
%  Description:
%    Evaluates the quality of a Cluster Head selection by combining five
%    weighted sub-objectives plus a CH→BS transmission energy penalty.
%
%  Fitness Components:
%    wf1 : Inverse of CH residual energy      (energy awareness)
%    wf2 : Sum of node-to-nearest-CH distances (load distribution)
%    wf3 : Sum of CH-to-nearest-BS distances  (BS proximity)
%    wf4 : Node degree within radius R        (connectivity)
%    wf5 : Spatial centrality of CHs          (distribution quality)
%
%  Inputs:
%    CH_positions : 1 × m vector of CH node indices
%    nodePositions: N × 2 coordinate matrix of all nodes
%    BS_positions : K × 2 base-station coordinates
%    nodeEnergy   : N × 1 remaining energy vector
%    networkDim   : network area dimension (m)
%    weights      : 1 × 5 weight vector  [w1 w2 w3 w4 w5]
%    packetSize   : packet length (bits)
%    Eelec        : electronics energy (J/bit)
%    Eamp         : amplifier energy – multi-path (J/bit/m^4)
%    xi_free      : amplifier energy – free space (J/bit/m^2)
%    d0           : cross-over distance (m)
%    N            : total number of nodes
%
%  Output:
%    fitness : scalar minimization objective
% =========================================================================

function fitness = ObjectiveFunction(CH_positions, nodePositions, BS_positions, ...
                                     nodeEnergy, networkDim, weights, ...
                                     packetSize, Eelec, Eamp, xi_free, d0, N)

% --- Safety: clip and deduplicate CH indices ---
CH_positions = round(CH_positions);
CH_positions(CH_positions < 1) = 1;
CH_positions(CH_positions > N) = N;
CH_positions = unique(CH_positions);

m = length(CH_positions);
N = size(nodePositions, 1);

R = 30;   % Neighbourhood radius for degree / centrality metrics

%% --- wf1: Inverse CH residual energy (energy awareness) ---
wf1 = 0;
for i = 1:m
    id = CH_positions(i);
    if nodeEnergy(id) <= 0
        wf1 = wf1 + 1e6;          % Heavy penalty for selecting a dead node
    else
        wf1 = wf1 + 1 / nodeEnergy(id);
    end
end

%% --- wf2: Total node-to-nearest-CH distance (load distribution) ---
wf2 = 0;
for i = 1:N
    minDist = inf;
    for j = 1:m
        d = norm(nodePositions(i,:) - nodePositions(CH_positions(j),:));
        if d < minDist
            minDist = d;
        end
    end
    wf2 = wf2 + minDist;
end

%% --- wf3: Total CH-to-nearest-BS distance (BS proximity) ---
wf3 = 0;
for i = 1:m
    ch_id    = CH_positions(i);
    dists_bs = vecnorm(nodePositions(ch_id,:) - BS_positions, 2, 2);
    wf3      = wf3 + min(dists_bs);
end

%% --- wf4: Node degree – number of neighbours within radius R ---
wf4 = 0;
for i = 1:m
    ch_id = CH_positions(i);
    count = 0;
    for j = 1:N
        if j ~= ch_id
            if norm(nodePositions(ch_id,:) - nodePositions(j,:)) <= R
                count = count + 1;
            end
        end
    end
    wf4 = wf4 + count;
end

%% --- wf5: Spatial centrality (distribution quality) ---
wf5 = 0;
for i = 1:m
    ch_id     = CH_positions(i);
    neighbors = [];
    for j = 1:N
        if j ~= ch_id && norm(nodePositions(ch_id,:) - nodePositions(j,:)) <= R
            neighbors = [neighbors; nodePositions(j,:)]; %#ok
        end
    end
    n_i = size(neighbors, 1);
    if n_i > 0
        sum_dist2 = sum(vecnorm(neighbors - nodePositions(ch_id,:), 2, 2).^2);
        wf5 = wf5 + (sum_dist2 / n_i) / networkDim;
    else
        wf5 = wf5 + 1e3;   % Penalty for isolated CH
    end
end

%% --- Energy Penalty: CH → BS transmission cost ---
energy_penalty = 0;
for i = 1:m
    ch_id       = CH_positions(i);
    dist_to_bs  = min(vecnorm(nodePositions(ch_id,:) - BS_positions, 2, 2));
    if dist_to_bs < d0
        Etx_bs = Eelec * packetSize + xi_free * packetSize * dist_to_bs^2;
    else
        Etx_bs = Eelec * packetSize + Eamp   * packetSize * dist_to_bs^4;
    end
    energy_penalty = energy_penalty + Etx_bs;
end

%% --- Weighted Fitness ---
fitness = weights(1)*wf1 + weights(2)*wf2 + weights(3)*wf3 + ...
          weights(4)*wf4 + weights(5)*wf5 + energy_penalty;

end
