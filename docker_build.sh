#!/bin/bash
# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT

# Default version 2020.1
XILVER=${1:-2020.1}

# Check if the petalinux installer exists
PLNX="petalinux-v${XILVER}-final-installer.run"
if [ ! -f "$PLNX" ] ; then
    echo "$PLNX installer not found"
    exit 1
fi

INSTALL_VIVADO=""
VIVADO_INSTALLER=$(ls | grep Xilinx_Unified_${XILVER}* | tail -1)
if [ ${VIVADO_INSTALLER} ] ; then
    echo "Vivado installer found: ${VIVADO_INSTALLER}"
    echo "It will be installed in the Docker image"
    INSTALL_VIVADO="--build-arg VIVADO_INSTALLER=${VIVADO_INSTALLER}"
fi

echo "Creating Docker image docker_petalinux2:$XILVER..."
time docker build --build-arg PETA_VERSION=${XILVER} --build-arg PETA_RUN_FILE=${PLNX} ${INSTALL_VIVADO} -t docker_petalinux2:${XILVER} .
