
I am adding a new package to the container, here are the details.

### What new packages does this PR add to the development image?
- package1
- package2

## Check List
- [ ] I successfully built the container using docker
<!--
cd dev-build-context 
git checkout my-updates
docker build . -t ldmx/local:temp-tag
-->
- [ ] I was able to build ldmx-sw using this new container build
<!--
# outline of build instructions
cd ldmx-sw
just use ldmx/local:temp-tag
just configure
just build
-->
- [ ] I was able to test run a small simulation and reconstruction inside this container
<!--
# outline of test instructions
cd ldmx-sw/build
denv ctest
denv LDMX_NUM_EVENTS=10 LDMX_RUN_NUMBER=1 fire ../.github/validation_samples/inclusive/config.py
-->
- [ ] I was able to successfully use the new packages.
<!-- Explain what you did to test them below. -->
