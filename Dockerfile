FROM ubuntu:22.04

ARG BUILDER_USER_ID
ARG BUILDER_GROUP_ID

RUN apt -y update
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt -y install \
        vim \
        cmake \
        git \
        exa \
        fd-find \
        silversearcher-ag \
        build-essential \
        clang \
        bison \
        flex \
        gawk \
        make \
        autoconf \
        g++ \
        libreadline-dev \
        libeigen3-dev \
        libsfml-dev \
        tcl-dev \
        libffi-dev \
        mercurial \
        graphviz \
        xdot \
        pkg-config \
        python3 \
        python3-dev \
        python3-pip \
        libftdi-dev \
        qtbase5-dev \
        qtchooser \
        qt5-qmake \
        qtbase5-dev-tools \
        libboost-all-dev \
        apt-transport-https \
        ca-certificates \
        libgnutls30 \
        tzdata \
        libgl1-mesa-dev \
        libx11-dev \
        libxrandr-dev \
        libfreetype6-dev \
        libglew-dev \
        libjpeg8-dev \
        libsndfile1-dev \
        libopenal-dev \
        libudev-dev \
        libx11-xcb-dev \
        libxcb-render0-dev \
        libxcb-render-util0-dev \
        libxcb-xkb-dev \
        libxcb-icccm4-dev \
        libxcb-image0-dev \
        libxcb-keysyms1-dev \
        libxcb-randr0-dev \
        libxcb-shape0-dev \
        libxcb-sync-dev libxcb-xfixes0-dev \
        libxcb-xinerama0-dev \
        libxcb-dri3-dev \
        libxcb-util-dev \
        libxt-dev \
        libfontenc-dev \
        libice-dev \
        libsm-dev \
        libxaw7-dev \
        libxt-dev \
        libxcomposite-dev \
        libxcursor-dev \
        libxdamage-dev \
        libxfixes-dev \
        libxft-dev \
        libxi-dev \
        libxinerama-dev \
        libxkbfile-dev \
        libxmu-dev \
        libxmuu-dev \
        libxpm-dev \
        libxres-dev \
        libxss-dev \
        libxtst-dev \
        libxv-dev \
        libxvmc-dev \
        libxxf86vm-dev \
        libxaw7-dev \
        libxt-dev \
        libxcomposite-dev \
        libxcursor-dev \
        libxdamage-dev \
        libxfixes-dev \
        libxft-dev \
        libxi-dev \
        libxinerama-dev \
        libxkbfile-dev \
        libxmu-dev \
        libxmuu-dev \
        libxpm-dev \
        libxss-dev \
        libxtst-dev \
        libxv-dev \
        libxvmc-dev \
        libxxf86vm-dev \
        && apt clean \
        && rm -rf /var/lib/apt/lists/*

RUN update-ca-certificates

# Update certificate of git.veripool.org
RUN openssl s_client -showcerts -servername git.veripool.org -connect git.veripool.org:443 </dev/null 2>/dev/null | sed -n -e '/BEGIN\ CERTIFICATE/,/END\ CERTIFICATE/ p' > git-veripool-org.pem
RUN cat git-veripool-org.pem | tee -a /etc/ssl/certs/ca-certificates.crt

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

RUN git clone --recursive https://github.com/YosysHQ/prjtrellis /opt/tools_builds/trellis && \
    cd /opt/tools_builds/trellis/libtrellis && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local . && \
    make && \
    make install 
    
# Build nextpnr w/ icestorm(lattice ice40) and trellis(lattice ecp5) fpga support
RUN git clone https://github.com/YosysHQ/nextpnr /opt/tools_builds/nextpnr && \
    cd /opt/tools_builds/nextpnr && \
    cmake -DARCH=ice40 -DCMAKE_INSTALL_PREFIX=/usr/local . && \
    make -j$(nproc) && \
    make install

RUN cd /opt/tools_builds/nextpnr && \
    cmake -DARCH=ecp5 -DTRELLIS_INSTALL_PREFIX=/usr/local . && \
    make -j$(nproc) && \
    make install

RUN git clone https://github.com/cliffordwolf/yosys.git /opt/tools_builds/yosys && \
    cd /opt/tools_builds/yosys && \
    make -j$(nproc) && \
    make install


RUN addgroup --gid $BUILDER_GROUP_ID builder

# Create a builder user with the given user and group id, but remove the password.
RUN useradd --create-home --uid $BUILDER_USER_ID --gid $BUILDER_GROUP_ID -p blah builder && \
        passwd -d builder

# Install sudo (so conan can install dependencies) and add builder to sudoers within container.
RUN adduser builder sudo
    
# Install conan
RUN pip install conan

# Switch to builder user and fix up conan options, add remote, etc.
USER builder
RUN conan profile new default --detect &&\
    conan profile update settings.compiler.libcxx=libstdc++11 default && \
    conan profile update settings.cppstd=17 default && \
    conan remote remove conancenter && \ 
    conan remote add conancenter https://center.conan.io false