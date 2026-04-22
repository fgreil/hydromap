# `hydromap`project structure
```
├── Makefile
├── lib/
│   └── common.sh            # REGION, PROJ, CPT, colours, GMT defaults,
│                            # parse_entry(), shared functions
├── data/
│   ├── river_data.sh        # waterway metadata (sourced by common.sh)
│   └── cities.sh            # city coordinates (sourced by common.sh)
├── scripts/
│   ├── 0_InstallDeps.sh     # apt/dnf/zypper install
│   ├── 0_Download.sh        # fetch DEM + shapefiles
│   ├── 1_PlotMap.sh         # → output/f418-eu-background.ps
│   ├── 2_PlotCatchment.sh   # → output/f418-eu-catch_L1.ps  (arg: ID)
│   ├── 3_PlotRiver.sh       # → output/f418-eu-river_L1.ps  (arg: ID)
│   ├── 4_PlotCities.sh      # → output/f418-eu-cities.ps
│   ├── 5_PlotLegend.sh      # → output/f418-eu-legend_L1.ps (arg: ID)
│   └── 6_Assemble.sh        # composites layers → output/f418-eu-waterway-L1_Donau.pdf
└── output/
```
