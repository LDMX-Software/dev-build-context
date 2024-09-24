
FROM rootproject/root:6.32.04-ubuntu24.04
LABEL maintainer="Tom Eichlersmith <eichl008@umn.edu>, Tamas Almos Vami <Tamas.Almos.Vami@cern.ch>"

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
    autoconf \
    automake \
    binutils \
    cmake \
    curl\
    gcc g++ gfortran \
    locales \
    make \
    wget

# Packages necessary for Distrobox support
RUN install-ubuntu-packages \
    apt-utils \
    bc \
    dialog \
    diffutils \
    findutils \
    fish \
    gnupg2 \
    less \
    libnss-myhostname \
    libvte-2.9[0-9]-common \
    libvte-common \
    lsof \
    ncurses-base \
    passwd \
    pinentry-curses \
    procps \
    sudo \
    time \
    util-linux \
    zsh \
    libx11-dev \
    libxmu-dev \
    && rm -rf /var/lib/apt/lists/*

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

# this directory is where folks should "install" code compiled with the container
#    i.e. folks should mount a local install directory to /externals so that the
#    container can see those files and those files can be found from these env vars
ENV EXTERNAL_INSTALL_DIR=/externals
ENV PATH="${EXTERNAL_INSTALL_DIR}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${EXTERNAL_INSTALL_DIR}/lib"
ENV PYTHONPATH="${EXTERNAL_INSTALL_DIR}/lib:${EXTERNAL_INSTALL_DIR}/python:${EXTERNAL_INSTALL_DIR}/lib/python"
ENV CMAKE_PREFIX_PATH="${EXTERNAL_INSTALL_DIR}:${__prefix}" 

################################################################################
# Xerces-C 
#   Used by Geant4 to parse GDML
################################################################################
ENV XERCESC_VERSION="3.2.4"
LABEL xercesc.version=${XERCESC_VERSION}
#LABEL xercesc.version="3.2.4"
RUN mkdir src &&\
    ${__wget} http://archive.apache.org/dist/xerces/c/3/sources/xerces-c-${XERCESC_VERSION}.tar.gz |\
      ${__untar} &&\
    cmake -B src/build -S src -DCMAKE_INSTALL_PREFIX=${__prefix} &&\
    cmake --build src/build --target install -j$NPROC &&\
    rm -rf src


SHELL ["/bin/sh", "-c"] 

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
# Catch2
###############################################################################
ENV CATCH2_VERSION="3.3.1"
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

# Dependencies for LDMX-sw and/or the container environment
RUN install-ubuntu-packages \
    ca-certificates \
    clang-format \
    libboost-all-dev \
    libssl-dev

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

