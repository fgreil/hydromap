# f418 – European Waterway Maps

## Pipeline Overview

```
00_InstallDeps.sh          Install GMT, GDAL, Ghostscript
01_Download.sh             Fetch DEM + HydroSHEDS shapefiles
        ↓
02_Common.sh               Sourced by all scripts below (never run directly)
        ↓
10_PlotMap.sh    ──────────────────────────→  output/f418-eu-background.ps
40_PlotCities.sh ──────────────────────────→  output/f418-eu-cities.ps
        ↓  (per waterway ID, e.g. L1)
20_PlotCatchment.sh L1 ──────────────────→  output/f418-eu-catch_L1.ps
30_PlotRiver.sh     L1 ──────────────────→  output/f418-eu-river_L1.ps
50_PlotLegend.sh    L1 ──────────────────→  output/f418-eu-legend_L1.ps
        ↓
60_Assemble.sh      L1 ──────────────────→  output/f418-eu-waterway-L1_Danube.pdf
```

Layers are composited bottom → top:
background → catchment → river → cities → legend

## Script Reference

| Script | Run once / per ID | Description |
|--------|------------------|-------------|
| `00_InstallDeps.sh` | once | Installs GMT ≥ 6.4, GDAL, Ghostscript, curl |
| `01_Download.sh` | once | Downloads ETOPO1 DEM, HydroRIVERS, HydroBASINS |
| `02_Common.sh` | sourced | Shared variables, functions, CSV parsers |
| `10_PlotMap.sh` | once | Europe topo background (hillshade + coastlines) |
| `20_PlotCatchment.sh` | per ID | Catchment polygon from HydroBASINS |
| `30_PlotRiver.sh` | per ID | River lines (HydroRIVERS) or canal waypoints |
| `40_PlotCities.sh` | once | City dots and labels (39 cities) |
| `50_PlotLegend.sh` | per ID | Legend box with waterway name + symbols |
| `60_Assemble.sh` | per ID | Composites all layers → final PDF |

## Standalone Usage

Every numbered script can be run independently:

```bash
# One-time setup
bash scripts/00_InstallDeps.sh
bash scripts/01_Download.sh

# Shared layers (built once, reused for all 56 maps)
bash scripts/10_PlotMap.sh
bash scripts/40_PlotCities.sh

# Per-waterway layers (example: Rhine, ID = L3)
bash scripts/20_PlotCatchment.sh L3
bash scripts/30_PlotRiver.sh     L3
bash scripts/50_PlotLegend.sh    L3
bash scripts/60_Assemble.sh      L3
# → output/f418-eu-waterway-L3_Rhine.pdf
```

## Output Naming
The outputs follow the scheme `f418-eu-waterway-<ID>_<EnglishName>.pdf`, e.g. `f418-eu-waterway-L1_Danube.pdf` or 
- `f418-eu-waterway-C6_Kiel_Canal.pdf`

Intermediate layers are called for instance:
- `f418-eu-background.ps`
- `f418-eu-catch_L1.ps`
- `f418-eu-river_L1.ps`
- `f418-eu-cities.ps`
- `f418-eu-legend_L1.ps`

## Map Settings (02_Common.sh)

| Setting | Value |
|---------|-------|
| Region | 25°W – 45°E, 37°N – 72°N |
| Projection | Lambert Conformal Conic (std. parallels 40°N/68°N, centre 10°E/54°N) |
| DEM | ETOPO1 (NOAA), clipped at download |
| River data | HydroRIVERS v1.0 (HydroSHEDS), Europe tile |
| Catchments | HydroBASINS level-4, EU+Asia merged, dissolved by MAIN_BAS |
| Topo CPT | `oleron` (GMT built-in, perceptually uniform, colorblind-safe) |
| River colour | `#EE7733` (orange, CB-safe) |
| Catchment colour | `#0077BB` (blue @ 55% transparency, CB-safe) |
| Intermediate format | PostScript (`.ps`), switchable via `FORMAT=` |


## Troubleshooting

**Catchment polygon missing:**
```bash
ogrinfo -al -q ccm_data/catchments_dissolved.shp | grep MAIN_BAS | head -30
```
Update the `main_bas` field in `data/river_data.csv` for the affected ID.

**River lines missing:**
Widen the `bbox` field or lower the `strahler` threshold in `data/river_data.csv`.

**`oleron` CPT not found (GMT < 6.3):**
Replace `oleron` with `dem2` or `gray` in `10_PlotMap.sh`.

**Ghostscript PDF assembly fails:**
Check `gs --version` ≥ 9.0. On some systems the binary is `ghostscript` not `gs`;
update the `gs` call in `60_Assemble.sh` accordingly.

**Volga / Ural catchments clipped at eastern boundary:**
These basins extend beyond 45°E. The Asia HydroBASINS tile is merged during
download, but portions east of the map boundary will not be shown — this is expected.
