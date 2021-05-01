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

echo "Creating Docker image petalinux:$XILVER..."
time docker build --build-arg PETA_VERSION=${XILVER} --build-arg PETA_RUN_FILE=${PLNX} -t petalinux:${XILVER} .
