# Legacy Interop
For some past versions of ldmx-sw, we need to modify the code slightly 
in order for it to be able to be built by the newer containers.
For this reason, we have a set of patch files (the `ci/interop` directory).

The patch files here are intended to patch older versions of ldmx-sw
so that they can be built with newer images that have newer dependencies
and compilers.

They are `git apply`ed within ldmx-sw and are applied before the configuration (`cmake`)
step so that they can modify the build configuration files if need be.

For creating a patch files, there is a small script in `ci/interop`
that runs the appropriate `git` commands for you.
```
# inside of the ldmx-sw you have patched
path/to/dev-build-context/ci/interop/save-patch
```

Many versions of ldmx-sw require the same patch and so instead of copying the
same file, I have just symlinked a specific version's patch file to the previous
version so that developers only need to update a patch file for the version
where the (now breaking) change was introduced.
