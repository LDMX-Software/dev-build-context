FROM ubuntu:24.04
LABEL maintainer="Tom Eichlersmith <eichl008@umn.edu>, Tamas Almos Vami <Tamas.Almos.Vami@cern.ch>"
LABEL ubuntu.version="24.04"

ARG NPROC=1


# Add a script to the container environment that lets us install a list of
# packages from the ubuntu repositories while keeping the size of the docker
# layer relatively small

# /usr/local/bin will be in the path so we can refer to the script without the
# full path
COPY install-ubuntu-packages.sh /usr/local/bin/install-ubuntu-packages
# Make it executable
RUN chmod +x /usr/local/bin/install-ubuntu-packages

# Ongoing documentation for packages used is in docs/ubuntu-packages.md
# Basic OS/System tools
RUN install-ubuntu-packages \
    binutils \
    cmake \
    gcc g++ gfortran \
    locales \
    make \
    wget

# Basic python support, necessary for the build steps.
#
# Note: If you want to add additional python packages, you probably want to do
# this in the python_packages.txt file rather than here
RUN install-ubuntu-packages \
    python3-dev \
    python3-numpy \
    python3-pip \
    python3-tk

###############################################################################
# Source-Code Downloading Method
#   mkdir src && ${__wget} <url-to-tar.gz-source-archive> | ${__untar}
#
#   Adapted from acts-project/machines
###############################################################################
ENV __wget="wget -q -O -"
ENV __untar_to="tar -xz --strip-components=1 --directory"
ENV __untar="${__untar_to} src"
ENV __prefix="/usr/local"

################################################################################
# Xerces-C 
#   Used by Geant4 to parse GDML
################################################################################
ENV XERCESC_VERSION="3.3.0"
LABEL xercesc.version=${XERCESC_VERSION}
RUN mkdir src &&\
    ${__wget} http://archive.apache.org/dist/xerces/c/3/sources/xerces-c-${XERCESC_VERSION}.tar.gz |\
      ${__untar} &&\
    cmake -B src/build -S src -DCMAKE_INSTALL_PREFIX=${__prefix} &&\
    cmake --build src/build --target install -j$NPROC &&\
    rm -rf src

###############################################################################
# LHAPDF
#
# Needed for GENIE
#
# - We disable the python subpackage because it is based on Python2 whose
#   executable has been removed from Ubuntu 22.04.
###############################################################################
LABEL lhapdf.version="6.5.5"
RUN mkdir src &&\
    ${__wget} https://lhapdf.hepforge.org/downloads/?f=LHAPDF-6.5.5.tar.gz |\
      ${__untar} &&\
    cd src &&\
    ./configure --disable-python --prefix=${__prefix} &&\
    make -j$NPROC install &&\
    cd ../ &&\
    rm -rf src

###############################################################################
# PYTHIA8
###############################################################################
RUN install-ubuntu-packages \
    rsync

LABEL pythia.version="8.313"
RUN mkdir src && \
    ${__wget} https://pythia.org/download/pythia83/pythia8313.tgz | ${__untar} &&\
    cd src &&\
    ./configure --with-lhapdf6 --prefix=${__prefix} &&\
    make -j$NPROC install &&\
    cd ../ &&\
    rm -rf src

###############################################################################
# CERN's ROOT
#  Needed for GENIE and serialization within the Framework
#
# We have a very specific configuration of the ROOT build system
# - Use C++17 so that ROOT doesn't re-define C++17 STL classes in its headers
#   We want to use C++17 in Framework and ROOT's redefinitions prevent that.
# - Use gnuinstall=ON and CMAKE_INSTALL_LIBDIR=lib to make ROOT be a system install
# - Start with a minimal build (gminimal) and then enable things from there.
# - Need asimage and opengl built for the ROOT GUIs to be functional.
# - Want pyroot to support some PyROOT-based analyses
# - Turn off xrootd since its build fails for some reason (and we don't need it)
# - gsl_shared, mathmore, and pytia6 are all used by GENIE
#
# After building and installing, we write a ld conf file to include ROOT's
# libraries in the linker cache, then rebuild the linker cache so that
# downstream libraries in this Dockerfile can link to ROOT easily.
#
# We promote the environment variables defined in thisroot.sh to this
# Dockerfile so that thisroot.sh doesn't need to be sourced.
###############################################################################

