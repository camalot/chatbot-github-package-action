#!/usr/bin/env sh
set -e;
PROJECT_NAME="$INPUT_REPONAME";
BUILD_VERSION="$INPUT_VERSION";
FOLDER_NAME="$INPUT_FOLDERNAME";
GITHUB_TOKEN="$INPUT_TOKEN";

/app/build.sh -r "${PROJECT_NAME}" -v "${BUILD_VERSION}" -f "${FOLDER_NAME}" -g ${GITHUB_TOKEN};