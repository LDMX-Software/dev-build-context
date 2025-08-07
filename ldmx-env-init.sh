###############################################################################
# Environment initialization for LDMX SW container images
#   Assumptions:
#   - The installation location of ldmx-sw is defined in LDMX_SW_INSTALL
#     or it is located at ${HOME}/ldmx-sw/install or ${HOME}/install.
###############################################################################

# LDMX_SW_INSTALL is defined when building the production image or users
# can use it to specify a non-normal install location
if [ -z "${LDMX_SW_INSTALL+x}" ]; then
  if [ -z "${LDMX_BASE+x}" ]; then
    # LDMX_BASE not defined
    if [ -f "${HOME}/CMakeLists.txt" ]; then
      # HOME is ldmx-sw
      export LDMX_SW_INSTALL="${HOME}/install"
    elif [ -d "${HOME}/ldmx-sw" ]; then
      # HOME is ldmx-sw's parent directory
      export LDMX_SW_INSTALL="${HOME}/ldmx-sw/install"
    else
      # unable to auto-detect
      printf "[ldmx-env-init.sh] WARNING: %s\n" \
        "LDMX_SW_INSTALL is not defined and I wasn't able to deduce the location relative to ${HOME}." \
        "You may not be able to run ldmx-sw programs in this environment."
    fi
  else
    # LDMX_BASE defined
    export LDMX_SW_INSTALL="${LDMX_BASE}/ldmx-sw/install"
  fi
fi

if [ -n "${LDMX_SW_INSTALL+x}" ]; then
  export LD_LIBRARY_PATH="${LDMX_SW_INSTALL}/lib:${LD_LIBRARY_PATH}"
  export PYTHONPATH="${LDMX_SW_INSTALL}/python:${LDMX_SW_INSTALL}/lib:${PYTHONPATH}"
  export PATH="${LDMX_SW_INSTALL}/bin:${PATH}"
  export CMAKE_PREFIX_PATH="${CMAKE_PREFIX_PATH}:${LDMX_SW_INSTALL}"
fi
