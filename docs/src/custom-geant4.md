# Using a Custom Geant4

Geant4 is our main simulation engine and it has a large effect on the products of our simulation samples.
As such, it is very common to compare multiple different versions, patches, and tweaks to Geant4 with our simulation.

~~~admonish warning title="Confirm Image Version"
Make sure you have an image that is at least v4.2.0.
You can check your version of the image by [inspecting the image labels](image-version.md).
~~~

### Building Your Geant4
You can build your Geant4 in a similar manner as ldmx-sw. It does take much longer to compile than ldmx-sw since it is larger, so be sure to leave enough time for it.

```admonish warning title="Remember"
You can only run this custom build of Geant4 with whatever image you are building it with, so make sure you are happy with the image version you are using.
```

``` shell
cd path/to/ldmx # directory that contains ldmx-sw
git clone git@github.com:LDMX-Software/geant4.git # or could be mainline Geant4 or an unpacked tar-ball
denv cmake -B geant4/build -S geant4 <cmake-options>
denv cmake --build geant4/build --target install
```
Now building Geant4 from source has a lot of configuration options that can be used to customize how it is built.
Below are a few that are highlighted for how we use containers and their interaction with the Geant4 build.

- `CMAKE_INSTALL_PREFIX`: This should be set to a path accessible from the container so that the programs within the container can read from and write to this directory. If the geant4 build directory is within `LDMX_BASE` (like it is above), then you could do something like `-DCMAKE_INSTALL_PREFIX=../install` when you run `ldmx cmake` within the build directory.
- `GEANT4_INSTALL_DATADIR`: If you are building a version of Geant4 that has the same data files as the Geant4 version built into the container image, then you can tell the Geant4 build to use those data files with this option, saving build time and disk space. This is helpful if (for example) you are just re-building the same version of Geant4 but in Debug mode. You can see where the Geant4 data is within the container with `denv printenv G4DATADIR` and then use this value `-DGEANT4_INSTALL_DATADIR=/usr/local/share/geant4/data`.

The following are the build options used when setting up the container and are likely what you want to get started 
- `-DGEANT4_USE_GDML=ON` Enable reading geometries with the GDML markup language which is used in LDMX-sw for all our geometries 
- `-DGEANT4_INSTALL_EXAMPLES=OFF` Don't install the Geant4 example applications (just to save space and compilation time)
- `-DGEANT4_USE_OPENGL_X11=ON`  enable an X11-based GUI for inspecting geometries
- `-DGEANT4_MULTITHREADED=OFF` If you are building a version of Geant4 that is multithreaded by default, you will want to disable it with. The dynamic loading used in LDMX-sw will often not work with a multithreaded version of Geant4 

#### Concerns when building different versions of Geant4 than 10.2.3

