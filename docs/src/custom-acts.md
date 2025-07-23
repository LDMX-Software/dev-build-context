# Custom Acts

For similar reasons as [Geant4](custom-geant4.md), some developers may want to try building
ldmx-sw with a different version of Acts than what resides within the current image.
Luckily, using a custom Acts is a bit simpler than Geant4 since there aren't as many
pieces of data to consider (for example, Acts does not inspect environment variables for
runtime configuration to my knowledge).

## Building Your Acts

```admonish warning title="Remember"
You can only run this custom build of Acts with whatever image you are building it with,
so make sure you are happy with the image version you are using.
```

```shell
cd path/to/ldmx # directory that contains ldmx-sw
git clone git@github.com:acts-project/acts.git
# checkout specific version or branch
denv cmake -B acts/build -S acts \
  -DCMAKE_INSTALL_PREFIX=acts/install \
  -DCMAKE_CXX_STANDARD=20
denv cmake --build acts/build --target install
```

The `cmake` options written above can be experimented with.
We use the C++20 standard in ldmx-sw currently, so it is helpful to use the same standard in Acts.
The `CMAKE_INSTALL_PREFIX` is the path where Acts will be installed and that path will need to
be inside a directory that is mounted to the container at runtime and provided to ldmx-sw when
configuring the build.

## Running with Your Acts
Since there aren't other environment variables needed for Acts to function at runtime,
we just need to build ldmx-sw with specific `cmake` options pointing it to our new location of Acts.
```
just configure -DActs_DIR=/path/to/ldmx/acts/install
just build
```
Some other CMake options may be required depending on your version of ACTS and the version of the dev
image you are using. Below are some options that we've come across while testing. They can be set on the
the command line when running `just configure` with `-D<name>=<value>` like `Acts_DIR` above.
- `CMAKE_FIND_DEBUG_MODE`: may need to be turned `OFF`
- `nlohmann_json_DIR`: may need to be directed to the specific version that was installed with ACTS
  - e.g. `-Dnlohmann_json_DIR=/path/to/ldmx/acts/install/lib/cmake/nlohmann_json/`
