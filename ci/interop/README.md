# Legacy Interop

The patch files here are intended to patch older versions of ldmx-sw
so that they can be built with newer images that have newer dependencies
and compilers.

They are `git apply`ed within ldmx-sw and are applied before the configuration (`cmake`)
step so that they can modify the build configuration files if need be.

For creating a patch files, there is a small script in this directory
that runs the appropriate `git` commands for you.
```
# inside of the ldmx-sw you have patched
path/to/ci/interop/save-patch
```

Many versions of ldmx-sw require the same patch and so instead of copying the
same file, I have just symlinked a specific version's patch file to the previous
version so that developers only need to update a patch file for the version
where the (now breaking) change was introduced.
