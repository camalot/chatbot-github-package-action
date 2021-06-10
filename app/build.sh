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
__debug "working in ${WORKSPACE}";

[[ -p "${BUILD_VERSION// }" ]] && __error "'-v' (version) attribute is required.";
[[ -p "${FOLDER_NAME// }" ]] && __error "'-f' (folder name) attribute is required.";


[ -d ${WORKSPACE}/temp/ ] && __info "delete ${WORKSPACE}/temp/" && rm -rf ${WORKSPACE}/temp/;
__debug "Make temp directory";
mkdir -p "${WORKSPACE}/temp/";
[ -d ${WORKSPACE}/dist/ ] && __info "delete ${WORKSPACE}/dist/" && rm -rf ${WORKSPACE}/dist/;
__debug "Make dist directory";
mkdir -p "${WORKSPACE}/dist/";

__debug "Copy folder ${WORKSPACE}/script -> ${WORKSPACE}/temp/"
cp -r "${WORKSPACE}/script" "${WORKSPACE}/temp/";

for p in ${WORKSPACE}/temp/script/*.py; do
  __debug "sed Version to ${BUILD_VERSION} in ${p}";
  sed -i "s/Version = \"1.0.0-snapshot\"/Version = \"${BUILD_VERSION}\"/g" "${p}";
done

updater_zip="${WORKSPACE}/temp/script/applicationupdater.zip";
/app/gh-dl-release -o "camalot" -r "chatbotscriptupdater" -t "latest" -n "ApplicationUpdater.Administrator" -f "$updater_zip" -g ${GH_TOKEN};
# curl -sSL $(curl -s "https://api.github.com/repos/camalot/chatbotscriptupdater/releases/latest" \
# 	| jq -r '.assets[] | select(.name|test("ApplicationUpdater.Administrator")) | .browser_download_url') > ${WORKSPACE}/temp/script/applicationupdater.zip;

sleep 2;
__debug "make updater directory";
mkdir -p ${WORKSPACE}/temp/script/libs/updater/
__debug "unzip updater zip file";
unzip -d ${WORKSPACE}/temp/script/libs/updater/ $updater_zip;
sleep 2;
__debug "remove updater zip file"
rm "${updater_zip}";

__debug "Move ${WORKSPACE}/temp/script -> ${WORKSPACE}/temp/${FOLDER_NAME}";
mv "${WORKSPACE}/temp/script" "${WORKSPACE}/temp/${FOLDER_NAME}";

__debug "change to temp directory";
cd "${WORKSPACE}/temp/" || __error "unable to cd to ${WORKSPACE}/temp/";

[[ ! -f ${WORKSPACE}/.zipignore ]] && __warning "create ${WORKSPACE}/.zipignore file" && touch ${WORKSPACE}/.zipignore;
__debug "Zip up working directory";
zip -r "${REPO_NAME}-${BUILD_VERSION}.zip" --exclude=@${WORKSPACE}/.zipignore -- *;
__debug "move ${REPO_NAME}-${BUILD_VERSION}.zip -> ${WORKSPACE}/dist/";
mv "${REPO_NAME}-${BUILD_VERSION}.zip" "${WORKSPACE}/dist/";

cd ${WORKSPACE} || __error "unable to cd to ${WORKSPACE}/temp/";

__info "Setting ouptut releaseZip: ${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip";
# echo "::set-output name=releaseZip::${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip";
__set_output "releaseZip" "${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip"
