#!/bin/bash
# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT
#
# Run from a PetaLinux project directory

latest=$(docker image list | grep ^petalinux | awk '{ print $2 }' | sort | tail -1)
echo "Starting petalinux:$latest"
mkdir -p $PWD/tftpboot

SET_MIRROR_PATH=""
if [ $GENIUX_MIRROR_PATH ]
    then
        SET_MIRROR_PATH="-v $GENIUX_MIRROR_PATH:/source_mirror"
fi

SET_X_SERVER=""
if [ $DISPLAY ]
    then
        SET_X_SERVER="-e DISPLAY=$DISPLAY --net=host -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/home/petalinux/.Xauthority"
fi

SET_DOCKER_COMMAND=$@
OVERRIDE_EXTRYPOINT=""
if [ "$SET_DOCKER_COMMAND" ]
   then
        echo "$@" > ./command.sh
        chmod +x ./command.sh
        OVERRIDE_ENTRYPOINT="--entrypoint /bin/sh"
        SET_DOCKER_COMMAND="-l -c ./command.sh"
fi

docker run -ti $SET_X_SERVER $SET_MIRROR_PATH -v "$PWD":"$PWD" -v "$PWD/tftpboot":/tftpboot -w "$PWD" --rm -u petalinux $OVERRIDE_ENTRYPOINT petalinux:$latest $SET_DOCKER_COMMAND

if [ "$SET_DOCKER_COMMAND" ]
    then
        rm ./command.sh
fi
