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
