#1/bin/bash
# A script for building one of the subprojects within the docker container.

PROJ=$1
CMAKE_BUILD="Release"
if [ "$1" == "debug" ] ; then
    CMAKE_BUILD="Debug"
    PROJ=$2
fi

BUILD_DIR=/build/${PROJ}
SRC_DIR=/code/${PROJ}

echo "# Building FPGA project: '${PROJ}'"
mkdir -p ${BUILD_DIR}
cd ${BUILD_DIR}
echo "# Running conan for simulator dependencies for FPGA project: '${PROJ}'"
conan install ${SRC_DIR} --build missing
echo "# Generating make files for FPGA project: '${PROJ}'"
cmake -DCMAKE_BUILD_TYPE=${CMAKE_BUILD} ${SRC_DIR}
echo "# Building FPGA project: '${PROJ}'"
cmake --build ${BUILD_DIR}