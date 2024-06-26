#!/bin/bash
# SPDX-FileCopyrightText: 2021, Carles Fernandez-Prades <carles.fernandez@cttc.es>
# SPDX-License-Identifier: MIT
#
# Run from a PetaLinux project directory

latest=$(docker image list | grep ^docker_petalinux2 | awk '{ print $2 }' | sort | tail -1)
echo "Starting petalinux2:$latest"
mkdir -p "$PWD"/tftpboot

SET_MIRROR_PATH_AUX=""
if [ "$GENIUX_MIRROR_PATH" ]
    then
        SET_MIRROR_PATH_AUX="-v $GENIUX_MIRROR_PATH:/source_mirror"
fi
IFS=" " read -r -a SET_MIRROR_PATH <<< "$SET_MIRROR_PATH_AUX"

if [ "$DISPLAY" ]
    then
        SET_X_SERVER_AUX="-e DISPLAY=$DISPLAY --net=host -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/home/petalinux/.Xauthority"
fi
IFS=" " read -r -a SET_X_SERVER <<< "$SET_X_SERVER_AUX"

if [ "${SET_DOCKER_COMMAND_AUX[0]}" ]
   then
        echo "$@" > ./command.sh
        chmod +x ./command.sh
        OVERRIDE_ENTRYPOINT_AUX="--entrypoint /bin/bash"
        SET_DOCKER_COMMAND_AUX="-l -c ./command.sh"
fi
IFS=" " read -r -a OVERRIDE_ENTRYPOINT <<< "$OVERRIDE_ENTRYPOINT_AUX"
IFS=" " read -r -a SET_DOCKER_COMMAND <<< "$SET_DOCKER_COMMAND_AUX"

docker run -ti "${SET_X_SERVER[@]}" "${SET_MIRROR_PATH[@]}" -v "$PWD":"$PWD":z -v "$PWD/tftpboot":/tftpboot:z -w "$PWD" --rm -u petalinux "${OVERRIDE_ENTRYPOINT[@]}" docker_petalinux2:"${latest}" "${SET_DOCKER_COMMAND[@]}"

if [ "$OVERRIDE_ENTRYPOINT_AUX" ]
    then
        rm ./command.sh
fi
