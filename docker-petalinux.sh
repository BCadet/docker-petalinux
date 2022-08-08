#!/bin/bash
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

ACTION=$1
ACTION=${ACTION:="build"}
shift

FOLDER=${PWD##*/}
FOLDER=${FOLDER:-/}        # to correct for the case where PWD=/

function build_image() {
    export PETALINUX_INSTALLER=$(ls $PWD | grep petalinux-v[0-9.]*-final-installer.run)

    if [ -z $PETALINUX_INSTALLER ]; then
        echo "no petalinux installer found in $PWD"
        return
    fi

    IMAGE=${PETALINUX_INSTALLER,,} #convert lowercase (should always be)
    IMAGE=${IMAGE:0:17} # take the 17 first chars (should be petalinux-vxxxx.x )
    IMAGE=${IMAGE/-/:} # convert - to : -> the version become the docker image tag (petalinux:vxxxx.x)

    if [ $(echo "${PETALINUX_INSTALLER:11:17} >= 2020.1" | bc -l) -eq 1 ];
        then UBUNTU_VERSION=20.04
        elif [ $(echo "${VERSION} >= 2018.1" | bc -l) -eq 1 ];
        then UBUNTU_VERSION=18.04
        else UBUNTU_VERSION=16.04
    fi

    echo "-- basing docker image on ubuntu:$UBUNTU_VERSION"

    docker buildx build \
        -t $IMAGE \
        --build-arg UBUNTU_VERSION=$UBUNTU_VERSION \
        .
}

function run_image() {
    VERSION=$1

    if [ -z $IMAGE ]; then
        echo "please provide the petalinux image version you want to run (for example v2021.2)"
        return
    fi

    docker run -it --rm \
        -v `pwd`:/workspaces/$FOLDER \
        --workdir=/workspaces/$FOLDER \
        --env REMOTE_USER="builder" \
        --env NEW_UID=$(id -u) \
        --env NEW_GID=$(id -g) \
        petalinux:$VERSION
}

case $ACTION in
    "build")
        build_image
        ;;
    "run")
        run_image
        ;;
    *)
        echo "Action $ACTION not available"
        ;;
esac
