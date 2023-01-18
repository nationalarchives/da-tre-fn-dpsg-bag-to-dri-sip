#!/usr/bin/env bash


main() {
  if [ $# -lt 4 ] || [ $# -gt 4 ]; then
    echo "Usage: s3_bucket_testdata s3_bucket_in s3_bucket_out aws_profile"
    return 1
  fi

  s3_bucket_testdata="$1"
  s3_bucket_in="$2"
  s3_bucket_out="$3"
  aws_profile="$4"

  cd units
  python -m unittest discover
  UNITS_RESULT="$?"
  cd ..

  behave
  BEHAVE_RESULT="$?"

  cd test-scripts
# Test v1.1 of data from TRE = package TDR-2022-AA1
  ./run.sh "$s3_bucket_testdata" "$s3_bucket_in" "$s3_bucket_out" TDR-2022-AA1 standard 60 MOCKA101Y22TBAA1 "$aws_profile"
  test_script_one_result="$?"
# Test v1.1 of data from TRE = package TDR-2022-D6WD
  ./run.sh "$s3_bucket_testdata" "$s3_bucket_in" "$s3_bucket_out" TDR-2022-D6WD standard 60 TSTA1Y22TBD6WD "$aws_profile"
  test_script_two_result="$?"
  cd ..

  OVERALL_RESULT="0"
  if [ $UNITS_RESULT = "0" ]; then
      echo UNITS OK
  else
      echo UNITS FAIL
      OVERALL_RESULT="1"
  fi
  if [ $BEHAVE_RESULT = "0" ]; then
      echo BEHAVE OK
  else
      echo BEHAVE FAIL
      OVERALL_RESULT="1"
  fi
  if [ $test_script_one_result = "0" ] && [ $test_script_two_result = "0" ]; then
      echo TEST SCRIPTS OK
  else
      echo TEST SCRIPTS FAIL
      OVERALL_RESULT="1"
  fi
  if [ $OVERALL_RESULT = "0" ]; then
      echo OVERALL OK
      exit 0
  else
      echo OVERALL FAIL
      exit 1
  fi
}

main "$@"