RUN install-ubuntu-packages \
    fonts-freefont-ttf \
    libafterimage-dev \
    libfftw3-dev \
    libfreetype6-dev \
    libftgl-dev \
    libgif-dev \
    libgl1-mesa-dev \
    libgl2ps-dev \
    libglew-dev \
    libglu-dev \
    libjpeg-dev \
    liblz4-dev \
    liblzma-dev \
    libpng-dev \
    libx11-dev \
    libxext-dev \
    libxft-dev \
    libxml2-dev \
    libxmu-dev \
    libxpm-dev \
    libz-dev \
    libzstd-dev \
    nlohmann-json3-dev \
    srm-ifce-dev \
    libgsl-dev

ENV ROOT_VERSION="6.34.10"
LABEL root.version=${ROOT_VERSION}
RUN mkdir src &&\
    ${__wget} https://root.cern/download/root_v${ROOT_VERSION}.source.tar.gz |\
     ${__untar} &&\
    cmake \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=20 \
      -DCMAKE_INSTALL_PREFIX=${__prefix} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -Dgnuinstall=ON \
      -Dgminimal=ON \
      -Dasimage=ON \
      -Dgeom=ON \
      -Dgdml=ON \
      -Dopengl=ON \
      -Dpyroot=ON \
      -Dxrootd=OFF \
      -Dmathmore=ON \   
      -Dpythia8=ON \    
      -B build \
      -S src \
    && cmake --build build --target install -j$NPROC &&\
    rm -rf build src &&\
    ldconfig
ENV ROOTSYS=${__prefix}
# first instance of PYTHONPATH, so no appending
ENV PYTHONPATH=${ROOTSYS}/lib
ENV CLING_STANDARD_PCH=none

###############################################################################
# Geant4
#
# - The normal ENV variables can be ommitted since we are installing to
#   a system path. We just need to copy the environment variables defining
#   the location of datasets. 
# - We configure Geant4 to always install the data to a specific path so 
#   the environment variables don't need to change if the version changes.
#
# Assumptions
#  - GEANT4 defined to be a release of geant4 or LDMX's fork of geant4
###############################################################################
ENV GEANT4=LDMX.10.2.3_v0.6
ENV G4DATADIR="${__prefix}/share/geant4/data"
LABEL geant4.version="${GEANT4}"
RUN __owner="geant4" &&\
    echo "${GEANT4}" | grep -q "LDMX" && __owner="LDMX-Software" &&\
    mkdir src &&\
    ${__wget} https://github.com/${__owner}/geant4/archive/${GEANT4}.tar.gz | ${__untar} &&\
    cmake \
        -DGEANT4_INSTALL_DATA=ON \
        -DGEANT4_INSTALL_DATADIR=${G4DATADIR} \
        -DGEANT4_USE_GDML=ON \
        -DGEANT4_INSTALL_EXAMPLES=OFF \
        -DGEANT4_USE_OPENGL_X11=ON \
        -DCMAKE_INSTALL_PREFIX=${__prefix} \
        -B src/build \
        -S src \
        &&\
    cmake --build src/build --target install -j$NPROC &&\
    rm -rf src 

ENV G4NEUTRONHPDATA="${G4DATADIR}/G4NDL4.5"
ENV G4LEDATA="${G4DATADIR}/G4EMLOW6.48"
ENV G4LEVELGAMMADATA="${G4DATADIR}/PhotonEvaporation3.2"
ENV G4RADIOACTIVEDATA="${G4DATADIR}/RadioactiveDecay4.3.2"
ENV G4PARTICLEXSDATA="${G4DATADIR}/G4PARTICLEXS3.1.1"
ENV G4PIIDATA="${G4DATADIR}/G4PII1.3"
ENV G4REALSURFACEDATA="${G4DATADIR}/RealSurface1.0"
ENV G4SAIDXSDATA="${G4DATADIR}/G4SAIDDATA1.1"
ENV G4ABLADATA="${G4DATADIR}/G4ABLA3.0"
ENV G4INCLDATA="${G4DATADIR}/G4INCL1.0"
ENV G4ENSDFSTATEDATA="${G4DATADIR}/G4ENSDFSTATE1.2.3"
ENV G4NEUTRONXSDATA="${G4DATADIR}/G4NEUTRONXS1.4"

################################################################################
# Install Eigen headers into container
#
# Assumptions
#  - EIGEN set to release name from GitLab repository
################################################################################
ENV EIGEN=3.4.0
LABEL eigen.version="${EIGEN}"
RUN mkdir src &&\
    ${__wget} https://gitlab.com/libeigen/eigen/-/archive/${EIGEN}/eigen-${EIGEN}.tar.gz |\
      ${__untar} &&\
    cmake \
        -DCMAKE_INSTALL_PREFIX=${__prefix} \
        -B src/build \
        -S src \
    &&\
    cmake \
        --build src/build \
        --target install \
        -j$NPROC \
    &&\
    rm -rf src 

