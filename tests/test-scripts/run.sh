#!/usr/bin/env bash
set -eE

main() {
  if [ $# -lt 9 ] || [ $# -gt 10 ]; then
    echo "Usage: s3_bucket_testdata s3_bucket_in s3_bucket_out consignment_reference consignment_type batch_ref aws_profile_non_prod aws_profile_management and optionally replace_folder_boolean"
    return 1
  fi

  s3_bucket_testdata="$1"
  s3_bucket_in="$2"
  s3_bucket_out="$3"
  consignment_reference="$4"
  consignment_type="$5"
  pre_signed_timout="$6"
  batch_ref="$7"
  aws_profile_non_prod="$8"
  aws_profile_management="$9"
  replace_folder="${10}"

  export AWS_PROFILE="${aws_profile_non_prod}"
  export S3_DRI_OUT_BUCKET="${s3_bucket_out}"
  export TRE_PRESIGNED_URL_EXPIRY="${pre_signed_timout}"
  export TRE_PROCESS_NAME="dev-local-dpsg-process-name"
  export TRE_ENVIRONMENT="dev-local-dpsg-env-name"
  export TRE_SYSTEM_NAME="dev-local-system-name"

  test_uuid_directory=/test-dpsg-uuid/
  consignments=consignments/
  aws_post_test_path=${consignments}${consignment_type}/${consignment_reference}${test_uuid_directory}
  aws_test_file_path=${consignments}${consignment_type}/${consignment_reference}${test_uuid_directory}${consignment_reference}

  #tmp clean up
  rm -rf /tmp/tre-test/*
  aws s3 rm s3://"${s3_bucket_in}"/"${aws_post_test_path:?}" --recursive --quiet --profile "${aws_profile_non_prod}"
  aws s3 rm s3://"${s3_bucket_out}"/"${aws_post_test_path:?}" --recursive --quiet --profile "${aws_profile_non_prod}"

  printf -v event '{
    "version": "1.0.0",
    "timestamp": 1661340417609575000,
    "UUIDs": [
      {
        "TDR-UUID": "c73e5ca7-cf87-442a-8248-e05f81361ae0"
      },
      {
        "TRE-UUID": "3c1db304-090f-4b19-abfc-8618cc0e5875"
      }
    ],
    "producer": {
      "environment": "dev",
      "name": "TRE",
      "process": "dev-tre-validate-bagit",
      "event-name": "bagit-validated",
      "type": "%s"
    },
    "parameters": {
      "bagit-validated": {
        "reference": "%s",
        "s3-bucket": "%s",
        "s3-bagit-name": "ZZZ",
        "s3-object-root": "%s",
        "validated-files": "4"
      }
    }
  }' \
    "${consignment_type}" \
    "${consignment_reference}" \
    "${s3_bucket_in}" \
    "${aws_test_file_path}"

  printf 'Generated input event:\n%s\nInvoking test...\n' "${event}"

  mkdir -p /tmp/tre-test/input
  aws s3api get-object --bucket "${s3_bucket_testdata}"  --key da-transform-sample-data/"${consignment_reference}".tar.gz "${consignment_reference}".tar.gz --profile "${aws_profile_management}"
  tar -xf "${consignment_reference}".tar.gz -C /tmp/tre-test/input
  aws s3 cp --recursive /tmp/tre-test/input s3://"${s3_bucket_in}"/"${aws_post_test_path}" --quiet --profile "${aws_profile_non_prod}"

  replace_folder_expected_suffix=""
  if [ "$replace_folder" = "True" ]
  then
    replace_folder_expected_suffix="_rf_true"
    export TRE_REPLACE_FOLDER="True"
  fi
  python3 test-bagit-to-dri-sip.py "${event}"
  aws s3api get-object --bucket "${s3_bucket_out}"  --key "${aws_test_file_path}"/sip/"${batch_ref}".tar.gz "${batch_ref}"_actual.tar.gz --profile "${aws_profile_non_prod}"
  aws s3api get-object --bucket "${s3_bucket_out}"  --key "${aws_test_file_path}"/sip/"${batch_ref}".tar.gz.sha256 "${batch_ref}"_actual.tar.gz.sha256 --profile "${aws_profile_non_prod}"

  mkdir -p /tmp/tre-test/actual
  tar -xf "${batch_ref}"_actual.tar.gz -C /tmp/tre-test/actual

  expected_files=${batch_ref}${replace_folder_expected_suffix}_expected.tar.gz
  mkdir -p /tmp/tre-test/expected
  aws s3api get-object --bucket "${s3_bucket_testdata}"  --key da-transform-sample-data/"${expected_files}" "${expected_files}" --profile "${aws_profile_management}"
  tar -xf "${expected_files}" -C /tmp/tre-test/expected

  diff=$(diff -r /tmp/tre-test/actual /tmp/tre-test/expected)
  cleanup
  if [ "$diff" != "" ]
  then
      echo "$diff"
      echo "<===== TEST FAILED - FILES DO NOT MATCH =====>"
      exit 1
  else
      echo "<===== ALL FILES MATCH - TEST PASSED =====>"
      exit 0
  fi
}

function cleanup {
  unset TRE_REPLACE_FOLDER
  unset AWS_PROFILE
  rm -rf /tmp/tre-test/*
  rm "${consignment_reference}".tar.gz
  rm "${batch_ref}"_actual.tar.gz
  rm "${batch_ref}"_actual.tar.gz.sha256
  rm "${expected_files}"
  aws s3 rm s3://"${s3_bucket_in}"/"${aws_post_test_path:?}" --recursive --quiet --profile "${aws_profile_non_prod}"
  aws s3 rm s3://"${s3_bucket_out}"/"${aws_post_test_path:?}" --recursive --quiet --profile "${aws_profile_non_prod}"
}

trap cleanup ERR
main "$@"
