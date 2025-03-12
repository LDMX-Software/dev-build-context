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

