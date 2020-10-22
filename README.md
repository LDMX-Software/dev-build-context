# Development Container for ldmx-sw

<p align="center">
    <a href="http://perso.crans.org/besson/LICENSE.html" alt="GPLv3 license">
        <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" />
    </a>
    <img src="https://github.com/LDMX-Software/docker/workflows/Build/badge.svg" />
    <a href="https://hub.docker.com/r/ldmx/dev">
        <img src="https://img.shields.io/github/v/release/LDMX-Software/docker" />
    </a>
</p>

Docker build context for developing and running ldmx-sw: [Docker Hub](https://hub.docker.com/repository/docker/ldmx/dev)

There is a corresponding workflow in [ldmx-sw](https://github.com/LDMX-Software/ldmx-sw) that generates a [production docker container](https://hub.docker.com/repository/docker/ldmx/pro) using the container generated by this build context as a base image.
This production container already has ldmx-sw built and installed on it and assumes the user wants to run the application.

### Use in ldmx-sw

In _ldmx-sw_, an [environment script](https://github.com/LDMX-Software/ldmx-sw/blob/master/scripts/ldmx-env.sh) is defined in `bash` to setup the environment for both `docker` and `singularity` correctly.
A description of this setup process is given for both [docker](docs/use_with_docker.md) and [singularity](docs/use_with_singularity.md) if you desire more information.

## Current Container Configuration
- Ubuntu 18.04 Server base image
- python dev, pip, and numpy packages for both versions 2 and 3
- All boost development packages
- cmake from python3 pip (currently version 3.18)
- ROOT built and installed from source for version 6.22 (branch v6-22-00-patches)
- XercesC built and installed from source version 3.2.3
- **Geant4 built and installed from source version [LDMX.up-kaons](https://github.com/LDMX-Software/geant4/releases/tag/LDMX.up-kaons)** which unnaturally biases up kaon-production for studying specific interactions in the ECal
- python packages uproot, numpy, matplotlib, xgboost, and sklearn for both versions 2 and 3
- SSL Certificates that will be trusted by container are in the `certs` directory

### Other Packages
If you would like another package included in the development container, please open an issue in this repository.

