#!/usr/bin/env bash
# =============================================================================
# 00_InstallDeps.sh  –  Install all dependencies on Linux
#
# Supports: Debian/Ubuntu (apt), Fedora (dnf), RHEL/CentOS (yum), openSUSE (zypper)
# Run with:  bash scripts/00_InstallDeps.sh
# =============================================================================

set -euo pipefail

echo "=== Detecting package manager ==="

if   command -v apt-get &>/dev/null; then DISTRO=debian
elif command -v dnf     &>/dev/null; then DISTRO=fedora
elif command -v yum     &>/dev/null; then DISTRO=rhel
elif command -v zypper  &>/dev/null; then DISTRO=suse
else
    echo "[ERROR] No supported package manager found (apt/dnf/yum/zypper)."
    exit 1
fi
echo "  Detected: ${DISTRO}"

install_debian() {
    sudo apt-get update -qq
    # Add UbuntuGIS PPA if GMT < 6.4
    local ver major minor
    ver=$(gmt --version 2>/dev/null || echo "0.0")
    major=$(echo "${ver}" | cut -d. -f1)
    minor=$(echo "${ver}" | cut -d. -f2)
    if (( major < 6 || ( major == 6 && minor < 4 ) )); then
        echo "  GMT < 6.4 detected; adding ubuntugis-unstable PPA..."
        sudo apt-get install -y software-properties-common
        sudo add-apt-repository -y ppa:ubuntugis/ubuntugis-unstable
        sudo apt-get update -qq
    fi
    sudo apt-get install -y \
        gmt gmt-dcw gmt-gshhg \
        gdal-bin \
        ghostscript \
        curl unzip bc
}

install_fedora() {
    sudo dnf install -y epel-release 2>/dev/null || true
    sudo dnf install -y GMT GMT-common gdal gdal-tools ghostscript curl unzip bc
}

install_rhel() {
    sudo yum install -y epel-release 2>/dev/null || true
    sudo yum install -y GMT gdal gdal-tools ghostscript curl unzip bc
}

install_suse() {
    sudo zypper install -y gmt gdal ghostscript curl unzip bc
}

case "${DISTRO}" in
    debian) install_debian ;;
    fedora) install_fedora ;;
    rhel)   install_rhel   ;;
    suse)   install_suse   ;;
esac

echo ""
echo "=== Verifying installations ==="

check() {
    local cmd="$1" label="$2"
    if command -v "${cmd}" &>/dev/null; then
        echo "  ${label}: OK  ($("${cmd}" --version 2>&1 | head -1))"
    else
        echo "  ${label}: MISSING"
    fi
}

check gmt       "GMT"
check ogr2ogr   "GDAL/ogr2ogr"
check gs        "Ghostscript"
check curl      "curl"

GMT_VER=$(gmt --version 2>/dev/null || echo "0.0")
GMT_MAJ=$(echo "${GMT_VER}" | cut -d. -f1)
GMT_MIN=$(echo "${GMT_VER}" | cut -d. -f2)
if (( GMT_MAJ > 6 || ( GMT_MAJ == 6 && GMT_MIN >= 4 ) )); then
    echo "  GMT version ${GMT_VER} >= 6.4  ✓"
else
    echo "  [WARN] GMT ${GMT_VER} < 6.4 — oleron CPT may not be available."
    echo "         Build from source: https://github.com/GenericMappingTools/gmt"
fi

echo ""
echo "=== Done. Next: bash scripts/01_Download.sh ==="
