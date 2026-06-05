# WSN-Puma-Optimization

MATLAB simulation of Wireless Sensor Network (WSN) optimization using the **Puma Optimizer Algorithm (POA)**.  
Two independent problems are solved:

1. **Coverage Optimization** – optimal sensor placement to maximize area coverage  
2. **Energy-Efficient Routing** – optimal Cluster Head selection to maximize network lifetime

---

## Repository Structure

```
WSN-Puma-Optimization/
│
├── README.md
├── requirements.txt
│
├── Algorithm/                         ← Core POA implementation
│   ├── Puma.m                         Main optimizer loop
│   ├── Exploration.m                  Exploration phase (diversification)
│   ├── Exploitation.m                 Exploitation phase (intensification)
│   └── boundaryCheck.m               Boundary enforcement utility
│
├── Coverage_Optimization/             ← Problem 1
│   ├── main_coverage.m                Entry point – run this
│   ├── Calculate_Cost.m               Coverage + connectivity cost function
│   └── DrawFinalResult.m              Sensor deployment visualization
│
├── Energy_Efficient_Routing/          ← Problem 2
│   ├── main_routing.m                 Entry point – run this
│   ├── ObjectiveFunction.m            Multi-objective CH fitness function
│   └── NetworkLifetime.m              Round-by-round energy simulation
│
└── Results/
    └── routing_results/               Output figures and data (gitignored)
```

---

## Requirements

- MATLAB R2021a or later  
- Statistics and Machine Learning Toolbox (for `unifrnd`)  
- *GNU Octave users*: add `pkg load statistics;` at the top of each main script

See [`requirements.txt`](requirements.txt) for details.

---

## How to Run

### Coverage Optimization
```matlab
cd Coverage_Optimization
main_coverage
```
Outputs:
- Convergence curve figure
- Optimal sensor deployment map with coverage/communication circles
- Coverage rate printed to console

### Energy-Efficient Routing
```matlab
cd Energy_Efficient_Routing
main_routing
```
Outputs:
- POA convergence curve
- Alive/dead node count and total energy per round plots
- First-node-death round printed to console
- Per-node death round table

---

## Algorithm Reference

> Abdollahzadeh, B., Khodadadi, N., Barshandeh, S., Trojovský, P., Gharehchopogh, F.S., El-kenawy, E.-S.M., Abualigah, L., & Mirjalili, S. (2024).  
> **Puma optimizer (PO): a novel metaheuristic optimization algorithm and its application in machine learning.**  
> *Cluster Computing*. https://doi.org/10.1007/s10586-023-04221-5

---

## Parameters

| Parameter | Coverage | Routing | Description |
|---|---|---|---|
| `Npop / nSol` | 50 | 30 | Population size |
| `Max_it / MaxIter` | 500 | 500 | Maximum iterations |
| `Region_Size` | 160 | – | Grid dimension (pixels) |
| `Nsensors` | 60 | – | Number of sensors |
| `SensRange` | 10 | – | Sensing radius |
| `CommRange` | 20 | – | Communication radius |
| `N` | – | 50 | Number of nodes |
| `CHpercent` | – | 0.10 | CH fraction |
| `InitialEnergy` | – | 1.5 J | Initial node energy |

---

## License

This project is released for academic use.  
The POA core algorithm is credited to the original authors (see reference above).
