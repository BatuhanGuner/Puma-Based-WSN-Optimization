% =========================================================================
%  Puma Optimizer Algorithm (POA) - WSN Simulation
%  Applied to: Coverage Optimization & Energy-Efficient Routing in WSNs
%
%  Repository: WSN-Puma-Optimization
%  File: Algorithm/Puma.m
%
%  Original POA Paper:
%    Abdollahzadeh et al., "Puma optimizer (PO): a novel metaheuristic
%    optimization algorithm and its application in machine learning"
%    Cluster Computing, DOI: 10.1007/s10586-023-04221-5
% =========================================================================

function [Puma_X, Puma_C, Convergence] = Puma(nSol, MaxIter, lb, ub, dim, CostFunction)

% --- Parameter Initialization ---
UnSelected = ones(1,2);   % 1:Exploration  2:Exploitation
F3_Explore = 0;
F3_Exploit = 0;
Seq_Time_Explore = ones(1,3);
Seq_Time_Exploit = ones(1,3);
Seq_Cost_Explore = ones(1,3);
Seq_Cost_Exploit = ones(1,3);
Score_Explore = 0; %#ok
Score_Exploit = 0; %#ok
PF = [0.5 0.5 0.3];   % 1&2: intensification (F1,F2)  3: diversification (F3)
PF_F3 = [];
Mega_Explor  = 0.99;
Mega_Exploit = 0.99;

% --- Population Initialization ---
for i = 1:nSol
    Sol(i).X    = unifrnd(lb, ub, 1, dim); %#ok
    Sol(i).Cost = CostFunction(Sol(i).X);  %#ok
end

[~, ind] = min([Sol.Cost]);
Best         = Sol(ind);
Flag_Change  = 1;
Initial_Best = Best;

% =========================================================================
%  UNEXPERIENCED PHASE  (Iterations 1-3)
% =========================================================================
for Iter = 1:3

    Sol_Explor = Exploration(Sol, lb, ub, dim, nSol, CostFunction);
    Costs_Explor(1, Iter) = min([Sol_Explor.Cost]); %#ok

    Sol_Exploit = Exploitation(Sol, lb, ub, dim, nSol, Best, MaxIter, Iter, CostFunction);
    Costs_Exploit(1, Iter) = min([Sol_Exploit.Cost]); %#ok

    Sol = [Sol Sol_Explor Sol_Exploit]; %#ok
    [~, sind] = sort([Sol.Cost]);
    Sol  = Sol(sind(1:nSol));
    Best = Sol(1);

    Convergence(Iter) = Best.Cost; %#ok
    disp(['Iteration: ' num2str(Iter) '  Best Cost = ' num2str(Best.Cost)]);
end

% --- Hyper-Initialization (Eqs. 5-10) ---
Seq_Cost_Explore(1) = abs(Initial_Best.Cost  - Costs_Explor(1));
Seq_Cost_Exploit(1) = abs(Initial_Best.Cost  - Costs_Exploit(1));
Seq_Cost_Explore(2) = abs(Costs_Explor(2)    - Costs_Explor(1));
Seq_Cost_Exploit(2) = abs(Costs_Exploit(2)   - Costs_Exploit(1));
Seq_Cost_Explore(3) = abs(Costs_Explor(3)    - Costs_Explor(2));
Seq_Cost_Exploit(3) = abs(Costs_Exploit(3)   - Costs_Exploit(2));

for i = 1:3
    if Seq_Cost_Explore(i) ~= 0
        PF_F3 = [PF_F3, Seq_Cost_Explore(i)]; %#ok
    end
    if Seq_Cost_Exploit(i) ~= 0
        PF_F3 = [PF_F3, Seq_Cost_Exploit(i)]; %#ok
    end
end

% --- Initial Scores (Eqs. 1-12) ---
F1_Explor  = PF(1) * (Seq_Cost_Explore(1) / Seq_Time_Explore(1));
F1_Exploit = PF(1) * (Seq_Cost_Exploit(1) / Seq_Time_Exploit(1));
F2_Explor  = PF(2) * ((Seq_Cost_Explore(1)+Seq_Cost_Explore(2)+Seq_Cost_Explore(3)) / ...
                       (Seq_Time_Explore(1)+Seq_Time_Explore(2)+Seq_Time_Explore(3)));
F2_Exploit = PF(2) * ((Seq_Cost_Exploit(1)+Seq_Cost_Exploit(2)+Seq_Cost_Exploit(3)) / ...
                       (Seq_Time_Exploit(1)+Seq_Time_Exploit(2)+Seq_Time_Exploit(3)));
