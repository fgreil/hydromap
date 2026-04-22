# =============================================================================
# Makefile  –  f418 European waterway maps
#
# Targets:
#   make all            build all 56 waterway PDFs (sequential)
#   make <ID>           build single waterway  e.g.  make L1
#   make C              build all canals        e.g.  make C
#   make background     rebuild topo background only
#   make cities         rebuild city layer only
#   make deps           install system dependencies
#   make download       fetch DEM + shapefiles
#   make clean          remove all generated output
#   make clean-layers   remove intermediate PS layers only (keep PDFs)
#
# Variables:
#   FORMAT=ps           intermediate format: ps (default), pdf, png
#
# Example:
#   make FORMAT=png L1
# =============================================================================

FORMAT   ?= ps
SHELL    := /usr/bin/env bash
SCRIPTS  := scripts

# ---------------------------------------------------------------------------
# All waterway IDs
# ---------------------------------------------------------------------------
ALL_IDS := \
    C1 C2 C3 C4 C5 C6 C7 \
    L1 L2 L3 L4 L5 L6 L7 \
    M1 M2 M3 M4 M5 M6 M7 \
    W1 W2 W3 W4 W5 W6 W7 \
    B1 B2 B3 B4 B5 B6 B7 \
    A1 A2 A3 A4 A5 A6 A7 \
    G1 G2 G3 G4 G5 G6 G7 \
    N1 N2 N3 N4 N5 N6 N7

# Category groups
C_IDS := C1 C2 C3 C4 C5 C6 C7
L_IDS := L1 L2 L3 L4 L5 L6 L7
M_IDS := M1 M2 M3 M4 M5 M6 M7
W_IDS := W1 W2 W3 W4 W5 W6 W7
B_IDS := B1 B2 B3 B4 B5 B6 B7
A_IDS := A1 A2 A3 A4 A5 A6 A7
G_IDS := G1 G2 G3 G4 G5 G6 G7
N_IDS := N1 N2 N3 N4 N5 N6 N7

PREFIX  := output/f418-eu
BG      := $(PREFIX)-background.$(FORMAT)
CITIES  := $(PREFIX)-cities.$(FORMAT)

# Final PDFs (one per waterway)
FINAL_PDFS := $(foreach id,$(ALL_IDS),$(shell \
    FORMAT=$(FORMAT) bash $(SCRIPTS)/02_Common.sh 2>/dev/null; \
    echo "output/f418-eu-waterway-$(id)_*.pdf"))

# ---------------------------------------------------------------------------
# Default target
# ---------------------------------------------------------------------------
.PHONY: all
all: $(foreach id,$(ALL_IDS),map-$(id))

# ---------------------------------------------------------------------------
# Shared layers (built once)
# ---------------------------------------------------------------------------
$(BG): $(SCRIPTS)/10_PlotMap.sh $(SCRIPTS)/02_Common.sh \
        europe_dem.nc
	FORMAT=$(FORMAT) bash $(SCRIPTS)/10_PlotMap.sh

$(CITIES): $(SCRIPTS)/40_PlotCities.sh $(SCRIPTS)/02_Common.sh \
            data/cities.csv
	FORMAT=$(FORMAT) bash $(SCRIPTS)/40_PlotCities.sh

.PHONY: background cities
background: $(BG)
cities:     $(CITIES)

# ---------------------------------------------------------------------------
# Per-waterway pattern rules
# ---------------------------------------------------------------------------

# Catchment layer
$(PREFIX)-catch_%.$(FORMAT): $(SCRIPTS)/20_PlotCatchment.sh \
                               $(SCRIPTS)/02_Common.sh \
                               data/river_data.csv \
                               ccm_data/catchments_dissolved.shp
	FORMAT=$(FORMAT) bash $(SCRIPTS)/20_PlotCatchment.sh $*

