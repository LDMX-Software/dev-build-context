# Ubuntu Packages
Here I try to list all of the installed ubuntu packages and give an explanation of why they are included.
Lot's of these packages are installed into the [ROOT official docker container](https://github.com/root-project/root-docker/blob/master/ubuntu2404/packages) and so I have copied them into this image.
I have looked into their purpose by a combination of googling the package name and looking at [ROOT's reason for them](https://root.cern/install/dependencies/). 

In the Dockerfile, most packages are added when they are needed for the rest of
the build. Adding packages before they are needed means the container needs to
be rebuilt starting from the point you add them, so it is a good habit to avoid
doing so. There is a helper script installed in the container
`install-ubuntu-packages` that can be called directly in the Dockerfile with a
list of packages to install.

If you want to add additional packages that aren't necessary for building
ldmx-sw, its dependencies, or the container environment use the install command
at the end of the Dockerfile.

~~~admonish warning title="Python Packages"
If you are looking to add python packages, prefer adding them to the
[python packages file](https://github.com/LDMX-Software/dev-build-context/blob/main/python_packages.txt)
rather than installing them from the ubuntu repositories.
~~~

~~~admonish note collapsible=true title="Extracting Package List from Dockerfile"
We have settled into a relatively simple syntax for the packages in the Dockerfile
and thus I've been able to write an `awk` script that can parse the Dockerfile
and list the packages we install from the ubuntu repositories.
```awk
{{ #include get-ubuntu-packages.awk }}
```
which is stored in `docs/src` and can be run like
```
awk -f docs/src/get-ubuntu-packages.awk Dockerfile
```
~~~

Package | Reason
---|---
binutils | Adding PPA and linking libraries
cmake | Configuration of build system
gcc | GNU C Compiler
g++ | GNU C++ Compiler
gfortran | GNU Fortran Compiler
locales | Configuration of TPython and other python packages
make | Building system for dependencies and ldmx-sw
wget | Download source files for dependencies and ldmx-sw Conditions
python3-dev | ROOT TPython and ldmx-sw configuration system
python3-numpy | ROOT TPython requires numpy and downstream analysis packages
python3-pip | Downloading more python packages
python3-tk | matplotlib requires python-tk for some plotting
rsync | necessary to build Pythia8 
fonts-freefont-ttf | fonts for plots with ROOT
libafterimage-dev | ROOT GUI needs these for common shapes
libfftw3-dev | Discrete fourier transform in ROOT
libfreetype6-dev | fonts for plots with ROOT
libftgl-dev | Rendering fonts in OpenGL
libgif-dev | Saving plots as GIFs
libgl1-mesa-dev | [MesaGL](https://mesa3d.org) allowing 3D rendering using OpenGL
libgl2ps-dev | Convert OpenGL image to PostScript file
libglew-dev | [GLEW](https://glew.sourceforge.net) library for helping use OpenGL
libglu-dev | [OpenGL Utility Library](https://www.opengl.org/resources/libraries/)
libjpeg-dev | Saving plots as JPEGs
liblz4-dev | Data compression in ROOT serialization
liblzma-dev | Data compression in ROOT serialization
libpng-dev | Saving plots as PNGs
libx11-dev | low-level window management (ROOT GUI)
libxext-dev | low-level window management (ROOT GUI)
libxft-dev | low-level window management (ROOT GUI)
libxml2-dev | XML reading and writing
libxmu-dev | low-level window management (ROOT GUI)
libxpm-dev | low-level window management (ROOT GUI)
libz-dev | Data compression in ROOT serialization
libzstd-dev | Data compression in ROOT serialization
srm-ifce-dev | [srm-ifce](https://github.com/cern-fts/srm-ifce) client side access of distributed storage within ROOT
libgsl-dev | GNU Scientific Library for numerical calculations in ROOT MathMore (needed for GENIE)
liblog4cpp5-dev | C++ Logging Library used in GENIE
ca-certificates | Installing certificates to trust within container
clang-format | C++ Code Formatting for ldmx-sw
libboost-all-dev | C++ Utilities for Acts and ldmx-sw
libssl-dev | Securely interact with other computers and encrypt files
clang | C++ Alternative Compiler for ldmx-sw
clang-tidy | C++ Static Analyzer for ldmx-sw
clang-tools | Additional development tools for ldmx-sw
cmake-curses-gui | GUI for inspecting CMake configuration
gdb | GNU DeBugger for ldmx-sw development
libasan8 | Address sanitization for ldmx-sw
lld | alternative linker for ldmx-sw
