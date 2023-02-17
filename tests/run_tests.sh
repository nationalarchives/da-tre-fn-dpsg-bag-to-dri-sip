#!/usr/bin/env bash


main() {
  if [ $# -lt 5 ] || [ $# -gt 5 ]; then
    echo "Usage: s3_bucket_testdata s3_bucket_in s3_bucket_out aws_profile_non_prod aws_profile_management"
    return 1
  fi

  s3_bucket_testdata="$1"
  s3_bucket_in="$2"
  s3_bucket_out="$3"
  aws_profile_non_prod="$4"
  aws_profile_management="$5"

  cd units
  python -m unittest discover
  UNITS_RESULT="$?"
  cd ..

  behave
  BEHAVE_RESULT="$?"

  cd test-scripts
# Test v1.1 of data from TRE = package TDR-2022-AA1
  ./run.sh "$s3_bucket_testdata" "$s3_bucket_in" "$s3_bucket_out" TDR-2022-AA1 standard 60 MOCKA101Y22TBAA1 "$aws_profile_non_prod" "$aws_profile_management"
  test_script_one_result="$?"
# Test v1.2 of data from TRE = package TDR-2022-D6WD
  ./run.sh "$s3_bucket_testdata" "$s3_bucket_in" "$s3_bucket_out" TDR-2022-D6WD standard 60 TSTA1Y22TBD6WD "$aws_profile_non_prod" "$aws_profile_management"
  test_script_two_result="$?"
# Test edge cases under v1.2 with default value (FALSE) of "replace_folder" = package TDR-2022-D6WF
  ./run.sh "$s3_bucket_testdata" "$s3_bucket_in" "$s3_bucket_out" TDR-2022-D6WF standard 60 TSTA1Y22TBD6WF "$aws_profile_non_prod" "$aws_profile_management"
  test_script_three_result="$?"
# Test edge cases under v1.2 with value of TRUE set for "replace_folder" = package TDR-2022-D6WF
  ./run.sh "$s3_bucket_testdata" "$s3_bucket_in" "$s3_bucket_out" TDR-2022-D6WF standard 60 TSTA1Y22TBD6WF "$aws_profile_non_prod" "$aws_profile_management" True
  test_script_four_result="$?"

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
  if [ $test_script_one_result = "0" ] && [ $test_script_two_result = "0" ] &&
     [ $test_script_three_result = "0" ] && [ $test_script_four_result = "0" ]; then
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
