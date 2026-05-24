% =========================================================================
%  Puma Optimizer Algorithm (POA) - Exploration Phase
%  WSN Simulation: Coverage Optimization & Energy-Efficient Routing
%
%  Repository: WSN-Puma-Optimization
%  File: Algorithm/Exploration.m
%
%  Original POA Paper:
%    Abdollahzadeh et al., "Puma optimizer (PO): a novel metaheuristic
%    optimization algorithm and its application in machine learning"
%    Cluster Computing, DOI: 10.1007/s10586-023-04221-5
% =========================================================================

function Sol = Exploration(Sol, lb, ub, dim, nSol, CostFunction)

[~, sind] = sort([Sol.Cost]);
Sol = Sol(sind);

pCR = 0.20;
PCR = 1 - pCR;       % Eq. 28
p   = PCR / nSol;    % Eq. 29

for i = 1:nSol
    x = Sol(i).X;

    A      = randperm(nSol);
    A(A==i) = [];
    a = A(1); b = A(2); c = A(3);
    d = A(4); e = A(5); f = A(6);

    G = 2*rand - 1;   % Eq. 26

    if rand < 0.5
        % Random position in search space  (Eq. 25 - branch 1)
        y = rand(1, dim) .* (ub - lb) + lb;
    else
        % Differential-mutation based position  (Eq. 25 - branch 2)
        y = Sol(a).X + G .* (Sol(a).X - Sol(b).X) + ...
            G .* (((Sol(a).X - Sol(b).X) - (Sol(c).X - Sol(d).X)) + ...
                  ((Sol(c).X - Sol(d).X) - (Sol(e).X - Sol(f).X)));
    end

    y = max(y, lb);
    y = min(y, ub);

    % Crossover
    z  = zeros(size(x));
    j0 = randi([1, numel(x)]);
    for j = 1:numel(x)
        if j == j0 || rand <= pCR
            z(j) = y(j);
        else
            z(j) = x(j);
        end
    end

    NewSol(i).X    = z;                          %#ok
    NewSol(i).Cost = CostFunction(NewSol(i).X);  %#ok

    if NewSol(i).Cost < Sol(i).Cost
        Sol(i) = NewSol(i);
    else
        pCR = pCR + p;   % Eq. 30 – adaptive crossover rate
    end
end

end