# River layer
$(PREFIX)-river_%.$(FORMAT): $(SCRIPTS)/30_PlotRiver.sh \
                               $(SCRIPTS)/02_Common.sh \
                               data/river_data.csv \
                               ccm_data/HydroRIVERS_v10_eu.shp
	FORMAT=$(FORMAT) bash $(SCRIPTS)/30_PlotRiver.sh $*

# Legend layer
$(PREFIX)-legend_%.$(FORMAT): $(SCRIPTS)/50_PlotLegend.sh \
                                $(SCRIPTS)/02_Common.sh \
                                data/river_data.csv
	FORMAT=$(FORMAT) bash $(SCRIPTS)/50_PlotLegend.sh $*

# Final assembly  (phony because filename encodes english name, harder to pattern-match)
.PHONY: map-%
map-%: $(BG) \
       $(PREFIX)-catch_%.$(FORMAT) \
       $(PREFIX)-river_%.$(FORMAT) \
       $(CITIES) \
       $(PREFIX)-legend_%.$(FORMAT)
	FORMAT=$(FORMAT) bash $(SCRIPTS)/60_Assemble.sh $*

# ---------------------------------------------------------------------------
# Category convenience targets
# ---------------------------------------------------------------------------
.PHONY: C L M W B A G N
C: $(foreach id,$(C_IDS),map-$(id))
L: $(foreach id,$(L_IDS),map-$(id))
M: $(foreach id,$(M_IDS),map-$(id))
W: $(foreach id,$(W_IDS),map-$(id))
B: $(foreach id,$(B_IDS),map-$(id))
A: $(foreach id,$(A_IDS),map-$(id))
G: $(foreach id,$(G_IDS),map-$(id))
N: $(foreach id,$(N_IDS),map-$(id))

# Individual ID convenience targets (e.g. make L1)
.PHONY: $(ALL_IDS)
$(ALL_IDS): %: map-%

# ---------------------------------------------------------------------------
# Data acquisition
# ---------------------------------------------------------------------------
.PHONY: deps download
deps:
	bash $(SCRIPTS)/00_InstallDeps.sh

download: europe_dem.nc ccm_data/HydroRIVERS_v10_eu.shp \
           ccm_data/catchments_dissolved.shp

europe_dem.nc ccm_data/HydroRIVERS_v10_eu.shp ccm_data/catchments_dissolved.shp:
	bash $(SCRIPTS)/01_Download.sh

# ---------------------------------------------------------------------------
# Cleaning
# ---------------------------------------------------------------------------
.PHONY: clean clean-layers
clean:
	rm -rf output/

clean-layers:
	rm -f output/$(PREFIX)-background.$(FORMAT)
	rm -f output/$(PREFIX)-cities.$(FORMAT)
	rm -f output/$(PREFIX)-catch_*.$(FORMAT)
	rm -f output/$(PREFIX)-river_*.$(FORMAT)
	rm -f output/$(PREFIX)-legend_*.$(FORMAT)
	rm -f output/$(PREFIX)-shade.nc
	rm -f output/$(PREFIX)-topo.cpt

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------
.PHONY: help
help:
	@echo "Usage:"
	@echo "  make all            Build all 56 waterway PDFs"
	@echo "  make <ID>           Build single waterway  (e.g. make L1)"
	@echo "  make <CAT>          Build category          (e.g. make C)"
	@echo "  make background     Rebuild topo background"
	@echo "  make cities         Rebuild city layer"
	@echo "  make deps           Install system dependencies"
	@echo "  make download       Fetch DEM and shapefiles"
	@echo "  make clean          Remove all output"
	@echo "  make clean-layers   Remove intermediate PS layers only"
	@echo ""
	@echo "Variables:"
	@echo "  FORMAT=ps|pdf|png   Intermediate format (default: ps)"
	@echo ""
	@echo "Categories: C L M W B A G N"
	@echo "IDs:        C1..C7  L1..L7  M1..M7  W1..W7"
	@echo "            B1..B7  A1..A7  G1..G7  N1..N7"
