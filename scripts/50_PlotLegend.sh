#!/usr/bin/env bash
# =============================================================================
# 50_PlotLegend.sh  –  Render legend for one waterway
#
# Output: output/f418-eu-legend_<ID>.{ps|pdf|png}
#
# Legend entries:
#   - Catchment area swatch  (if applicable)
#   - River / canal line swatch
#   - Capital city symbol
#   - Non-capital city symbol
#   - Length in km
#
# Standalone usage:
#   bash scripts/50_PlotLegend.sh L1
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

ID="${1:?Usage: $0 <waterway-ID>  e.g. L1}"
ID="${ID^^}"

parse_river "${ID}"

OUT="$(legend_file "${ID}")"

echo "=== 50_PlotLegend: ${ID} – ${_label} ==="
echo "  Output: ${OUT}"

apply_gmt_defaults

IS_CANAL="no"
HAS_CATCH="no"
[[ "${_cat}" == "Canal" ]]    && IS_CANAL="yes"
[[ "${_main_bas}" != "0" ]]   && HAS_CATCH="yes"

# ---------------------------------------------------------------------------
# Build legend spec
# ---------------------------------------------------------------------------
LEGEND_TXT="${TMPDIR_GMT}/legend_${ID}.txt"
{
    echo "G 0.08c"

    # Waterway name (primary label, wraps if long)
    echo "T ${_label}"
    echo "G 0.06c"
    printf "T Length: %s km\n" "${_len}"
    echo "G 0.10c"

    # Catchment swatch
    if [[ "${HAS_CATCH}" == "yes" ]]; then
        echo "S 0.3c r 0.35c ${CATCH_COLOR}@55 0.5p,${CATCH_COLOR} 0.9c Catchment area"
        echo "G 0.06c"
    fi

    # River / canal line swatch
    if [[ "${IS_CANAL}" == "yes" ]]; then
        echo "S 0.3c - 0.50c ${RIVER_COLOR} 2p,${RIVER_COLOR},- 0.9c Canal"
    else
        echo "S 0.3c - 0.50c ${RIVER_COLOR} 1.6p,${RIVER_COLOR} 0.9c River"
    fi

    echo "G 0.10c"

    # City symbols
    echo "S 0.3c c 0.22c ${CITY_CAP_COLOR} 0.3p,black 0.9c Capital city"
    echo "G 0.06c"
    echo "S 0.3c c 0.18c ${CITY_NON_COLOR} 0.3p,black 0.9c Major city"

    echo "G 0.06c"
} > "${LEGEND_TXT}"

# ---------------------------------------------------------------------------
# Render – positioned lower-left of map
# ---------------------------------------------------------------------------
gmt begin "${OUT%.*}" "${FORMAT}"
    apply_gmt_defaults
    gmt basemap ${REGION} ${PROJ} -Bafg --MAP_FRAME_PEN=0p

    gmt legend "${LEGEND_TXT}" ${REGION} ${PROJ} \
        -Dx0.3c/0.3c+w9c \
        -F+p0.6p,black+gwhite@20 \
        -C0.18c/0.12c
gmt end

echo "  Done: ${OUT}"