Score_Explore = (PF(1)*F1_Explor)  + (PF(2)*F2_Explor);
Score_Exploit = (PF(1)*F1_Exploit) + (PF(2)*F2_Exploit);

% =========================================================================
%  EXPERIENCED PHASE  (Iterations 4 - MaxIter)
% =========================================================================
for Iter = 4:MaxIter

    if Score_Explore > Score_Exploit
        % --- Exploration branch ---
        SelectFlag   = 1;
        Sol          = Exploration(Sol, lb, ub, dim, nSol, CostFunction);
        Count_select = UnSelected;
        UnSelected(2) = UnSelected(2) + 1;
        UnSelected(1) = 1;
        F3_Explore = PF(3);
        F3_Exploit = F3_Exploit + PF(3);

        [~, TBind] = min([Sol.Cost]);
        TBest = Sol(TBind);
        Seq_Cost_Explore(3) = Seq_Cost_Explore(2);
        Seq_Cost_Explore(2) = Seq_Cost_Explore(1);
        Seq_Cost_Explore(1) = abs(Best.Cost - TBest.Cost);
        if Seq_Cost_Explore(1) ~= 0
            PF_F3 = [PF_F3, Seq_Cost_Explore(1)]; %#ok
        end
        if TBest.Cost < Best.Cost
            Best = TBest;
        end
    else
        % --- Exploitation branch ---
        SelectFlag   = 2;
        Sol          = Exploitation(Sol, lb, ub, dim, nSol, Best, MaxIter, Iter, CostFunction);
        Count_select = UnSelected;
        UnSelected(1) = UnSelected(1) + 1;
        UnSelected(2) = 1;
        F3_Explore = F3_Explore + PF(3);
        F3_Exploit = PF(3);

        [~, TBind] = min([Sol.Cost]);
        TBest = Sol(TBind);
        Seq_Cost_Exploit(3) = Seq_Cost_Exploit(2);
        Seq_Cost_Exploit(2) = Seq_Cost_Exploit(1);
        Seq_Cost_Exploit(1) = abs(Best.Cost - TBest.Cost);
        if Seq_Cost_Exploit(1) ~= 0
            PF_F3 = [PF_F3, Seq_Cost_Exploit(1)]; %#ok
        end
        if TBest.Cost < Best.Cost
            Best = TBest;
        end
    end

    if Flag_Change ~= SelectFlag
        Flag_Change = SelectFlag;
        Seq_Time_Explore(3) = Seq_Time_Explore(2);
        Seq_Time_Explore(2) = Seq_Time_Explore(1);
        Seq_Time_Explore(1) = Count_select(1);
        Seq_Time_Exploit(3) = Seq_Time_Exploit(2);
        Seq_Time_Exploit(2) = Seq_Time_Exploit(1);
        Seq_Time_Exploit(1) = Count_select(2);
    end

    % --- Score Update (Eqs. 13-24) ---
    F1_Explor  = PF(1) * (Seq_Cost_Explore(1) / Seq_Time_Explore(1));
    F1_Exploit = PF(1) * (Seq_Cost_Exploit(1) / Seq_Time_Exploit(1));
    F2_Explor  = PF(2) * ((Seq_Cost_Explore(1)+Seq_Cost_Explore(2)+Seq_Cost_Explore(3)) / ...
                           (Seq_Time_Explore(1)+Seq_Time_Explore(2)+Seq_Time_Explore(3)));
    F2_Exploit = PF(2) * ((Seq_Cost_Exploit(1)+Seq_Cost_Exploit(2)+Seq_Cost_Exploit(3)) / ...
                           (Seq_Time_Exploit(1)+Seq_Time_Exploit(2)+Seq_Time_Exploit(3)));

    if Score_Explore < Score_Exploit
        Mega_Explor  = max((Mega_Explor  - 0.01), 0.01);
        Mega_Exploit = 0.99;
    elseif Score_Explore > Score_Exploit
        Mega_Explor  = 0.99;
        Mega_Exploit = max((Mega_Exploit - 0.01), 0.01);
    end

    lmn_Explore = 1 - Mega_Explor;
    lmn_Exploit = 1 - Mega_Exploit;

    Score_Explore = (Mega_Explor*F1_Explor)   + (Mega_Explor*F2_Explor)   + (lmn_Explore*(min(PF_F3)*F3_Explore));
    Score_Exploit = (Mega_Exploit*F1_Exploit) + (Mega_Exploit*F2_Exploit) + (lmn_Exploit*(min(PF_F3)*F3_Exploit));

    Convergence(Iter) = Best.Cost; %#ok
    disp(['Iteration: ' num2str(Iter) '  Best Cost = ' num2str(Best.Cost)]);
    Puma_C = Best.Cost;
    Puma_X = Best.X;
end

end