For most use cases you will be building a modified version of the same release of Geant4 that is used in the container (10.2.3). It is also possible to build and use later versions of Geant4 although this should be done with care. In particular 
- Different Geant4 release versions will require that you rebuild LDMX-sw for use with that version, it will not be sufficient to set the `LDMX_CUSTOM_GEANT4` environment variable and pick up the shared libraries therein
- Recent versions of Geant4 group the electromagnetic processes for each particle into a so-called general process for performance reasons. This means that many features in LDMX-sw that rely on the exact names of processes in Geant4 will not work. You can disable this by inserting something like the following in [RunManager::setupPhysics()](https://github.com/LDMX-Software/SimCore/blob/20d9bcb6d2bad2b99255cf32c1b3f099b26752b0/src/SimCore/RunManager.cxx#L60)
```C++ 
// Make sure to include G4EmParameters if needed
auto electromagneticParameters {G4EmParameters::Instance()};
// Disable the use of G4XXXGeneralProcess,
// i.e. G4GammaGeneralProcess and G4ElectronGeneralProcess
electromagneticParameters->SetGeneralProcessActive(false);
```
- Geant4 relies on being able to locate a set of datasets when running. For builds of 10.2.3, the ones that are present in the container will suffice but other versions may need different versions of these datasets. If you run into issues with this, use `ldmx env` and check that the following environment variables are pointing to the right location 
- `GEANT4_DATA_DIR` should point to `$LDMX_CUSTOM_GEANT4/share/Geant4/data`
  - You can define the `LDMX_CUSTOM_GEANT4_DATA_DIR` environment variable in the container environment to manually point it to a custom location
- The following environment variables should either be unset or point to the correct location in `GEANT4_DATA_DIR`
  - `G4NEUTRONHPDATA` 
  - `G4LEDATA`
  - `G4LEVELGAMMADATA`
  - `G4RADIOACTIVEDATA`
  - `G4PARTICLEXSDATA`
  - `G4PIIDATA`
  - `G4REALSURFACEDATA`
  - `G4SAIDXSDATA`
  - `G4ABLADATA`
  - `G4INCLDATA`
  - `G4ENSDFSTATEDATA`
- When using CMake, ensure that the right version of Geant4 is picked up at configuration time (i.e. when you run `denv cmake`)
  - You can always check the version that is used in a build directory by running `denv ccmake .` in the build directory and searching for the Geant4 version variable
  - If the version is incorrect, you will need to re-configure your build directory. If `cmake` isn't picking up the right Geant4 version by default, ensure that the `CMAKE_PREFIX_PATH` is pointing to your version of Geant4
- Make sure that your version of Geant4 was built with multithreading disabled

~~~admonish tip collapsible=true title="Geant4 Data Duplication"
The Geant4 datasets do not evolve as quickly as the source code that uses them.
We have a copy of the data needed for the LDMX standard version within the container (v10.2.3 currently)
and you can inspect the versions of the datasets that have changed between the version in the container
image and the one you want to build to see which datasets you may need to install.

The file `cmake/Modules/Geant4DatasetDefinitions.cmake` in the Geant4 source code has these
versions for us (The name changed from `Geant4Data...` to `G4Data...` in v10.7.0) and we can
use this file to check manually which datasets need to be updated when running a newer version.
Below, I'm comparing Geant4 v10.3.0 and our current standard.
```
diff \
  --new-line-format='+%L' \
  --old-line-format='-%L' \
  --unchanged-line-format=' %L' \
  <(wget -q -O - https://raw.githubusercontent.com/LDMX-Software/geant4/LDMX.10.2.3_v0.5/cmake/Modules/Geant4DatasetDefinitions.cmake) \
  <(wget -q -O - https://raw.githubusercontent.com/Geant4/geant4/v10.3.0/cmake/Modules/Geant4DatasetDefinitions.cmake)
```

<details>
  <summary>Output</summary>

```diff
 # - Define datasets known and used by Geant4
 # We keep this separate from the Geant4InstallData module for conveniance
 # when updating and patching because datasets may change more rapidly.
 # It allows us to decouple the dataset definitions from how they are
 # checked/installed/configured
 #
 
 # - NDL
 geant4_add_dataset(
   NAME      G4NDL
   VERSION   4.5
   FILENAME  G4NDL
   EXTENSION tar.gz
   ENVVAR    G4NEUTRONHPDATA
   MD5SUM    fd29c45fe2de432f1f67232707b654c0
   )
 
 # - Low energy electromagnetics
 geant4_add_dataset(
   NAME      G4EMLOW
-  VERSION   6.48
+  VERSION   6.50
   FILENAME  G4EMLOW
   EXTENSION tar.gz
   ENVVAR    G4LEDATA
-  MD5SUM    844064faa16a063a6a08406dc7895b68
+  MD5SUM    2a0dbeb2dd57158919c149f33675cce5
   )
 
 # - Photon evaporation
 geant4_add_dataset(
   NAME      PhotonEvaporation
-  VERSION   3.2
+  VERSION   4.3
   FILENAME  G4PhotonEvaporation
   EXTENSION tar.gz
   ENVVAR    G4LEVELGAMMADATA
-  MD5SUM    01d5ba17f615d3def01f7c0c6b19bd69
+  MD5SUM    012fcdeaa517efebba5770e6c1cbd882
   )
 
 # - Radioisotopes
 geant4_add_dataset(
   NAME      RadioactiveDecay
-  VERSION   4.3.2
+  VERSION   5.1
   FILENAME  G4RadioactiveDecay
   EXTENSION tar.gz
   ENVVAR    G4RADIOACTIVEDATA
-  MD5SUM    ed171641682cf8c10fc3f0266c8d482e
+  MD5SUM    994853b153c6f805e60e2b83b9ac10e0
   )
 
 # - Neutron XS
 geant4_add_dataset(
   NAME      G4NEUTRONXS
   VERSION   1.4
   FILENAME  G4NEUTRONXS
   EXTENSION tar.gz
   ENVVAR    G4NEUTRONXSDATA
   MD5SUM    665a12771267e3b31a08c622ba1238a7
   )
 
 # - PII
 geant4_add_dataset(
   NAME      G4PII
   VERSION   1.3
   FILENAME  G4PII
   EXTENSION tar.gz
   ENVVAR    G4PIIDATA
   MD5SUM    05f2471dbcdf1a2b17cbff84e8e83b37
   )
 
 # - Optical Surfaces
 geant4_add_dataset(
   NAME      RealSurface
   VERSION   1.0
   FILENAME  RealSurface
   EXTENSION tar.gz
   ENVVAR    G4REALSURFACEDATA
   MD5SUM    0dde95e00fcd3bcd745804f870bb6884
   )
 
 # - SAID
 geant4_add_dataset(
   NAME      G4SAIDDATA
   VERSION   1.1
   FILENAME  G4SAIDDATA
   EXTENSION tar.gz
   ENVVAR    G4SAIDXSDATA
   MD5SUM    d88a31218fdf28455e5c5a3609f7216f
   )
 
 # - ABLA
 geant4_add_dataset(
   NAME      G4ABLA
   VERSION   3.0
   FILENAME  G4ABLA
   EXTENSION tar.gz
   ENVVAR    G4ABLADATA
   MD5SUM    d7049166ef74a592cb97df0ed4b757bd
   )
 
 # - ENSDFSTATE
 geant4_add_dataset(
   NAME      G4ENSDFSTATE
-  VERSION   1.2.3
+  VERSION   2.1
   FILENAME  G4ENSDFSTATE
   EXTENSION tar.gz
   ENVVAR    G4ENSDFSTATEDATA
-  MD5SUM    98fef898ea35df4010920ad7ad88f20b
+  MD5SUM    95d970b97885aeafaa8909f29997b0df
   )
```

</details>

As you can see, while only a subset of the datasets change, some of them _do_ change.
Unless you are planning to compare several different Geant4 versions that all share
mostly the same datasets, it is easier just to have each Geant4 version have its
own downloaded copies of the datasets.
~~~

## Running with your Geant4
The way we use different versions of Geant4 has changed over the years, so it depends on which version of the image you are using.

### >=5.1.0
Since we are using `denv` to interact with the development image, you now have access to a local file that
can customize your development environment within the container image.
This file is `.profile` located within the container's home directory.
To find the location of this file, run
```sh
denv printenv HOME
```
from the location where you want to use the custom Geant4.
The path output by this command is where the `.profile` is that you will edit.

~~~admonish warning title="System `.profile`", collapsible=true
The `.profile` file is a file that exists in many normal Linux (and MacOS) systems.
I am just pointing this out because if you edit your system one (located at `~/.profile`)
instead of the one that is located within the denv workspace, you will not get the changes
to the container environment you want _and_ you could break your system.
~~~

All this stuff should go at the _end_ of the `.profile` so that you are "updating" the default
environment.

First, make sure to unset the image-specific versions of the Geant4 environment variables defining
the location of the data directories.
This list may not be complete depending on the version of Geant4 installed in the image, you can use
`denv printenv` to see the full list of environment variables within the container environment.
```
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
```
If you changed the location of the data directory when building Geant4, make sure to also use that
location here by defining `GEANT4_DATA_DIR` _before_ sourcing the Geant4 environment script.
```
# only needed if changed data location when building geant4
export GEANT4_DATA_DIR=/full/path/to/custom/data/location
```
Then source the custom Geant4's environment script.
```
. /full/path/to/custom/geant4/bin/geant4.sh
# this stuff below is helpful to make sure a data directory is found
# and allows folks to have a debug build of Geant4 without re-downloading the data
# it goes _after_ the script because the script will define GEANT4_DATA_DIR if the
# build is configured with a specific data location
if [ -z "${GEANT4_DATA_DIR+x}" ]; then
  export GEANT4_DATA_DIR="${G4DATADIR}"
fi
```
And finally, update `CMAKE_PREFIX_PATH` so that ldmx-sw will prefer this custom Geant4 instead
of the one installed within the image.
```
export CMAKE_PREFIX_PATH="/full/path/to/custom/geant4/lib/cmake:${CMAKE_PREFIX_PATH}"
```

After these changes, you should be able to compile and run ldmx-sw from this environment using
your custom build of Geant4 with the normal development commands.
```
just compile
just fire config.py
```

You can make sure your Geant4 was found and is being used by going into the build and inspecting
the configuration.
```
cd build && denv ccmake .
```
You should see `Geant4_DIR` set to the path of your custom Geant4 instead of some path in `/usr/local/...`.


### <5.1.0,>=4.2.0
With release 4.2.0 of the ldmx/dev image, the entrypoint script now checks the environment variable `LDMX_CUSTOM_GEANT4` for a path to a local installation of Geant4.
This allows the user to override the Geant4 that is within the image with one that available locally. In this way, you can choose whichever version of Geant4 you want,
with whatever code modifications applied, with whatever build instructions you choose.
Just like with ldmx-sw, you can only run a specific build of Geant4 in the same image that you used to build it.
``` shell
just setenv LDMX_CUSTOM_GEANT4=/path/to/geant4/install
```
If you followed the procedure above, the Geant4 install will be located at `${LDMX_BASE}/geant4/install` and you can use
this in the `setenv` command.
``` shell
just setenv LDMX_CUSTOM_GEANT4=${LDMX_BASE}/geant4/install
```

By default the container will produce a rather verbose warning when using a custom Geant4 build.
This is to avoid reproducibility issues caused by accidental use of the feature.
You can disable it by defining the `LDMX_CUSTOM_GEANT4_CONFIRM_DEV` environment variable in the container environment 

```shell
just setenv LDMX_CUSTOM_GEANT4=${LDMX_BASE}/geant4/install 
denv ... # Some command 
> Warning: You are relying on a non-container version of Geant4. This mode of operation can come with some reproducibility concerns if you aren't careful. # The actual warning is longer than this...
just setenv LDMX_CUSTOM_GEANT4_CONFIRM_DEV=yes # Can be anything other than an empty string 
denv ... # No warning!
```
