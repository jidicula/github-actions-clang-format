#!/usr/bin/env bash

###############################################################################
#                                check.sh                                     #
###############################################################################
# USAGE: ./entrypoint.sh [<path>] [<fallback style>]
#
# Checks all C/C++/Protobuf/CUDA files (.h, .H, .hpp, .hh, .h++, .hxx and .c,
# .C, .cpp, .cc, .c++, .cxx, .proto, .cu) in the provided GitHub repository path
# (arg1) for conforming to clang-format. If no path is provided or provided path
# is not a directory, all C/C++/Protobuf/CUDA files are checked. If any files
# are incorrectly formatted, the script lists them and exits with 1.
#
# Define your own formatting rules in a .clang-format file at your repository
# root. Otherwise, the provided style guide (arg2) is used as a fallback.

# format_diff function
# Accepts a filepath argument. The filepath passed to this function must point
# to a C/C++/Protobuf/CUDA file.
format_diff() {
	local filepath="$1"
	# Invoke clang-format with dry run and formatting error output
	if [[ $CLANG_FORMAT_MAJOR_VERSION -gt "9" ]]; then
		local_format="$(docker run \
			--volume "$(pwd)":"$(pwd)" \
			--workdir "$(pwd)" \
			ghcr.io/jidicula/clang-format:"$CLANG_FORMAT_MAJOR_VERSION" \
			--dry-run \
			--Werror \
			--style=file"$FORMAT_FILEPATH" \
			--fallback-style="$FALLBACK_STYLE" \
			"${filepath}")"
	else # Versions below 9 don't have dry run
		formatted="$(docker run \
			--volume "$(pwd)":"$(pwd)" \
			--workdir "$(pwd)" \
			ghcr.io/jidicula/clang-format:"$CLANG_FORMAT_MAJOR_VERSION" \
			--style=file"$FORMAT_FILEPATH" \
			--fallback-style="$FALLBACK_STYLE" \
			"${filepath}")"
		local_format="$(diff -q <(cat "${filepath}") <(echo "${formatted}"))"
	fi

	local format_status="$?"
	if [[ ${format_status} -ne 0 ]]; then
		# Append Markdown-bulleted monospaced filepath of failing file to
		# summary file.
		echo "* \`$filepath\`" >>failing-files.txt

		echo "Failed on file: $filepath" >&2
		echo "$local_format" >&2
		exit_code=1 # flip the global exit code
		return "${format_status}"
	fi
	return 0
}

CLANG_FORMAT_MAJOR_VERSION="$1"
CHECK_PATH="$2"
FALLBACK_STYLE="$3"
EXCLUDE_REGEX="$4"
INCLUDE_REGEX="$5"
FORMAT_FILEPATH="$6"

# Set the regex to an empty string regex if nothing was provided
if [[ -z $EXCLUDE_REGEX ]]; then
	EXCLUDE_REGEX="^$"
fi

# Set the filetype regex if nothing was provided.
# Find all C/C++/Protobuf/CUDA files:
#   h, H, hpp, hh, h++, hxx
#   c, C, cpp, cc, c++, cxx
#   ino, pde
#   proto
#   cu
if [[ -z $INCLUDE_REGEX ]]; then
	INCLUDE_REGEX='^.*\.((((c|C)(c|pp|xx|\+\+)?$)|((h|H)h?(pp|xx|\+\+)?$))|(ino|pde|proto|cu))$'
fi

cd "$GITHUB_WORKSPACE" || exit 2

if [[ ! -d $CHECK_PATH ]]; then
	echo "Not a directory in the workspace, fallback to all files." >&2
	CHECK_PATH="."
fi

if [[ -n $FORMAT_FILEPATH ]] && [[ ! -f $FORMAT_FILEPATH ]]; then
	echo "Not a file in the workspace, fallback to search for .clang_format." >&2
	FORMAT_FILEPATH=""
elif [[ -n $FORMAT_FILEPATH ]]; then
	# if being used, add the colon for seperating the syntax file:<file_name>
	FORMAT_FILEPATH=":$FORMAT_FILEPATH"
fi

# initialize exit code
exit_code=0

# output clang-format version
docker run \
	--volume "$(pwd)":"$(pwd)" \
	--workdir "$(pwd)" \
	ghcr.io/jidicula/clang-format:"$CLANG_FORMAT_MAJOR_VERSION" --version

# All files improperly formatted will be printed to the output.
src_files=$(find "$CHECK_PATH" -name .git -prune -o -regextype posix-egrep -regex "$INCLUDE_REGEX" -print)

# check formatting in each source file
IFS=$'\n' # Loop below should separate on new lines, not spaces.
for file in $src_files; do
	# Only check formatting if the path doesn't match the regex
	if ! [[ ${file} =~ $EXCLUDE_REGEX ]]; then
		format_diff "${file}"
	fi
done

# global exit code is flipped to nonzero if any invocation of `format_diff` has
# a formatting difference.
exit "$exit_code"
