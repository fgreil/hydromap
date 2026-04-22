#!/usr/bin/env bash
# =============================================================================
# 30_PlotRiver.sh  –  Render river or canal line for one waterway
#
# Output: output/f418-eu-river_<ID>.{ps|pdf|png}
#
# Standalone usage:
#   bash scripts/30_PlotRiver.sh L1    # natural river from HydroRIVERS
#   bash scripts/30_PlotRiver.sh C6    # canal from hard-coded waypoints
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

ID="${1:?Usage: $0 <waterway-ID>  e.g. L1}"
ID="${ID^^}"

parse_river "${ID}"

OUT="$(river_file "${ID}")"

echo "=== 30_PlotRiver: ${ID} – ${_label} ==="
echo "  Output: ${OUT}"

apply_gmt_defaults

# ---------------------------------------------------------------------------
# CANAL: draw from hard-coded waypoints
# ---------------------------------------------------------------------------
plot_canal() {
    local xy="${TMPDIR_GMT}/canal_${ID}.txt"
    echo "${_canal_pts}" | tr ';' '\n' | tr ',' '\t' > "${xy}"

    gmt begin "${OUT%.*}" "${FORMAT}"
        apply_gmt_defaults
        gmt basemap ${REGION} ${PROJ} -Bafg --MAP_FRAME_PEN=0p

        # White halo for legibility, then dashed coloured line
        gmt plot "${xy}" ${REGION} ${PROJ} -W3.0p,white@60
        gmt plot "${xy}" ${REGION} ${PROJ} -W2.0p,"${RIVER_COLOR}",-

        # Endpoint markers
        { head -1 "${xy}"; tail -1 "${xy}"; } > "${TMPDIR_GMT}/ep_${ID}.txt"
        gmt plot "${TMPDIR_GMT}/ep_${ID}.txt" ${REGION} ${PROJ} \
            -Ss0.22c -G"${RIVER_COLOR}" -W0.4p,black
    gmt end
}

# ---------------------------------------------------------------------------
# NATURAL RIVER: filter HydroRIVERS by spatial bbox + Strahler order
# ---------------------------------------------------------------------------
plot_river() {
    local key="${_bbox// /_}_s${_strahler}"
    local cache="${TMPDIR_GMT}/riv_${key}.gmt"

    if [[ ! -s "${cache}" ]]; then
        ogr2ogr -f "OGR_GMT" "${cache}" "${RIVER_SHP}" \
            -spat ${_bbox} \
            -where "ORD_STRA >= ${_strahler}" 2>/dev/null || true
    fi

    if [[ ! -s "${cache}" ]]; then
        echo "  [WARN] No HydroRIVERS lines found for bbox '${_bbox}'" \
             "Strahler>=${_strahler}" >&2
    fi

    gmt begin "${OUT%.*}" "${FORMAT}"
        apply_gmt_defaults
        gmt basemap ${REGION} ${PROJ} -Bafg --MAP_FRAME_PEN=0p

        if [[ -s "${cache}" ]]; then
            # White halo for contrast over terrain, then coloured line
            gmt plot "${cache}" ${REGION} ${PROJ} -W2.8p,white@60
            gmt plot "${cache}" ${REGION} ${PROJ} -W1.5p,"${RIVER_COLOR}"
        fi
    gmt end
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
if [[ "${_cat}" == "Canal" ]]; then
    plot_canal
else
    plot_river
fi

echo "  Done: ${OUT}"
