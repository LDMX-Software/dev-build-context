###############################################################################
# Environment initialization for LDMX SW container images
#   Assumptions:
#   - The installation location of ldmx-sw is defined in LDMX_SW_INSTALL
#     or it is located at LDMX_BASE/ldmx-sw/install.
###############################################################################

# add ldmx-sw and ldmx-analysis installs to the various paths
# LDMX_SW_INSTALL is defined when building the production image or users
# can use it to specify a non-normal install location
if [ -z "${LDMX_SW_INSTALL+x}" ]; then
  if [ -z "${LDMX_BASE+x}" ]; then
    printf "[ldmx-env-init.sh] WARNING: %s\n" \
      "Neither LDMX_BASE nor LDMX_SW_INSTALL is defined." \
      "At least one needs to be defined to ensure a working installation."
  fi
  export LDMX_SW_INSTALL="${LDMX_BASE}/ldmx-sw/install"
fi
export LD_LIBRARY_PATH="${LDMX_SW_INSTALL}/lib:${LD_LIBRARY_PATH}"
export PYTHONPATH="${LDMX_SW_INSTALL}/python:${LDMX_SW_INSTALL}/lib:${PYTHONPATH}"
export PATH="${LDMX_SW_INSTALL}/bin:${PATH}"

#add what we need for GENIE 
export LD_LIBRARY_PATH="${GENIE}/lib:${GENIE_REWEIGHT}/lib:/usr/local/pythia6:${LD_LIBRARY_PATH}"
export PATH="${GENIE}/bin:${GENIE_REWEIGHT}/bin:${PATH}"

# Developer option: If a custom geant4 install is to be used, source the
# environment script from that install
#
# Note: Use with care!
# 
# The custom Geant4 install still needs to have been built with the same
# container environment
if [ -n "${LDMX_CUSTOM_GEANT4+x}" ]; then
    # Overly obnoxious warning to make sure this feature isn't used accidentally
    # Also detail how to set custom Geant4 data directories
    if [ -z "${LDMX_CUSTOM_GEANT4_CONFIRM_DEV+x}" ]; then
        echo "Warning: You are relying on a non-container version of Geant4. This mode of operation can come with some reproducibility concerns if you aren't careful. "
        echo "Define the environment variable LDMX_CUSTOM_GEANT4_CONFIRM_DEV in the container environment to suppress this message"
        echo "If using the standard ldmx-env.sh shell script, use 'ldmx setenv' to set environment variables within the container environment"
        echo "You may also want to define LDMX_CUSTOM_GEANT4_DATA_DIR if you are using a version of Geant4 different from 10.2.3 and the Geant4 build you intend to use has the data directory in an non-standard location (i.e. one that isn't picked up by the geant4.sh script) "
    fi
    # First: Unset the container-specific versions of the Geant4 data directories
    unset G4NEUTRONHPDATA
    unset G4LEDATA
    unset G4LEVELGAMMADATA
    unset G4RADIOACTIVEDATA
    unset G4PARTICLEXSDATA
    unset G4PIIDATA
    unset G4REALSURFACEDATA
    unset G4SAIDXSDATA
    unset G4ABLADATA
    unset G4INCLDATA
    unset G4ENSDFSTATEDATA
    unset G4NEUTRONXSDATA
    # If explicitly requested, use a custom location for Geant4's data directories
    if [ -n "${LDMX_CUSTOM_GEANT4_DATA_DIR+x}" ]; then
        export GEANT4_DATA_DIR="${LDMX_CUSTOM_GEANT4_DATA_DIR}"
    fi 
    # Source the custom geant's environment script
    # shellcheck disable=SC1091
    . "${LDMX_CUSTOM_GEANT4}/bin/geant4.sh"
    # Prioritize the cmake config in the Geant4 installation over the container location (/usr/local)
    export CMAKE_PREFIX_PATH="${LDMX_CUSTOM_GEANT4}/lib/cmake:/usr/local/:${CMAKE_PREFIX_PATH}"

    # If no directory was found by the geant4.sh script and the user didn't
    # explicitly ask for a location (e.g. for a debug build):
    #
    # Assume we are using 10.2.3 (container provided) data
    if [ -z "${GEANT4_DATA_DIR+x}" ]; then
        export GEANT4_DATA_DIR="${G4DATADIR}"
    fi
else
    # Tell CMake to look for configuration files in the container location by default
    export CMAKE_PREFIX_PATH="/usr/local/:${LDMX_SW_INSTALL}"
fi
