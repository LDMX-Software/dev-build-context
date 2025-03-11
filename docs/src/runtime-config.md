# Runtime Configuration

These images are built with all of the software necessary to build and run ldmx-sw;
however, there are additional steps that need to be taken when a container is launched
from the image in order to make running ldmx-sw easier.

The `ldmx-env-init.sh` script is a shell script that defines some necessary environment
variables for the user. This script is run _after_ a container is initially constructed
and so it can access the directories that are mounted to a container at runtime.

We use [`denv`](https://tomeichlersmith.github.io/denv) to run these images and `denv`
uses a login shell to run the requested commands within the container while
mounting the `denv_workspace` directory to the container's `${HOME}`.
Additionally, `denv` copies any files from `/etc/skel/`
(the "skeleton" area holding default initialization files for new user home directories)
into the container's `HOME` directory if they do not exist yet.
This enables us, as an image creator, to update files within `/etc/skel/`
with our custom initialization.

~~~admonish tip title="For Future Developers"
If you are updating the image and find yourself needing to include environment
variables that need to know runtime information (like the full path to mounted directories),
then these environment variables should be defined in `ldmx-env-init.sh` or `/etc/skel/.profile`
so that users get them "automatically" with `denv`
~~~

We do this by updating the `/etc/skel/.profile` file at the end of the Dockerfile,
defining `LDMX_BASE` to be the `HOME` directory if it isn't defined.

~~~admonish warning title=""
This mapping of `LDMX_BASE` to `HOME` is only necessary to support the legacy usage
of these images with the custom entrypoint script `entry.sh` and the `ldmx` suite
of bash functions defined within `ldmx-sw/scripts/ldmx-env.sh`.
~~~

## Using `denv` with Images Prior to v4.2.2
Images before v4.2.2 did not update `/etc/skel/.profile` and so users need to
manually update the `.profile` in order to functionally use the image with `denv`.

1. Run a dummy command to copy over the initial `.profile`
2. Define `LDMX_BASE` as `HOME` in your `.profile`
3. Copy the `ldmx-env-init.sh` script into your `.profile`

For example
```bash
# 1.
denv true
# 2.
printf "%s\n" \
  "# make sure LDMX_BASE is defined for ldmx-env-init.sh" \
  "if [ -z \"\${LDMX_BASE+x}\" ]; then" \
  "  export LDMX_BASE=\"\${HOME}\"" \
  "fi" \
  >> .profile
# 3.
curl -s https://raw.githubusercontent.com/LDMX-Software/dev-build-context/refs/heads/main/ldmx-env-init.sh \
  >> .profile
```
