% =========================================================================
%  Network Lifetime Simulation
%  WSN Simulation: Energy-Efficient Routing
%
%  Repository: WSN-Puma-Optimization
%  File: Energy_Efficient_Routing/NetworkLifetime.m
%
%  Description:
%    Simulates round-by-round energy dissipation of a clustered WSN.
%    Each round:
%      - Cluster Head (CH) nodes transmit aggregated data to the nearest BS.
%      - Normal nodes transmit their data to the nearest CH.
%      - CH nodes also pay the reception cost for their cluster members.
%    Simulation stops when all nodes are dead.
%
%  Energy Model (first-order radio model):
%    Tx energy (free-space)  : Eelec*k + xi_free*k*d^2   (d < d0)
%    Tx energy (multi-path)  : Eelec*k + Eamp*k*d^4      (d >= d0)
%    Rx energy               : Eelec*k
%
%  Inputs:
%    nodePositions : N × 2 node coordinates
%    nodeEnergy    : N × 1 initial energy vector (J)
%    CH_IDs        : 1 × m cluster head indices
%    BS_positions  : K × 2 base-station coordinates
%    N             : total number of nodes
%    packetSize    : bits per packet
%    Eelec, Eamp, xi_free, d0 : radio energy parameters
%
%  Outputs:
%    aliveNodes  : 1 × maxRounds  – alive node count per round
%    deadNodes   : 1 × maxRounds  – dead  node count per round
%    totalEnergy : 1 × maxRounds  – total remaining energy per round
%    deathRound  : 1 × N          – round at which each node died (0 = alive)
% =========================================================================

function [aliveNodes, deadNodes, totalEnergy, deathRound] = ...
    NetworkLifetime(nodePositions, nodeEnergy, CH_IDs, BS_positions, ...
                    N, packetSize, Eelec, Eamp, xi_free, d0)

maxRounds = 7500;

aliveNodes  = zeros(1, maxRounds);
deadNodes   = zeros(1, maxRounds);
totalEnergy = zeros(1, maxRounds);
deathRound  = zeros(1, N);

for r = 1:maxRounds
    for i = 1:N
        if nodeEnergy(i) <= 0
            continue   % Skip already-dead nodes
        end

        if any(CH_IDs == i)
            % ---- CH: transmit to nearest BS ----
            dists_bs   = vecnorm(nodePositions(i,:) - BS_positions, 2, 2);
            dist_to_bs = min(dists_bs);

            if dist_to_bs < d0
                Etx = Eelec * packetSize + xi_free * packetSize * dist_to_bs^2;
            else
                Etx = Eelec * packetSize + Eamp   * packetSize * dist_to_bs^4;
            end
            nodeEnergy(i) = nodeEnergy(i) - Etx;

        else
            % ---- Normal node: transmit to nearest CH ----
            dists_ch         = vecnorm(nodePositions(i,:) - nodePositions(CH_IDs,:), 2, 2);
            [dist_to_ch, idx] = min(dists_ch);
            ch                = CH_IDs(idx);

            if dist_to_ch < d0
                Etx = Eelec * packetSize + xi_free * packetSize * dist_to_ch^2;
            else
                Etx = Eelec * packetSize + Eamp   * packetSize * dist_to_ch^4;
            end
            nodeEnergy(i) = nodeEnergy(i) - Etx;

            % CH reception cost
            if nodeEnergy(ch) > 0
                nodeEnergy(ch) = nodeEnergy(ch) - Eelec * packetSize;
            end
        end

        % Record death round
        if nodeEnergy(i) <= 0 && deathRound(i) == 0
            deathRound(i) = r;
        end
    end

    aliveNodes(r)  = sum(nodeEnergy > 0);
    deadNodes(r)   = N - aliveNodes(r);
    totalEnergy(r) = sum(nodeEnergy(nodeEnergy > 0));

    % Early exit when network is fully dead
    if aliveNodes(r) == 0
        aliveNodes(r:end)  = 0;
        deadNodes(r:end)   = N;
        totalEnergy(r:end) = 0;
        break;
    end
end

end
