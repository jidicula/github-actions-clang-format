#!/usr/bin/env bash

FALLBACK_STYLE="llvm"
EXCLUDE_REGEX="capital"
CLANG_FORMAT_VERSION="$1"
CLANG_FORMAT_FILEPATH="$GITHUB_WORKSPACE/test/format_files/clang_format_example"

###############################################################################
#                      Default C/C++/Protobuf/CUDA regex                      #
###############################################################################

# should succeed
"$GITHUB_WORKSPACE"/check.sh "$CLANG_FORMAT_VERSION" "$GITHUB_WORKSPACE/test/known_pass" "$FALLBACK_STYLE" "$EXCLUDE_REGEX" "" "$CLANG_FORMAT_FILEPATH"
docker_status="$?"
if [[ $docker_status != "0" ]]; then
	echo "files that should succeed have failed!"
	exit 1
fi

# should fail
"$GITHUB_WORKSPACE"/check.sh "$CLANG_FORMAT_VERSION" "$GITHUB_WORKSPACE/test/known_fail" "$FALLBACK_STYLE" "$EXCLUDE_REGEX" "" "$CLANG_FORMAT_FILEPATH"
docker_status="$?"
if [[ $docker_status == "0" ]]; then
	echo "files that should fail have succeeded!"
	exit 2
fi

# load test on known_pass/addition.c copies

"$GITHUB_WORKSPACE"/check.sh "$CLANG_FORMAT_VERSION" "$GITHUB_WORKSPACE/test/load_test" "$FALLBACK_STYLE" "$EXCLUDE_REGEX" "" "$CLANG_FORMAT_FILEPATH"
docker_status="$?"
if [[ $docker_status != "0" ]]; then
	echo "files that should succeed have failed in the loadtest!"
	exit 3
fi

###############################################################################
#                            Custom filetype regex                            #
###############################################################################

INCLUDE_REGEX='^.*\.(c|C)'

# should succeed
"$GITHUB_WORKSPACE"/check.sh "$CLANG_FORMAT_VERSION" "$GITHUB_WORKSPACE/test/known_pass" "$FALLBACK_STYLE" "$EXCLUDE_REGEX" "$INCLUDE_REGEX" "$CLANG_FORMAT_FILEPATH"
docker_status="$?"
if [[ $docker_status != "0" ]]; then
	echo "files that should succeed have failed!"
	exit 1
fi

# should fail
"$GITHUB_WORKSPACE"/check.sh "$CLANG_FORMAT_VERSION" "$GITHUB_WORKSPACE/test/known_fail" "$FALLBACK_STYLE" "$EXCLUDE_REGEX" "$INCLUDE_REGEX" "$CLANG_FORMAT_FILEPATH"
docker_status="$?"
if [[ $docker_status == "0" ]]; then
	echo "files that should fail have succeeded!"
	exit 2
fi
