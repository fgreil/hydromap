#!/usr/bin/env bash
# =============================================================================
# 02_Common.sh  –  SOURCE THIS FILE, never execute directly.
#
# Provides:
#   - Project-wide variables (paths, GMT settings, colours)
#   - load_river_data()  : populates RIVER_* arrays from river_data.csv
#   - load_city_data()   : populates CITY_* arrays from cities.csv
#   - parse_river()      : sets _id _label _english _cat _len _bbox
#                          _strahler _main_bas _canal_pts  for one ID
#   - apply_gmt_defaults()
#   - filename_for()     : returns canonical output filename stem for an ID
# =============================================================================

# ---------------------------------------------------------------------------
# GUARD: prevent double-sourcing
# ---------------------------------------------------------------------------
[[ -n "${_F418_COMMON_LOADED:-}" ]] && return 0
_F418_COMMON_LOADED=1

# ---------------------------------------------------------------------------
# PROJECT
# ---------------------------------------------------------------------------
PROJECT_ID="f418"
PREFIX="${PROJECT_ID}-eu"

# ---------------------------------------------------------------------------
# DIRECTORY LAYOUT  (resolved relative to project root)
# ---------------------------------------------------------------------------
COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${COMMON_DIR}/.." && pwd)"

DATA_DIR="${PROJECT_ROOT}/data"
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
OUTPUT_DIR="${PROJECT_ROOT}/output"
TMPDIR_GMT="/tmp/${PREFIX}_$$"

mkdir -p "${OUTPUT_DIR}" "${TMPDIR_GMT}"
# Clean up temp dir on exit (only register once)
trap 'rm -rf "${TMPDIR_GMT}"' EXIT

# ---------------------------------------------------------------------------
# INPUT DATA FILES
# ---------------------------------------------------------------------------
RIVER_CSV="${DATA_DIR}/river_data.csv"
CITIES_CSV="${DATA_DIR}/cities.csv"

# ---------------------------------------------------------------------------
# GEODATA PATHS  (populated by 01_Download.sh)
# ---------------------------------------------------------------------------
DEM="${PROJECT_ROOT}/europe_dem.nc"
RIVER_SHP="${PROJECT_ROOT}/ccm_data/HydroRIVERS_v10_eu.shp"
CATCH_SHP="${PROJECT_ROOT}/ccm_data/catchments_dissolved.shp"

# ---------------------------------------------------------------------------
# MAP SETTINGS
# ---------------------------------------------------------------------------
# Region: 25°W–45°E, 37°N–72°N
REGION="-R-25/45/37/72"
# Lambert Conformal Conic: std parallels 40/68 N, centre 10 E / 54 N
PROJ="-JL10/54/40/68/20c"

CPT="${OUTPUT_DIR}/${PREFIX}-topo.cpt"
SHADE="${OUTPUT_DIR}/${PREFIX}-shade.nc"

# ---------------------------------------------------------------------------
# OUTPUT FORMAT  (overridden by Makefile via FORMAT env variable)
# ---------------------------------------------------------------------------
FORMAT="${FORMAT:-ps}"

# ---------------------------------------------------------------------------
# COLOURS  (colorblind-safe)
# ---------------------------------------------------------------------------
CATCH_COLOR="#0077BB"    # catchment fill  (blue, 55% transparent in GMT)
RIVER_COLOR="#EE7733"    # river / canal line (orange)
SEA_COLOR="#C8E8F4"      # sea and lakes
BORDER_COLOR="#444444"   # country borders
CITY_CAP_COLOR="black"   # capital dot
CITY_NON_COLOR="#555555" # non-capital dot

# ---------------------------------------------------------------------------
# GMT DEFAULTS
# ---------------------------------------------------------------------------
apply_gmt_defaults() {
    gmt gmtset \
        FORMAT_GEO_MAP=ddd:mm:ssF      \
        MAP_FRAME_TYPE=plain            \
        FONT_ANNOT_PRIMARY="9p,Helvetica,black"       \
        FONT_LABEL="10p,Helvetica,black"              \
        MAP_GRID_PEN_PRIMARY="0.15p,grey75"           \
        MAP_TITLE_OFFSET=0.3c           \
        PS_MEDIA=A4
}

# ---------------------------------------------------------------------------
# LOAD RIVER DATA from CSV into indexed arrays
#
# Populates parallel arrays indexed 0..N-1:
#   RD_ID[]  RD_LABEL[]  RD_ENGLISH[]  RD_CAT[]  RD_LEN[]
#   RD_BBOX[]  RD_STRAHLER[]  RD_MAIN_BAS[]  RD_CANAL_PTS[]
#
# Also populates associative array RD_IDX[id]=index for fast lookup.
# ---------------------------------------------------------------------------
declare -a RD_ID RD_LABEL RD_ENGLISH RD_CAT RD_LEN \
           RD_BBOX RD_STRAHLER RD_MAIN_BAS RD_CANAL_PTS
