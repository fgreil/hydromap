#!/usr/bin/env bash
# =============================================================================
# 01_Download.sh  –  Fetch DEM and river/catchment shapefiles
#
# Downloads (~700 MB total):
#   1. ETOPO1 DEM clipped to Europe     →  europe_dem.nc
#   2. HydroRIVERS v1.0 Europe          →  ccm_data/HydroRIVERS_v10_eu.shp
#   3. HydroBASINS level-4 Europe+Asia  →  ccm_data/catchments_dissolved.shp
#
# Run from project root:  bash scripts/01_Download.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

cd "${PROJECT_ROOT}"
mkdir -p ccm_data tmp_dl

# ---------------------------------------------------------------------------
# 1. ETOPO1 DEM via NOAA OPeNDAP — clipped to map extent at download time
#    Region: 25°W–45°E, 37°N–72°N
# ---------------------------------------------------------------------------
echo "=== [1/4] ETOPO1 DEM ==="
if [[ -f "${DEM}" ]]; then
    echo "  ${DEM} already exists – skipping."
else
    ETOPO_BASE="https://www.ngdc.noaa.gov/thredds/ncss/global/ETOPO1_Ice_g_gmt4.grd/dataset.nc"
    ETOPO_PARAMS="?var=z&north=72&west=-25&east=45&south=37&horizStride=1&accept=netcdf"
    echo "  Downloading ETOPO1 (clipped, ~300 MB)..."
    curl -L --retry 5 --retry-delay 5 -o "${DEM}" "${ETOPO_BASE}${ETOPO_PARAMS}"
    echo "  Saved: ${DEM}  ($(du -sh "${DEM}" | cut -f1))"
fi

# ---------------------------------------------------------------------------
# 2. HydroRIVERS v1.0 – Europe tile
#    https://www.hydrosheds.org/products/hydrorivers
# ---------------------------------------------------------------------------
echo ""
echo "=== [2/4] HydroRIVERS (Europe) ==="
if [[ -f "${RIVER_SHP}" ]]; then
    echo "  ${RIVER_SHP} already exists – skipping."
else
    RZIP="tmp_dl/HydroRIVERS_v10_eu.zip"
    curl -L --retry 5 \
        -o "${RZIP}" \
        "https://data.hydrosheds.org/file/HydroRIVERS/HydroRIVERS_v10_eu.zip"
    unzip -q "${RZIP}" -d tmp_dl/riv_eu/
    find tmp_dl/riv_eu/ -name "HydroRIVERS_v10_eu.*" \
        -exec cp {} ccm_data/ \;
    echo "  Saved: ${RIVER_SHP}"
fi

# ---------------------------------------------------------------------------
# 3. HydroBASINS level-4 – Europe + Asia tiles
#    https://www.hydrosheds.org/products/hydrobasins
# ---------------------------------------------------------------------------
fetch_basins() {
    local region="$1" label="$2"
    local shp="ccm_data/hybas_${region}_lev04_v1c.shp"
    if [[ -f "${shp}" ]]; then
        echo "  ${shp} already exists – skipping."
        return
    fi
    local zip="tmp_dl/hybas_${region}_lev04.zip"
    echo "  Downloading HydroBASINS ${label}..."
    curl -L --retry 5 \
        -o "${zip}" \
        "https://data.hydrosheds.org/file/HydroBASINS/standard/hybas_${region}_lev04_v1c.zip"
    unzip -q "${zip}" -d "tmp_dl/bas_${region}/"
    find "tmp_dl/bas_${region}/" -name "hybas_${region}_lev04_v1c.*" \
        -exec cp {} ccm_data/ \;
    echo "  Saved: ${shp}"
}

echo ""
echo "=== [3/4] HydroBASINS level-4 ==="
fetch_basins "eu" "Europe (~50 MB)"
fetch_basins "as" "Asia   (~50 MB)"

# ---------------------------------------------------------------------------
# 4. Merge EU + AS tiles and dissolve by MAIN_BAS
# ---------------------------------------------------------------------------
echo ""
echo "=== [4/4] Merging and dissolving catchments ==="
if [[ -f "${CATCH_SHP}" ]]; then
    echo "  ${CATCH_SHP} already exists – skipping."
else
    RAW_EU="ccm_data/hybas_eu_lev04_v1c.shp"
    RAW_AS="ccm_data/hybas_as_lev04_v1c.shp"
    MERGED="ccm_data/hybas_merged_lev04.shp"

    echo "  Merging EU + AS tiles..."
    ogr2ogr -f "ESRI Shapefile" "${MERGED}" "${RAW_EU}"
    ogr2ogr -f "ESRI Shapefile" -update -append "${MERGED}" "${RAW_AS}" \
        -nln "hybas_merged_lev04"

    echo "  Dissolving by MAIN_BAS (may take 1–2 min)..."
    ogr2ogr -f "ESRI Shapefile" "${CATCH_SHP}" "${MERGED}" \
        -dialect SQLite \
        -sql "SELECT MAIN_BAS, ST_Union(geometry) AS geometry
              FROM hybas_merged_lev04
              GROUP BY MAIN_BAS"
    echo "  Saved: ${CATCH_SHP}"
fi

rm -rf tmp_dl

echo ""
echo "=== Download complete ==="
echo "  DEM:        $(du -sh "${DEM}"        2>/dev/null | cut -f1)"
echo "  Rivers:     $(du -sh "${RIVER_SHP}"  2>/dev/null | cut -f1)"
echo "  Catchments: $(du -sh "${CATCH_SHP}"  2>/dev/null | cut -f1)"
echo ""
echo "Next: make all"
