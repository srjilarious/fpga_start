#!/bin/bash
# A script that provides a nicer interface for running these fpga builds 
# in docker.

SCRIPT_DIR=$(dirname "$0")

# Make sure the build and conan cache directory exist.
mkdir -p ${SCRIPT_DIR}/build/conan_data

CODE_DIR=$(realpath ${SCRIPT_DIR})
BUILD_DIR=$(realpath ${SCRIPT_DIR}/build/)
CONAN_CACHE=$(realpath ${SCRIPT_DIR}/build/conan_data/)

# echo "CODE_DIR = ${CODE_DIR}"
# echo "BUILD_DIR = ${BUILD_DIR}"
# echo "CONAN_CACHE = ${CONAN_CACHE}"

docker_shell ()
{
    mkdir -p ${BUILD_DIR}
    mkdir -p ${CODE_DIR}
    mkdir -p ${CONAN_CACHE}
    set -x
    docker run -it \
        -v ${CODE_DIR}:/code \
        -v ${BUILD_DIR}:/build \
        -v ${CONAN_CACHE}:/home/builder/.conan/data \
        fpga bin/bash --login
    set +x
}

build_project () 
{
    mkdir -p ${BUILD_DIR}
    mkdir -p ${CODE_DIR}
    mkdir -p ${CONAN_CACHE}
    set -x
    docker run -it \
        -v ${CODE_DIR}:/code \
        -v ${BUILD_DIR}:/build \
        -v ${CONAN_CACHE}:/home/builder/.conan/data \
        fpga bin/bash --login -c "/code/scripts/build_project.sh $1 $2"
    set +x
}

setup ()
{
    docker build -t fpga \
        --build-arg BUILDER_USER_ID=$(id -u ${USER}) \
        --build-arg BUILDER_GROUP_ID=$(id -g ${USER}) \
        ${SCRIPT_DIR}
}

case $1 in
    setup)
        setup 
        ;;

    shell)
        docker_shell 
        ;;

    build)
        build_project $2 $3
        ;;

    *)
        echo "Unknown sub-command '$1'"
        echo "Usage: dev.sh <command>:"
        echo "    dev.sh setup"
        echo "    dev.sh build [debug] <project>"
        echo "    dev.sh shell"
        ;; 
esac
