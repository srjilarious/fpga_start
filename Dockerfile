FROM ubuntu:20.10

ARG BUILDER_USER_ID
ARG BUILDER_GROUP_ID

RUN apt -y update
RUN apt -y install vim cmake git exa fd-find silversearcher-ag \
                build-essential clang bison flex gawk \
                make autoconf g++ flex bison

# Otherwise tzdata locks up asking for location.    
RUN DEBIAN_FRONTEND="noninteractive" apt-get -y install tzdata

RUN apt -y install libreadline-dev libeigen3-dev libsfml-dev \
                    tcl-dev libffi-dev git mercurial graphviz   \
                    xdot pkg-config python python3 libftdi-dev \
                    qt5-default python3-dev libboost-all-dev 

RUN mkdir /opt/tools_builds
RUN git clone https://git.veripool.org/git/verilator /opt/tools_builds/verilator && \
        cd /opt/tools_builds/verilator && \
        git checkout stable

# Build Verilator
RUN cd /opt/tools_builds/verilator && \
    autoconf && \
    /opt/tools_builds/verilator/configure && \
    make -j$(nproc) && \
    make install
    
# Build icestorm
RUN git clone https://github.com/cliffordwolf/icestorm.git /opt/tools_builds/icestorm && \
    cd /opt/tools_builds/icestorm && \
    make -j$(nproc) && \
    make install

RUN git clone https://github.com/YosysHQ/nextpnr /opt/tools_builds/nextpnr && \
    cd /opt/tools_builds/nextpnr && \
    cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local . && \
    make -j$(nproc) && \
    make install

RUN git clone https://github.com/cliffordwolf/yosys.git /opt/tools_builds/yosys && \
    cd /opt/tools_builds/yosys && \
    make -j$(nproc) && \
    make install

# Install conan
RUN apt install -y python3-pip
RUN pip install conan

RUN addgroup --gid $BUILDER_GROUP_ID builder

# Create a builder user with the given user and group id, but remove the password.
RUN useradd --create-home --uid $BUILDER_USER_ID --gid $BUILDER_GROUP_ID -p blah builder && \
        passwd -d builder

RUN DEBIAN_FRONTEND=noninteractive apt install -y \
    libgl1-mesa-dev libx11-dev libxrandr-dev \
    libfreetype6-dev libglew1.5-dev libjpeg8-dev \
    libsndfile1-dev libopenal-dev libudev-dev \
    libx11-xcb-dev libxcb-render0-dev \
    libxcb-render-util0-dev libxcb-xkb-dev \
    libxcb-icccm4-dev libxcb-image0-dev \
    libxcb-keysyms1-dev libxcb-randr0-dev \
    libxcb-shape0-dev libxcb-sync-dev libxcb-xfixes0-dev \
    libxcb-xinerama0-dev libxcb-dri3-dev libxcb-util-dev \
    libxt-dev libfontenc-dev libice-dev libsm-dev libxaw7-dev \
    libxt-dev libxcomposite-dev libxcursor-dev libxdamage-dev \
    libxfixes-dev libxft-dev libxi-dev libxinerama-dev \
    libxkbfile-dev libxmu-dev libxmuu-dev libxpm-dev \
    libxres-dev libxss-dev libxtst-dev libxv-dev libxvmc-dev \
    libxxf86vm-dev libxaw7-dev libxt-dev libxcomposite-dev \
    libxcursor-dev libxdamage-dev libxfixes-dev libxft-dev \
    libxi-dev libxinerama-dev libxkbfile-dev libxmu-dev \
    libxmuu-dev libxpm-dev libxss-dev libxtst-dev libxv-dev \
    libxvmc-dev libxxf86vm-dev 

RUN DEBIAN_FRONTEND=noninteractive apt install -y xorg openbox

# Install sudo (so conan can install dependencies) and add builder to sudoers within container.
RUN apt install -y sudo && \
    adduser builder sudo
    
# Switch to builder user and fix up conan options, add remote, etc.
USER builder
RUN conan profile new default --detect &&\
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.cppstd=17 default && \
    conan remote add bincrafters https://api.bintray.com/conan/bincrafters/public-conan #&& \
