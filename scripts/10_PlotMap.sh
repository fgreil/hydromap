#!/usr/bin/env bash
# =============================================================================
# 10_PlotMap.sh  –  Render the Europe topographic background (once)
#
# Output: output/f418-eu-background.{ps|pdf|png}
#
# Standalone usage:
#   bash scripts/10_PlotMap.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

OUT="$(bg_file)"

echo "=== 10_PlotMap: Europe background ==="
echo "  Output: ${OUT}"

apply_gmt_defaults

# ---------------------------------------------------------------------------
# Build CPT (oleron: perceptually uniform, colorblind-safe)
# ---------------------------------------------------------------------------
if [[ ! -f "${CPT}" ]]; then
    echo "  Building colour palette..."
    gmt makecpt -Coleron -T-500/5500/50 -Z -D > "${CPT}"
fi

# ---------------------------------------------------------------------------
# Hillshade (cached; reused by all maps)
# ---------------------------------------------------------------------------
if [[ ! -f "${SHADE}" ]]; then
    echo "  Computing hillshade (~30 s)..."
    gmt grdgradient "${DEM}" -Nt0.6 -A315 -G"${SHADE}"
fi

# ---------------------------------------------------------------------------
# Render background
# ---------------------------------------------------------------------------
gmt begin "${OUT%.*}" "${FORMAT}"
    apply_gmt_defaults

    # Topography with hillshading
    gmt grdimage "${DEM}" -I"${SHADE}" \
        ${REGION} ${PROJ} -C"${CPT}" \
        -Bxa15g15 -Bya10g10 -BWSen -Q

    # Sea, coastlines, country borders
    gmt coast ${REGION} ${PROJ} \
        -Da \
        -S"${SEA_COLOR}" \
        -W0.25p,grey35 \
        -N1/0.5p,"${BORDER_COLOR}"

    # Elevation colour bar
    gmt colorbar -C"${CPT}" \
        -DJBC+w11c/0.30c+h+o0/0.9c \
        -Bxa1000f500+l"Elevation (m)" -By+l""

gmt end

echo "  Done: ${OUT}"
