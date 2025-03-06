# Legacy Interop

The patch files here are intended to patch older versions of ldmx-sw
so that they can be built with newer images that have newer dependencies
and compilers.

They are `git apply`ed within ldmx-sw and are applied before the configuration (`cmake`)
step so that they can modify the build configuration files if need be.

For creating a patch file for v3 versions of ldmx-sw, you need to use
```
git diff --submodule=diff
```
so that the patches to files within the ldmx-sw submodules are captured.
For later versions of ldmx-sw, `git diff` works like normal.
In any case, these patch files are just the output of `git diff` redirected
to them.
```
cd path/to/ldmx-sw
git diff > path/to/ci/interop/$(git describe --tags).patch
```

Many versions of ldmx-sw require the same patch and so instead of copying the
same file, I have just symlinked a specific version's patch file to the previous
version so that developers only need to update a patch file for the version
where the (now breaking) change was introduced.
