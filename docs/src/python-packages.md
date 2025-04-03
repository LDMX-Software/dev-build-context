# Python Packages

Many Python packages are useful for late stage analysis of data,
so many are included within this image to make them readily available
for downstream LDMX collaborators.

## Do you need to use ldmx/dev?
If you are just using Python and supporting libraries (like `uproot`, `awkward`, and `hist`)
for your analysis, then you do not need to use this large and heavy image.
Instead, it is recommended for you to craft your own environment which is lighter (making
it easier to reproduce and move around clusters) and more nimble (allowing you to upgrade
packages if you want to).

```
cd my-analysis
denv init python:3.12 # choose python version
denv pip install scikit-hep # install packages you need
denv pip freeze > requirements.txt # write packages you've used for later reproducibility
git add requirements.txt .denv/config # store the configuration in git with your analysis code
```

Then, using the code in `my-analysis` on any other computer with `denv` installed would
get started by

```
git clone git@github.com:my-username/my-analysis.git
cd my-analysis
denv pip install -r requirements.txt
```
No `denv init` is required since the `.denv/config` is present in the `my-analysis` git repository.

~~~admonish tip title="Necessity of the ldmx/dev Image"
The only time you **need** to use the Python packages within the ldmx/dev image
is if you are using PyROOT (`import ROOT`) or the ldmx-sw ROOT dictionary.
If you use the `scikit-hep` libraries, then you can move to this more nimble
workflow.
~~~

## What's installed?
Many python packages evolve at a faster rate than we build the ldmx/dev image,
so many of the packages installed within the ldmx/dev image will be behind what has
been most recently released.

You can get the full list and specific versions of the Python packages installed
within your ldmx/dev image by running `denv pip freeze`.
The table below is just documentation of the packages we request to be installed
and not the full dependency tree.

- `scikit-hep`
  - Meta-package holding [scikit-hep](https://scikit-hep.org/) libraries
  - Includes (among others) `uproot`, `mplhep`, `hist`, `awkward`, `pandas`, `vector`, and `pylhe`
- `pyhepmc`
  - IO for the HEPMC data format
- `pip`, `wheel`, `setuptools`
  - Helpful for packaging and downstream upgrading
- `Cython`
  - Write C extensions for Python
- `numba`
  - Pre-compile Python functions for performance improvements
- `scikit-learn`, `xgboost`
  - Machine Learning libraries


