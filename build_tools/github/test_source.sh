#!/bin/bash

set -e
set -x

cd ../../

python -m venv test_env
source test_env/bin/activate

python -m pip install scikit-learn/scikit-learn/dist/*.tar.gz
python -m pip install pytest pandas

# Run the tests on the installed source distribution
mkdir tmp_for_test
cd tmp_for_test

# Fork note: the two pickle-version-warning tests interpolate sklearn.__version__
# into a pytest `match=` regex; the "+" in "1.8.0+gilfix" breaks that regex.
pytest --pyargs sklearn -k "not test_pickle_version_warning_is_issued_upon_different_version and not test_pickle_version_warning_is_issued_when_no_version_info_in_pickle"
