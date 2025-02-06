#!/usr/bin/env bash

CLANG_FORMAT_MAJOR_VERSION="$1"
CHECK_PATH="$2"
FALLBACK_STYLE="$3"
EXCLUDE_REGEX="$4"
INCLUDE_REGEX="$5"

echo "in wrapper.sh"

docker run \
	--volume "$(pwd)":"$(pwd)" \
	--workdir "$(pwd)" \
	--interactive \
	ghcr.io/jidicula/clang-format:"$CLANG_FORMAT_MAJOR_VERSION" \
	"/check.sh \
	$CLANG_FORMAT_MAJOR_VERSION \
	$CHECK_PATH \
	$FALLBACK_STYLE \
	$EXCLUDE_REGEX \
	$INCLUDE_REGEX"
