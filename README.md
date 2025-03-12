<!-- 
DEVELOPER NOTICE

Since this file is not in docs/src but we still copy it there for creating the website,
we need to have all links in this file be the full link to the website so that the
website works properly.

Instead of
    [my link](docs/src/page.md)
Do
    [my link](https://ldmx-software.github.io/dev-build-context/page.html)
-->

# Development Image Build Context
The build context for the `ldmx/dev` images used for developing and running ldmx-sw.

<p align="center">
    <a href="http://perso.crans.org/besson/LICENSE.html" alt="GPLv3 license">
        <img src="https://img.shields.io/badge/License-GPLv3-blue.svg" />
    </a>
    <a href="https://github.com/LDMX-Software/dev-build-context/actions/workflows/ci.yml" alt="Actions">
        <img src="https://github.com/LDMX-Software/dev-build-context/actions/workflows/ci.yml/badge.svg" />
    </a>
    <a href="https://hub.docker.com/r/ldmx/dev" alt="DockerHub">
        <img src="https://img.shields.io/github/v/release/LDMX-Software/dev-build-context" />
    </a>
</p>

There is a corresponding workflow in [ldmx-sw](https://github.com/LDMX-Software/ldmx-sw) that generates a [production image](https://hub.docker.com/r/ldmx/pro) using the image generated by this build context as a base image.
This production image already has ldmx-sw built and installed on it and assumes the user wants to run the application.

## Usage
The image is designed to be used with [`denv`](https://tomeichlersmith.github.io/denv/)
which provides support for Docker, Podman, and Apptainer.

## Software in Image

Software Package | Version | Construction Process
---|---|---
[Ubuntu Server](https://ubuntu.com/) | 24.04 | Base Image
[Python](https://www.python.org/) | 3.12.3 | From Ubuntu Repos
[cmake](https://cmake.org/) | 3.28.3 | From Ubuntu Repos
[Boost](https://www.boost.org/doc/libs/1_74_0/) | 1.83.0 | From Ubuntu Repos
[XercesC](http://xerces.apache.org/xerces-c/) | 3.3.0 | Built from source
[LHAPDF](https://www.lhapdf.org/) | 6.5.5 | Built from source
[Pythia8](https://pythia.org/) | 8.313 | Built from source
[ROOT](https://root.cern.ch/) | 6.34.04 | Built from source
[Geant4](https://geant4.web.cern.ch/) | [LDMX.10.2.3\_v0.6](https://github.com/LDMX-Software/geant4/tree/LDMX.10.2.3_v0.6) | Built from source
[Eigen](https://eigen.tuxfamily.org/index.php?title=Main_Page) | 3.4.0 | Built from source
[HEPMC3](https://hepmc.web.cern.ch) | 3.3.0 | Built from source
[GENIE](http://www.genie-mc.org/) Generator | [3.02.02-ldmx](https://github.com/wesketchum/Generator/releases/tag/R-3_04_02-ldmx) | Built from source
[GENIE](http://www.genie-mc.org/) Reweight | 1.04.00 | Built from Source
[Catch2](https://github.com/catchorg/Catch2) | 3.3.1 | Built from source
[ONNX Runtime](https://github.com/microsoft/onnxruntime) | 1.15.0 | Download pre-built binaries

A detailed list of all packages installed from ubuntu repositories is given
[here](https://ldmx-software.github.io/dev-build-context/ubuntu-packages.html),
and documentation on the workflow and runner used to build the image is
[here](https://ldmx-software.github.io/dev-build-context/runner.html).

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

