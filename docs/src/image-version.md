# Determining an Image's Version
Often it is helpful to determine an image's version. Sometimes, this is as easy as
looking at the tag provided by `docker image ls` or written into the SIF file name,
but sometimes this information is lost. Since v4 of the container image, we've been
more generous with adding labels to the image and a standard one is included
`org.opencontainers.image.version` which (for our purposes) stores the release that
built the image.

We can `inspect` an image to view its labels.
You can find out which runner is being used by running `denv check`.

### Docker/Podman
For docker and podman, the `inspect` command returns JSON with all of the image manifest details.
The `jq` program just helps us parse this JSON for the specific label we are looking for,
but you could just scroll through the output.
```bash
docker inspect ldmx/dev:latest |\
  jq 'map(.Config.Labels["org.opencontainers.image.version"])[]'
```

### Apptainer
`apptainer inspect` by default returns just the list of labels,
so we can just use `grep` to select the line with the label we care about.
Similar to above, you can also just scroll through the output if you want.
```
apptainer inspect ldmx_dev_latest.sif | grep org.opencontainers.image.version
```

~~~admonish tip title="Finding SIF Path"
`denv` uses the OCI Image Tag to refer to the images rather than a path to the SIF file
which is needed for `apptainer inspect` to function.
Fortunately, you can find the full path to the cached SIF file using an environment
variable `apptainer` defines at runtime.
```
denv printenv APPTAINER_CONTAINER
```
~~~
