# Using Parallel Containers
Sometimes users wish to compare the behavior of multiple dev images without
changing the source code of ldmx-sw (or a related repository) very much if at all.
This page documents how to use two (or more) images in parallel.

Normally, when users switch images, they need to full re-build after fully cleaning out
all of the generated files (usually with `just clean`).
This method avoids this connection between a full re-build and switching images at the cost of extra complexity.

The best way to document this is by outlining an example; however,
please note that this can easily be expanded to any number of images you wish
(and could be done with software that is not necessarily ldmx-sw).
Let's call the two images we wish to use `alice` and `bob`, 
both of which are already built.

### 1. Clean Up Environment
```
cd ~/ldmx/ldmx-sw # go to ldmx-sw
just clean
```

### 2. Build with Both Images
```
# going to build with alice first
just use ldmx/dev:alice
denv cmake -B alice/build -S . -DCMAKE_INSTALL_PREFIX=alice/install
denv cmake --build alice/build --target install
# now build with bob
just use ldmx/dev:bob
denv cmake -B bob/build -S . -DCMAKE_INSTALL_PREFIX=bob/install
denv cmake --build bob/build --target install
```

### 3. Run with an Image
The container run from an image looks at a specific path for libraries to link and executables to run
that were built by the user within the container. In current images (based on version 3
or newer), this path is `${LDMX_BASE}/ldmx-sw/install`.
```
# I want to run alice so I need its install in the location where
# the container looks when it runs (i.e. ldmx-sw/install)
ln -sf alice/install install
just use ldmx/dev:alice
just fire # runs ldmx-sw compiled with alice
ln -sf bob/install install
just use ldmx/dev:bob
just fire # runs ldmx-sw compiled with bob
```