declare -A RD_IDX

load_river_data() {
    [[ ${#RD_ID[@]} -gt 0 ]] && return 0   # already loaded
    local i=0
    while IFS=, read -r id label english cat len bbox strahler main_bas canal_pts; do
        # skip header
        [[ "${id}" == "id" ]] && continue
        # strip surrounding quotes from quoted fields
        label="${label//\"/}"
        english="${english//\"/}"
        bbox="${bbox//\"/}"
        canal_pts="${canal_pts//\"/}"
        RD_ID[i]="${id}"
        RD_LABEL[i]="${label}"
        RD_ENGLISH[i]="${english}"
        RD_CAT[i]="${cat}"
        RD_LEN[i]="${len}"
        RD_BBOX[i]="${bbox}"
        RD_STRAHLER[i]="${strahler}"
        RD_MAIN_BAS[i]="${main_bas}"
        RD_CANAL_PTS[i]="${canal_pts}"
        RD_IDX["${id}"]="${i}"
        (( i++ )) || true
    done < "${RIVER_CSV}"
}

# ---------------------------------------------------------------------------
# PARSE ONE RIVER ENTRY by ID
# Sets: _id _label _english _cat _len _bbox _strahler _main_bas _canal_pts
# ---------------------------------------------------------------------------
parse_river() {
    local id="$1"
    load_river_data
    if [[ -z "${RD_IDX[${id}]+x}" ]]; then
        echo "[ERROR] Unknown waterway ID '${id}'" >&2; return 1
    fi
    local i="${RD_IDX[${id}]}"
    _id="${RD_ID[i]}"
    _label="${RD_LABEL[i]}"
    _english="${RD_ENGLISH[i]}"
    _cat="${RD_CAT[i]}"
    _len="${RD_LEN[i]}"
    _bbox="${RD_BBOX[i]}"
    _strahler="${RD_STRAHLER[i]}"
    _main_bas="${RD_MAIN_BAS[i]}"
    _canal_pts="${RD_CANAL_PTS[i]}"
}

# ---------------------------------------------------------------------------
# LOAD CITY DATA from CSV into parallel arrays
#   CT_LON[]  CT_LAT[]  CT_NAME[]  CT_CAP[]
# ---------------------------------------------------------------------------
declare -a CT_LON CT_LAT CT_NAME CT_CAP

load_city_data() {
    [[ ${#CT_LON[@]} -gt 0 ]] && return 0
    local i=0
    while IFS=, read -r lon lat name capital; do
        [[ "${lon}" == "lon" ]] && continue
        CT_LON[i]="${lon}"
        CT_LAT[i]="${lat}"
        CT_NAME[i]="${name}"
        CT_CAP[i]="${capital}"
        (( i++ )) || true
    done < "${CITIES_CSV}"
}

# ---------------------------------------------------------------------------
# CANONICAL OUTPUT FILENAME STEM for a waterway ID
# Pattern: f418-eu-waterway-L1_Danube
# ---------------------------------------------------------------------------
filename_for() {
    local id="$1"
    parse_river "${id}"
    echo "${PREFIX}-waterway-${id}_${_english}"
}

# ---------------------------------------------------------------------------
# LAYER FILE PATHS
# ---------------------------------------------------------------------------
bg_file()      { echo "${OUTPUT_DIR}/${PREFIX}-background.${FORMAT}"; }
catch_file()   { echo "${OUTPUT_DIR}/${PREFIX}-catch_${1}.${FORMAT}"; }
river_file()   { echo "${OUTPUT_DIR}/${PREFIX}-river_${1}.${FORMAT}"; }
cities_file()  { echo "${OUTPUT_DIR}/${PREFIX}-cities.${FORMAT}"; }
legend_file()  { echo "${OUTPUT_DIR}/${PREFIX}-legend_${1}.${FORMAT}"; }
final_file()   { echo "${OUTPUT_DIR}/$(filename_for "${1}").pdf"; }

# ---------------------------------------------------------------------------
# ALL WATERWAY IDs IN ORDER
# ---------------------------------------------------------------------------
ALL_IDS=(
    C1 C2 C3 C4 C5 C6 C7
    L1 L2 L3 L4 L5 L6 L7
    M1 M2 M3 M4 M5 M6 M7
    W1 W2 W3 W4 W5 W6 W7
    B1 B2 B3 B4 B5 B6 B7
    A1 A2 A3 A4 A5 A6 A7
    G1 G2 G3 G4 G5 G6 G7
    N1 N2 N3 N4 N5 N6 N7
)
