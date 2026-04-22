#!/usr/bin/env bash
# =============================================================================
# 20_PlotCatchment.sh  –  Render catchment polygon for one waterway
#
# Output: output/f418-eu-catch_<ID>.{ps|pdf|png}
#
# Standalone usage:
#   bash scripts/20_PlotCatchment.sh L1
#   bash scripts/20_PlotCatchment.sh C6   # canal → empty output, no catchment
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

ID="${1:?Usage: $0 <waterway-ID>  e.g. L1}"
ID="${ID^^}"

parse_river "${ID}"

OUT="$(catch_file "${ID}")"

echo "=== 20_PlotCatchment: ${ID} – ${_label} ==="
echo "  Output: ${OUT}"

# Canals have no natural catchment
if [[ "${_cat}" == "Canal" || "${_main_bas}" == "0" ]]; then
    echo "  [INFO] Canal or no catchment defined – producing empty layer."
    # Write a valid but empty PS file so Makefile targets still resolve
    gmt begin "${OUT%.*}" "${FORMAT}"
        apply_gmt_defaults
        gmt basemap ${REGION} ${PROJ} -Bafg --MAP_FRAME_PEN=0p
    gmt end
    exit 0
fi

# ---------------------------------------------------------------------------
# Extract catchment polygon for this MAIN_BAS
# ---------------------------------------------------------------------------
CATCH_GMT="${TMPDIR_GMT}/catch_${_main_bas}.gmt"
if [[ ! -s "${CATCH_GMT}" ]]; then
    ogr2ogr -f "OGR_GMT" "${CATCH_GMT}" "${CATCH_SHP}" \
        -where "MAIN_BAS = ${_main_bas}" 2>/dev/null || true
fi

if [[ ! -s "${CATCH_GMT}" ]]; then
    echo "  [WARN] No catchment polygon found for MAIN_BAS=${_main_bas}" >&2
    echo "         Verify ID with: ogrinfo -al -q ${CATCH_SHP} | grep MAIN_BAS" >&2
fi

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
gmt begin "${OUT%.*}" "${FORMAT}"
    apply_gmt_defaults
    gmt basemap ${REGION} ${PROJ} -Bafg --MAP_FRAME_PEN=0p

    if [[ -s "${CATCH_GMT}" ]]; then
        gmt plot "${CATCH_GMT}" ${REGION} ${PROJ} \
            -G"${CATCH_COLOR}@55" \
            -W0.5p,"${CATCH_COLOR}"
    fi
gmt end

echo "  Done: ${OUT}"
