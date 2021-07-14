
FROM ubuntu:18.04
LABEL ubuntu.version="18.04"
MAINTAINER Tom Eichlersmith <eichl008@umn.edu>

# First install any required dependencies from ubuntu repos
#   TODO clean up this dependency list
# Ongoing documentation for this list is in docs/ubuntu-packages.md
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
        binutils \
        ca-certificates \
        davix-dev \
        dcap-dev \
        dpkg-dev \
        fonts-freefont-ttf \
        g++-7 \
        gcc-7 \
        libafterimage-dev \
        libcfitsio-dev \
        libfcgi-dev \
        libfftw3-dev \
        libfreetype6-dev \
        libftgl-dev \
        libgfal2-dev \
        libgif-dev \
        libgl1-mesa-dev \
        libgl2ps-dev \
        libglew-dev \
        libglu-dev \
        libgraphviz-dev \
        libgsl-dev \
        libjpeg-dev \
        liblz4-dev \
        liblzma-dev \
        libmysqlclient-dev \
        libpcre++-dev \
        libpng-dev \
        libpq-dev \
        libpythia8-dev \
        libsqlite3-dev \
        libssl-dev \
        libtbb-dev \
        libtiff-dev \
        libx11-dev \
        libxext-dev \  
        libxft-dev \
        libxml2-dev \
        libxmu-dev \
        libxpm-dev \
        libz-dev \
        libzstd-dev \
        locales \
        make \
        python3-dev \
        python3-pip \
        python3-numpy \
        python3-tk \
        srm-ifce-dev \
        unixodbc-dev \
        wget \
    && rm -rf /var/lib/apt/lists/* &&\
    apt-get clean all &&\
    python3 -m pip install --upgrade --no-cache-dir cmake

###############################################################################
# Source-Code Downloading Method
#   mkdir src && ${__wget} <url-to-tar.gz-source-archive> | ${__untar}
#
#   Adapted from acts-project/machines
###############################################################################
ENV __wget wget -q -O -
ENV __untar tar -xz --strip-components=1 --directory src
ENV __prefix /usr/local

# All init scripts in this directory will be run upon entry into container
RUN mkdir /etc/ldmx-container-env.d/

###############################################################################
# Boost
###############################################################################
LABEL boost.version="1.76.0"
RUN mkdir src &&\
    ${__wget} https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz |\
      ${__untar} &&\
    cd src &&\
    ./bootstrap.sh &&\
    ./b2 install &&\
    cd .. && rm -rf src

################################################################################
# Xerces-C 
################################################################################
LABEL xercesc.version="3.2.3"
RUN mkdir src &&\
    ${__wget} http://archive.apache.org/dist/xerces/c/3/sources/xerces-c-3.2.3.tar.gz |\
      ${__untar} &&\
    cmake -B src/build -S src -DCMAKE_INSTALL_PREFIX=${__prefix} &&\
    cmake --build src/build --target install &&\
    rm -rf src

###############################################################################
# CERN's ROOT
###############################################################################
LABEL root.version="6.22.08"
RUN mkdir src &&\
    ${__wget} https://root.cern/download/root_v6.22.08.source.tar.gz |\
     ${__untar} &&\
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      -DCMAKE_INSTALL_PREFIX=${__prefix} \
      -Dgminimal=ON \
      -Dgdml=ON \
      -Dopengl=ON \
      -Dpyroot=ON \
      -Dgnuinstall=ON \
      -Dxrootd=OFF \
      -B build \
      -S src \
    && cmake --build build --target install &&\
    ln -s /usr/local/bin/thisroot.sh /etc/ldmx-container-env.d/thisroot.sh &&\
    rm -rf build src

###############################################################################
# Geant4
#
# Assumptions
#  - GEANT4 defined to be a release of geant4 or LDMX's fork of geant4
###############################################################################
ENV GEANT4=LDMX.10.2.3_v0.4
LABEL geant4.version="${GEANT4}"
RUN __owner="geant4" &&\
    echo "${GEANT4}" | grep -q "LDMX" && __owner="LDMX-Software" &&\
    mkdir src &&\
    ${__wget} https://github.com/${__owner}/geant4/archive/${GEANT4}.tar.gz | ${__untar} &&\
    cmake \
        -DGEANT4_INSTALL_DATA=ON \
        -DGEANT4_USE_GDML=ON \
        -DGEANT4_INSTALL_EXAMPLES=OFF \
        -DGEANT4_USE_OPENGL_X11=ON \
        -DCMAKE_INSTALL_PREFIX=${__prefix} \
        -B src/build \
        -S src \
        &&\
    cmake --build src/build --target install &&\
    ln -s /usr/local/bin/geant4.sh /etc/ldmx-container-env.d/geant4.sh &&\ 
    rm -rf src 

###############################################################################
# Extra python packages for analysis
###############################################################################
ENV PYTHONPATH /usr/local/lib
ENV CLING_STANDARD_PCH none
RUN python3 -m pip install --upgrade --no-cache-dir \
        Cython \
        uproot \
        numpy \
        matplotlib \
        xgboost \
        sklearn

# add any ssl certificates to the container to trust
COPY ./certs/ /usr/local/share/ca-certificates
RUN update-ca-certificates

#run environment setup when docker container is launched and decide what to do from there
#   will require the environment variable LDMX_BASE defined
COPY ./entry.sh /etc/
RUN chmod 755 /etc/entry.sh
ENTRYPOINT ["/etc/entry.sh"]
