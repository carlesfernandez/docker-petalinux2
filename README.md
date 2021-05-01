<!-- prettier-ignore-start -->
[comment]: # (
SPDX-License-Identifier: MIT
)

[comment]: # (
SPDX-FileCopyrightText: 2021 Carles Fernandez-Prades <carles.fernandez@cttc.es>
)
<!-- prettier-ignore-end -->

# docker-petalinux2

A somehow generic Xilinx PetaLinux docker file, using Ubuntu (though some tweaks
might be possible for Windows).

It was successfully tested with version `2020.1` _which is the oldest version
handled by this release_. For former versions, please check
[docker-petalinux](https://github.com/carlesfernandez/docker-petalinux).

## Prepare Petalinux installer

The PetaLinux Installer is to be downloaded from the
[Xilinx's Embedded Design Tools website](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html).

Place the downloaded `petalinux-v<VERSION>-final-installer.run` file (where
`<VERSION>` can be `2020.1`, `2020.2`, ...) in the same folder than the
Dockerfile.

## Build the image

Run:

    ./docker_build.sh <VERSION>

> The default for `<VERSION>`, if not specified, is `2020.1`.

## Work with a PetaLinux project

A helper script `petalin2.sh` is provided that should be run _inside_ a
petalinux project directory. It basically is a shortcut to:

    docker run -ti -v "$PWD":"$PWD" -w "$PWD" --rm -u petalinux petalinux:<latest version> $@

When run without arguments, a shell will spawn, _with PetaLinux `settings.sh`
already sourced_, so you can directly execute `petalinux-*` commands.

    user@host:/path/to/petalinux_project$ /path/to/petalin2.sh
    petalinux@host:/path/to/petalinux_project$ petalinux-build

Otherwise, the arguments will be executed as a command. Example:

    user@host:/path/to/petalinux_project$ /path/to/petalin2.sh \
    "petalinux-create -t project --template zynq --name myproject"
