#!/usr/bin/env bash
# =============================================================================
# 40_PlotCities.sh  –  Render city dots and labels (once, reused for all maps)
#
# Output: output/f418-eu-cities.{ps|pdf|png}
#
# Standalone usage:
#   bash scripts/40_PlotCities.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

OUT="$(cities_file)"

echo "=== 40_PlotCities ==="
echo "  Output: ${OUT}"

apply_gmt_defaults
load_city_data

# ---------------------------------------------------------------------------
# Split into separate XY and label files for capitals vs non-capitals
# ---------------------------------------------------------------------------
CAP_XY="${TMPDIR_GMT}/cities_cap.txt"
NON_XY="${TMPDIR_GMT}/cities_non.txt"
CAP_LBL="${TMPDIR_GMT}/cities_cap_lbl.txt"
NON_LBL="${TMPDIR_GMT}/cities_non_lbl.txt"

> "${CAP_XY}";  > "${NON_XY}"
> "${CAP_LBL}"; > "${NON_LBL}"

for i in "${!CT_LON[@]}"; do
    lon="${CT_LON[i]}"
    lat="${CT_LAT[i]}"
    name="${CT_NAME[i]}"
    cap="${CT_CAP[i]}"
    if [[ "${cap}" == "1" ]]; then
        printf "%s\t%s\n"      "${lon}" "${lat}"        >> "${CAP_XY}"
        printf "%s\t%s\t%s\n" "${lon}" "${lat}" "${name}" >> "${CAP_LBL}"
    else
        printf "%s\t%s\n"      "${lon}" "${lat}"        >> "${NON_XY}"
        printf "%s\t%s\t%s\n" "${lon}" "${lat}" "${name}" >> "${NON_LBL}"
    fi
done

# ---------------------------------------------------------------------------
# Render
# ---------------------------------------------------------------------------
gmt begin "${OUT%.*}" "${FORMAT}"
    apply_gmt_defaults
    gmt basemap ${REGION} ${PROJ} -Bafg --MAP_FRAME_PEN=0p

    # Non-capital dots (smaller, dark grey)
    gmt plot "${NON_XY}" ${REGION} ${PROJ} \
        -Sc0.18c -G"${CITY_NON_COLOR}" -W0.3p,black

    # Capital dots (larger, black)
    gmt plot "${CAP_XY}" ${REGION} ${PROJ} \
        -Sc0.22c -G"${CITY_CAP_COLOR}" -W0.3p,black

    # Non-capital labels (7 pt, offset right, white halo)
    gmt text "${NON_LBL}" ${REGION} ${PROJ} \
        -F+f7p,Helvetica,"${CITY_NON_COLOR}"+jLM \
        -D0.14c/0c -To -Gwhite@40

    # Capital labels (7.5 pt bold, offset right, white halo)
    gmt text "${CAP_LBL}" ${REGION} ${PROJ} \
        -F+f7.5p,Helvetica-Bold,black+jLM \
        -D0.14c/0c -To -Gwhite@40

gmt end

echo "  Done: ${OUT}"
