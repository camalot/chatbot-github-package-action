#!/usr/bin/env bash
set -e;

base_dir=$(dirname "$0");
source "${base_dir}/shared.sh";

get_opts() {
  while getopts ":v:f:g:" opt; do
    case $opt in
      v) export opt_version="$OPTARG";
      ;;
      f) export opt_folder_name="$OPTARG";
      ;;
      g) export opt_github_token="$OPTARG";
      ;;
      \?) __error "Invalid option -$OPTARG";
      ;;
    esac;
  done;
  return 0;
};

get_opts "$@";

REPO_NAME="${GITHUB_REPOSITORY}";
REPO_OWNER="${GITHUB_REPOSITORY_OWNER}";
BUILD_VERSION="${opt_version:-"${INPUT_VERSION}"}";
FOLDER_NAME="${opt_folder_name:-"${INPUT_FOLDER}"}";
WORKSPACE="${GITHUB_WORKSPACE:-"${PWD}"}";
GH_TOKEN="${GITHUB_TOKEN:-"${opt_github_token}"}";
__info "working in ${WORKSPACE}";

[[ -p "${BUILD_VERSION// }" ]] && __error "'-v' (version) attribute is required.";
[[ -p "${FOLDER_NAME// }" ]] && __error "'-f' (folder name) attribute is required.";

__info "Make temp directory";
mkdir -p "${WORKSPACE}/temp/";
__info "Make dist directory";
mkdir -p "${WORKSPACE}/dist/";

__info "Copy folder ${WORKSPACE}/script -> ${WORKSPACE}/temp/"
cp -r "${WORKSPACE}/script" "${WORKSPACE}/temp/";

for p in ${WORKSPACE}/temp/script/*.py; do
  __info "sed Version to ${BUILD_VERSION} in ${p}";
  sed -i "s/Version = \"1.0.0-snapshot\"/Version = \"${BUILD_VERSION}\"/g" "${p}";
done

updater_zip="${WORKSPACE}/temp/script/applicationupdater.zip";
/app/gh-dl-release -o "camalot" -r "chatbotscriptupdater" -t "latest" -n "ApplicationUpdater.Administrator" -f "$updater_zip" -g ${GH_TOKEN};
# curl -sSL $(curl -s "https://api.github.com/repos/camalot/chatbotscriptupdater/releases/latest" \
# 	| jq -r '.assets[] | select(.name|test("ApplicationUpdater.Administrator")) | .browser_download_url') > ${WORKSPACE}/temp/script/applicationupdater.zip;

sleep 2;
__info "make updater directory";
mkdir -p ${WORKSPACE}/temp/script/libs/updater/
__info "unzip updater zip file";
unzip -d ${WORKSPACE}/temp/script/libs/updater/ $updater_zip;
sleep 2;
__info "remove updater zip file"
rm "${updater_zip}";

__info "Move ${WORKSPACE}/temp/script -> ${WORKSPACE}/temp/${FOLDER_NAME}";
mv "${WORKSPACE}/temp/script" "${WORKSPACE}/temp/${FOLDER_NAME}";
pushd . || __error "unable to pushd to '.'" && exit 9;
__info "change to temp directory";
cd "${WORKSPACE}/temp/" || __error "unable to cd to ${WORKSPACE}/temp/" && exit 9;

ls -lFA;
pwd;

[[ ! -f ${WORKSPACE}/.zipignore ]] && __warning "create ${WORKSPACE}/.zipignore file" && touch ${WORKSPACE}/.zipignore;
__info "Zip up working directory";
zip -r "${REPO_NAME}-${BUILD_VERSION}.zip" --exclude=@${WORKSPACE}/.zipignore -- *;
__info "move ${REPO_NAME}-${BUILD_VERSION}.zip -> ${WORKSPACE}/dist/";
mv "${REPO_NAME}-${BUILD_VERSION}.zip" "${WORKSPACE}/dist/";

popd || __error "unable to popd" && exit 9;

__info "Setting ouptut releaseZip: ${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip";
# echo "::set-output name=releaseZip::${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip";
__set_output "releaseZip" "${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip"
