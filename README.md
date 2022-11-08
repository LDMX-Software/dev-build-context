# Development Container for ldmx-sw

<p align="center">
    <a href="http://perso.crans.org/besson/LICENSE.html" alt="GPLv3 license">
        <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" />
    </a>
    <a href="https://github.com/LDMX-Software/docker/actions" alt="Actions">
        <img src="https://github.com/LDMX-Software/docker/workflows/CI/badge.svg" />
    </a>
    <a href="https://hub.docker.com/r/ldmx/dev" alt="DockerHub">
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

Direct Dependecy of ldmx-sw | Version | Construction Process
---|---|---
[Ubuntu Server](https://ubuntu.com/) | 18.04 | Base Image
[Python](https://www.python.org/) | 3.6.9 | From Ubuntu Repos
[cmake](https://cmake.org/) | 3.18 | From python3 pip
[XercesC](http://xerces.apache.org/xerces-c/) | 3.2.3 | Built from source
[Pythia6](https://pythia.org/pythia6/) | 6.428 | Built from source
[ROOT](https://root.cern.ch/) | 6.22/08 | Built from source
[Geant4](https://geant4.web.cern.ch/node/1) | [LDMX.10.2.3\_v0.4](https://github.com/LDMX-Software/geant4/tree/LDMX.10.2.3_v0.4) | Built from source
[Eigen](https://eigen.tuxfamily.org/index.php?title=Main_Page) | 3.4.0 | Built from source
[DD4hep](https://github.com/AIDASoft/DD4hep) | 01-18 | Built from source
[LHAPDF](https://lhapdf.hepforge.org/) | 6.5.2 | Built from source
[GENIE](http://www.genie-mc.org/) | 3.02.00 | Built from source

A detailed list of all packages installed from ubuntu repositories is given [here](docs/ubuntu-packages.md).

### Python Packages for Analyses
Installed in Python 3.
- pip 
- Cython
- numpy
- uproot
- matplotlib
- xgboost
- sklearn

### Other Configuration
- SSL Certificates that will be trusted by container are in the `certs` directory

## Other Packages
If you would like another package included in the development container, please open an issue in this repository.

