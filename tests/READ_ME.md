# notes to run features, unit tests and test script locally

## To run features
install behave with:       `pip install behave`
check installation with:   `behave --version`
in `tests` directory:
run with `behave`

## To run unit tests:
in `tests/units` directory
run with `python -m unittest discover`

## To run test scripts on a specific set of sample data
This script runs the full transform on a sample bag from s3 and compares (diffs) the actual SIP produced by the handler
function against an expected SIP from s3.  These input sample bags (and the corresponding expected SIP) are in the test
data repo on management account - they come from repo [da-tre-sample-data](https://github.com/nationalarchives/da-tre-sample-data).

in `tests/test-scripts` directory
run `./run.sh` with params:
    s3_bucket_testdata (where test data is located)
    s3_bucket_in
    s3_bucket_out
    TDR REF
    consignment type
    pre-signed url time out
    batch ref
    aws_profile for non prod account (where sample input/output goes in appropriate dev buckets, cleaned up afterwards)
    aws_profile for management account (where test data is located)

## Run everything option:
in `tests` directory
There is a `./run_tests.sh` script next to this read me.
Run the script - it should run features + unit tests + the test script for each of the current sets of sample data. It
requires params of:
    s3_bucket_testdata
    s3_bucket_in
    s3_bucket_out
    aws_profile for non prod account (where sample input/output goes in appropriate dev buckets, cleaned up afterwards)
    aws_profile for the management account (where test data is)