###############################################################################
# Install HEPMC for use as in interface with GENIE
###############################################################################
ENV HEPMC3=3.3.0
LABEL hepmc3.version="${HEPMC3}"
RUN mkdir src &&\
    ${__wget} http://hepmc.web.cern.ch/hepmc/releases/HepMC3-${HEPMC3}.tar.gz |\
      ${__untar} &&\
    cmake \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      -DHEPMC3_ENABLE_ROOTIO:BOOL=ON \
#      -DHEPMC3_ENABLE_PROTOBUFIO:BOOL=ON \
      -DHEPMC3_ENABLE_TEST:BOOL=OFF \
      -DHEPMC3_INSTALL_INTERFACES:BOOL=ON \
      -DHEPMC3_BUILD_STATIC_LIBS:BOOL=ON \
      -DHEPMC3_BUILD_DOCS:BOOL=OFF \
      -DHEPMC3_ENABLE_PYTHON:BOOL=ON \
      -DHEPMC3_PYTHON_VERSIONS=3.10 \
      -B src/build \
      -S src \
    &&\
    cmake --build src/build --target install -j$NPROC && \
    rm -rf src


###############################################################################
# GENIE
#
# Needed for ... GENIE :)
#
# - GENIE looks in ${ROOTSYS}/lib for various ROOT libraries it depends on.
#   This is annoying because root installs its libs to ${ROOTSYS}/lib/root
#   when the gnuinstall parameter is ON. We fixed this by forcing ROOT to
#   install its libs to ${ROOTSYS}/lib even with gnuinstall ON.
# - liblog4cpp5-dev from the Ubuntu 22.04 repos seems to be functional
# - GENIE reads its configuration from files written into its source tree
#   (and not installed), so we need to keep its source tree around
#
# Some errors from the build configuration
# - The 'quota: not found' error can be ignored. It is just saving a snapshot
#   of the build environment.
# - The 'cant exec git' error is resolved within the perl script which
#   deduces the version from the files in the .git directory if git is
#   not installed.
###############################################################################

# See https://github.com/LDMX-Software/docker/pull/48
#
# Note that libgsl-dev needs to be available already when building ROOT
# so that the MathMore target can be build which is used by GENIE
RUN install-ubuntu-packages \
    liblog4cpp5-dev

LABEL genie.version=3.04.02
ENV GENIE_VERSION=3_04_02-ldmx
ENV GENIE=/usr/local/src/GENIE/Generator
LABEL genie.version=${GENIE_VERSION}

RUN mkdir -p ${GENIE} &&\
    #export ENV GENIE_GET_VERSION="$(echo "${GENIE_VERSION}" | sed 's,\.,_,g')" &&\
    ${__wget} https://github.com/wesketchum/Generator/archive/refs/tags/R-${GENIE_VERSION}.tar.gz |\
      ${__untar_to} ${GENIE} &&\
    cd ${GENIE} &&\
    ./configure \
      --enable-lhapdf6 \
      --disable-lhapdf5 \
      --enable-gfortran \
      --with-gfortran-lib=/usr/x86_64-linux-gnu/ \
      --disable-pythia6 \
      --enable-pythia8 \
      --with-pythia8-lib=${__prefix}/lib \
      --enable-test \
      --enable-hepmc3 \
      --with-hepmc3-lib=/usr/local/lib \
      --with-hepmc3-inc=/usr/local/include \
    && \
    make -j$NPROC && \
    make -j$NPROC install

ENV GENIE_REWEIGHT_VERSION=1_04_00
ENV GENIE_REWEIGHT=/usr/local/src/GENIE/Reweight
RUN mkdir -p ${GENIE_REWEIGHT} &&\
    #export ENV GENIE_REWEIGHT_GET_VERSION="$(echo ${GENIE_REWEIGHT_VERSION} | sed 's,\.,_,g' )" &&\ 
    ${__wget} https://github.com/GENIE-MC/Reweight/archive/refs/tags/R-${GENIE_REWEIGHT_VERSION}.tar.gz |\
    ${__untar_to} ${GENIE_REWEIGHT} &&\
    cd ${GENIE_REWEIGHT} &&\
    make -j$NPROC && \
    make -j$NPROC install

###############################################################################
# Catch2
###############################################################################
ENV CATCH2_VERSION="3.8.0"
LABEL catch2.version=${CATCH2_VERSION}
RUN mkdir -p src &&\
    ${__wget} https://github.com/catchorg/Catch2/archive/refs/tags/v${CATCH2_VERSION}.tar.gz |\
      ${__untar} &&\
    cmake -B src/build -S src &&\
    cmake --build src/build --target install -- -j$NPROC &&\
    rm -rf src

