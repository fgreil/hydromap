#!/usr/bin/env bash
# =============================================================================
# 60_Assemble.sh  –  Composite all layers into final PDF for one waterway
#
# Layer order (bottom → top):
#   1. background   (topo, coastlines, colorbar)
#   2. catchment    (polygon)
#   3. river        (lines / canal)
#   4. cities       (dots + labels)
#   5. legend       (box)
#
# Output: output/f418-eu-waterway-<ID>_<EnglishName>.pdf
#
# Standalone usage:
#   bash scripts/60_Assemble.sh L1
#
# Requires: ghostscript (gs)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/02_Common.sh"

ID="${1:?Usage: $0 <waterway-ID>  e.g. L1}"
ID="${ID^^}"

parse_river "${ID}"

FINAL="$(final_file "${ID}")"
STEM="${FINAL%.pdf}"

echo "=== 60_Assemble: ${ID} – ${_label} ==="
echo "  Output: ${FINAL}"

# ---------------------------------------------------------------------------
# Verify all input layers exist
# ---------------------------------------------------------------------------
BG="$(bg_file)"
CATCH="$(catch_file "${ID}")"
RIVER="$(river_file "${ID}")"
CITIES="$(cities_file)"
LEGEND="$(legend_file "${ID}")"

missing=0
for f in "${BG}" "${CATCH}" "${RIVER}" "${CITIES}" "${LEGEND}"; do
    [[ ! -f "${f}" ]] && { echo "  [ERROR] Missing layer: ${f}" >&2; (( missing++ )) || true; }
done
(( missing > 0 )) && { echo "  Run make <ID> to generate missing layers." >&2; exit 1; }

# ---------------------------------------------------------------------------
# Add map title as a PostScript DSC comment overlay
# Title: label  [ID]  |  length km
# ---------------------------------------------------------------------------
TITLE="${_label}  [${ID}]  |  ${_len} km"

# ---------------------------------------------------------------------------
# Composite with ghostscript
#   -dNOPAUSE -dBATCH    : non-interactive
#   -sDEVICE=pdfwrite    : PDF output
#   -dCompatibilityLevel : PDF 1.5
#   -r300                : 300 dpi rasterisation for raster elements
#   Input order = layer order (gs stacks in input order)
# ---------------------------------------------------------------------------
gs \
    -dNOPAUSE \
    -dBATCH \
    -dQUIET \
    -sDEVICE=pdfwrite \
    -dCompatibilityLevel=1.5 \
    -r300 \
    -dPDFSETTINGS=/prepress \
    -sOutputFile="${FINAL}" \
    "${BG}" \
    "${CATCH}" \
    "${RIVER}" \
    "${CITIES}" \
    "${LEGEND}"

# ---------------------------------------------------------------------------
# Verify output
# ---------------------------------------------------------------------------
if [[ -f "${FINAL}" ]]; then
    SIZE=$(du -sh "${FINAL}" | cut -f1)
    echo "  Done: ${FINAL}  (${SIZE})"
else
    echo "  [ERROR] Assembly failed – output not created." >&2
    exit 1
fi
