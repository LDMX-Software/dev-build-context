# GitHub Workflows for Development Image

The definition of these workflows are located at `.github/workflows` in the repository.

The Continuous Integration (CI) workflow is split into three parts.
1. Build: In separate and parallel jobs, build the image for the different architectures
    we want to support. Push the resulting image (if successfully built) to DockerHub only
    using its sha256 digest.
2. Merge: Create a manifest for the images built earlier that packages the different
    architectures together into one tag. Container managers (like docker and singularity)
    will then deduce from this manifest which image they should pull for the architecture
    they are running on.
3. Test: Check that ldmx-sw can compile and run a basic simulation for various versions of ldmx-sw.

We only test after a successful build so, if the tests fail, users can pull the image and
debug why the tests are failing locally.

## ldmx-sw Test Versions
The CI can only test a finite number of versions of ldmx-sw - in general, we'd like
to make sure the past few minor versions are supported (with the possibility of
[interop patches](interop.md)) by the new image build while also enabling support for the newest ldmx-sw.

The versions that will be tested are in [`ci/ldmx-sw-to-test.json`](https://github.com/LDMX-Software/dev-build-context/blob/main/ci/ldmx-sw-to-test.json)
which is periodically updated by another workflow that checks for new ldmx-sw releases.
This workflow is not perfect, so it is helpful to keep the following in mind when a new ldmx-sw
release is posted and the workflow generates a PR updating the JSON file above.
- Test newest developments of ldmx-sw (`trunk`)
- Test minimum version supported (currently set at `v3.3.0`)
- Test highest patch-number for each minor version in between (`v3.0.2`, `v3.1.13`, `v3.2.12`)
- Test additional releases specifically related to changes to the image
  - For example `v4.2.15` has some patches to ldmx-sw enabling support for the newer GCC in v5 images.

## GitHub Actions Runner
The image builds take a really long time since we are building many large
packages from scratch and sometimes emulating a different architecture than
the one doing the image building. For this reason, we needed to move to
a [self-hosted runner](runner.md) solution.

## Pulling by Digest
You may want to pull an image by its digest because the manifest that creates a more helpful tag
has not been created (e.g. the other architecture's build is still running or the merge step failed).
You can do this by downloading the digest artifact from the workflow run
(at the bottom of the CI Workflow "Summary" page).

The digest is stored as the name of an empty file in this artifact.
We first copy this file name into a shell variable.
```
cd ~/Downloads
mkdir digest
cd digest
unzip ../digest-amd64.zip
export digest=$(ls *)
cd ..
rm -r digest digest-amd64.zip
```

~~~admonish warning title="Architecture Specific"
The builds referenced by digest are architecture specific.
Grouping them together into a manifest allows the runner to choose the image based
on the host computer's architecture.
This means you must choose the digest artifact corresponding to your computer's architecture.
~~~

Next, we need to download the image using the 64-character digest stored in `${digest}`.

### Docker/Podman
Below, I use `docker` but you can also do the same commands with `podman` in place of `docker`.

```
docker pull ldmx/dev@sha256:${digest}
docker tag ldmx/dev@sha256:${digest} ldmx/dev:some-helpful-name
```

### Apptainer
~~~admonish error title="Untested"
I have only ever needed to do this on my laptop with docker or podman installed;
however, I'm pretty sure this will work.
~~~

```
apptainer build ldmx_dev_some-helpful-name.sif docker://ldmx/dev@sha256:${digest}
```
