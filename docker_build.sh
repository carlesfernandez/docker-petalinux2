#!/bin/bash
# SPDX-FileCopyrightText: 2021-2023, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-FileCopyrightText: 2024, Max Wipfli <mail@maxwipfli.ch>
# SPDX-License-Identifier: MIT

# Default version 2021.2
XILVER=${1:-2021.2}

cd installers || exit

# Check for Petalinux installer
PLNX="petalinux-v${XILVER}-final-installer.run"
if [ ! -f "$PLNX" ] ; then
    echo "$PLNX installer not found"
    cd ..
    exit 1
fi

# Check for Xilinx Unified installer (for Vivado)
VIVADO_INSTALLER_GLOB=Xilinx_Unified_"${XILVER}"
VIVADO_INSTALLER=$(find . -maxdepth 1 -name "${VIVADO_INSTALLER_GLOB}*" | tail -1)
VIVADO_UPDATE="Xilinx_Vivado_Vitis_Update_2021.2.1_1219_1431.tar.gz"
VIVADO_PATCH="y2k22_patch-1.2.zip"

# Create dummy patch file in root directory (will be overwritten if required)
echo "" > "../$VIVADO_PATCH"

if [ "${VIVADO_INSTALLER}" ] ; then
    echo "Xilinx Unified installer found: ${VIVADO_INSTALLER}"
    echo "Vivado will be installed in the Docker image."

    if [ "${XILVER}" == "2021.2" ] ; then
        echo "Vivado version ${XILVER}: checking for required additional files."

        if [ ! -f "$VIVADO_PATCH" ] ; then
          echo "$VIVADO_PATCH patch not found."
          echo "Download it from https://support.xilinx.com/s/article/76960?language=en_US and place it in the installers folder"
          exit 1
        fi

        if [ ! -f "$VIVADO_UPDATE" ] ; then
            echo "$VIVADO_UPDATE installer not found."
            echo "Download it from https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/archive.html and place it in the installers folder"
            exit 1
        fi

        cp -f "$VIVADO_PATCH" ..
    fi

    INSTALL_VIVADO=("--build-arg" VIVADO_INSTALLER="${VIVADO_INSTALLER}")
    if [ "${XILVER}" == "2020.1" ] ; then
        INSTALL_VIVADO=("--build-arg" VIVADO_INSTALLER="${VIVADO_INSTALLER}" "--build-arg" VIVADO_AGREE="3rdPartyEULA,WebTalkTerms,XilinxEULA")
    fi
    if [ "${XILVER}" == "2021.2" ] ; then
        INSTALL_VIVADO=("--build-arg" VIVADO_INSTALLER="${VIVADO_INSTALLER}" "--build-arg" VIVADO_UPDATE="${VIVADO_UPDATE}" "--build-arg" VIVADO_AGREE="3rdPartyEULA,XilinxEULA")
    fi
else
    echo "Xilinx Unified installer not found."
    echo "Vivado will NOT be installed in the Docker image."
fi

cd ..

# shellcheck disable=SC2009
if ! ps -fC python3 | grep "http.server" > /dev/null ; then
    python3 -m "http.server" &
    HTTPID=$!
    echo "HTTP Server started as PID $HTTPID"
    trap 'kill $HTTPID' EXIT QUIT SEGV INT HUP TERM ERR
fi

echo "Creating Docker image docker_petalinux2:$XILVER..."
time docker build --build-arg USERNAME=petalinux --build-arg UID=$(id -u) --build-arg GID=$(id -g) --build-arg PETA_VERSION="${XILVER}" --build-arg PETA_RUN_FILE="${PLNX}" "${INSTALL_VIVADO[@]}" -t docker_petalinux2:"${XILVER}" .
if [ -f "y2k22_patch-1.2.zip" ] ; then
    rm "y2k22_patch-1.2.zip"
fi

[ -n "$HTTPID" ] && kill "$HTTPID" && echo "Killed HTTP Server"
