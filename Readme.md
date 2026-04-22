# `hydromap`project structure
```
├── Makefile
├── data/
│   ├── river_data.sh
│   └── cities.sh
├── scripts/
│   ├── 00_InstallDeps.sh
│   ├── 01_Download.sh
│   ├── 02_Common.sh         # sourced by all others, never executed directly
│   ├── 10_PlotMap.sh        # → output/f418-eu-background.ps
│   ├── 20_PlotCatchment.sh  # → output/f418-eu-catch_L1.ps
│   ├── 30_PlotRiver.sh      # → output/f418-eu-river_L1.ps
│   ├── 40_PlotCities.sh     # → output/f418-eu-cities.ps
│   ├── 50_PlotLegend.sh     # → output/f418-eu-legend_L1.ps
│   └── 60_Assemble.sh       # → output/f418-eu-waterway-L1_Donau.pdf
└── output/
```
