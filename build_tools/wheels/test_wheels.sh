#!/bin/bash

set -e
set -x

PROJECT_DIR="$1"

python $PROJECT_DIR/build_tools/wheels/check_license.py

python -c "import joblib; print(f'Number of cores (physical): \
{joblib.cpu_count()} ({joblib.cpu_count(only_physical_cores=True)})')"

FREE_THREADED_BUILD="$(python -c"import sysconfig; print(bool(sysconfig.get_config_var('Py_GIL_DISABLED')))")"
if [[ $FREE_THREADED_BUILD == "True" ]]; then
    # TODO: delete when importing numpy no longer enables the GIL
    # setting to zero ensures the GIL is disabled while running the
    # tests under free-threaded python
    export PYTHON_GIL=0
fi

# Test that there are no links to system libraries in the
# threadpoolctl output section of the show_versions output:
python -c "import sklearn; sklearn.show_versions()"

# Fork note: the two pickle-version-warning tests interpolate sklearn.__version__
# into a pytest `match=` regex; the "+" in "1.8.0+gilfix" breaks that regex, so
# they are excluded from wheel testing on all platforms.
SKIP_VERSION_WARNING_TESTS="not test_pickle_version_warning_is_issued_upon_different_version and not test_pickle_version_warning_is_issued_when_no_version_info_in_pickle"

if pip show -qq pytest-xdist; then
    XDIST_WORKERS=$(python -c "import joblib; print(joblib.cpu_count(only_physical_cores=True))")
    pytest --pyargs sklearn -n $XDIST_WORKERS -k "$SKIP_VERSION_WARNING_TESTS"
else
    pytest --pyargs sklearn -k "$SKIP_VERSION_WARNING_TESTS"
fi