###############################################################################
# ONNX Runtime
#  Used for running inference within ldmx-sw
#  We don't have time to build onnxruntime from source due to the
#  6hr time limit of GitHub actions :(
#  The commented out RUN command below is what I would do to build
#  from source as tested on my local machine and it requires updating
#  cmake to 3.26 using pip
#  The current verison of ONNX in use in ldmx-sw only has amd pre-builds,
#  so I don't think it will be able to be used in arm architecture images.
#  For this reason, I am omitting it until future development is done.
###############################################################################
ENV ONNX_VERSION="1.15.0"
LABEL onnx.version=${ONNX_VERSION}
#RUN mkdir -p src &&\
#    ${__wget} https://github.com/microsoft/onnxruntime/archive/refs/tags/v${ONNX_VERSION}.tar.gz |\
#      ${__untar} &&\
#    cd src &&\
#    ./build.sh \
#      --config RelWithDebInfo \
#      --build_shared_lib \
#      --compile_no_warning_as_error \
#      --skip_submodule_sync \
#      --skip_tests \
#      --allow_running_as_root \
#    && cmake --build build/Linux/RelWithDebInfo --target install &&\
#    cd .. && rm -rf src
# download pre-built binaries for the correct ARCH
RUN set -x ;\
    ARCH="$(uname -m)" &&\
    if [ "x86_64" = "$ARCH" ]; then \
      onnx_arch="x64"; \
    elif [ "aarch64" = "$ARCH" ]; then \
      onnx_arch="aarch64"; \
    else \
      exit 0; \
    fi &&\
    mkdir -p src &&\
    release_stub="https://github.com/microsoft/onnxruntime/releases/download" &&\
    onnx_version="${ONNX_VERSION}" &&\
    ${__wget} ${release_stub}/v${onnx_version}/onnxruntime-linux-${onnx_arch}-${onnx_version}.tgz |\
      ${__untar} &&\
    install -D -m 0644 -t ${__prefix}/lib src/lib/* &&\
    install -D -m 0644 -t ${__prefix}/include src/include/* &&\
    rm -rf src

# Dependencies for LDMX-sw and/or the container environment
RUN install-ubuntu-packages \
    ca-certificates \
    clang-format \
    libboost-all-dev \
    libssl-dev

###############################################################################
# Acts
###############################################################################
ENV ACTS_VERSION="36.0.0"
LABEL acts.version=${ACTS_VERSION}
RUN mkdir -p src &&\
    ${__wget} https://github.com/acts-project/acts/archive/refs/tags/v${ACTS_VERSION}.tar.gz |\
      ${__untar} &&\
    cmake \
      -DCMAKE_CXX_STANDARD=20 \
      -B src/build \
      -S src &&\
    cmake --build src/build --target install &&\
    rm -rf src

###############################################################################
# Generate the linker cache
#    This should go AFTER all compiled dependencies so that the ld cache 
#    contains all of them.
#    Ubuntu includes /usr/local/lib in the linker cache generation by default,
#    so dependencies just need to write a ld conf file if their libs do not
#    get installed to that directory (e.g. ROOT)
###############################################################################
RUN ldconfig -v

###############################################################################
# Extra python packages for analysis
###############################################################################
COPY ./python_packages.txt /etc/python_packages.txt
RUN python3 -m pip install --no-cache-dir --break-system-packages --requirement /etc/python_packages.txt


# Optional tools and developer utilities
#
# If you want to add additional packages that aren't strictly necessary to build
# ldmx-sw or its dependencies, this is a good place to put them
RUN install-ubuntu-packages \
    clang \
    clang-tidy \
    clang-tools \
    cmake-curses-gui \
    gdb \
    libasan8 \
    lld

# add any ssl certificates to the container to trust
COPY ./certs/ /usr/local/share/ca-certificates
RUN update-ca-certificates

# copy environment initialization script into container
# and make sure the default profile will call it as well
COPY ./ldmx-env-init.sh /etc/
RUN printf "%s\n" \
      "# make sure LDMX_BASE is defined for ldmx-env-init.sh" \
      "if [ -z \"\${LDMX_BASE+x}\" ]; then" \
      "  export LDMX_BASE=\"\${HOME}\"" \
      "fi" \
      ". /etc/ldmx-env-init.sh" \
    >> /etc/skel/.profile

#run environment setup when docker container is launched and decide what to do from there
#   will require the environment variable LDMX_BASE defined
COPY ./entry.sh /etc/
RUN chmod 755 /etc/entry.sh
ENTRYPOINT ["/etc/entry.sh"]

