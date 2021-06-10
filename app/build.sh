#!/usr/bin/env bash
set -e;

base_dir=$(dirname "$0");
source "${base_dir}/shared.sh";

get_opts() {
  while getopts ":p:v:f:" opt; do
    case $opt in
      r) export opt_repo_name="$OPTARG";
      ;;
      v) export opt_version="$OPTARG";
      ;;
      f) export opt_folder_name="$OPTARG";
      ;;
      \?) __error "Invalid option -$OPTARG";
      ;;
    esac;
  done;
  return 0;
};

get_opts "$@";

REPO_NAME="${opt_repo_name:-"${INPUT_REPONAME}"}";
BUILD_VERSION="${opt_version:-"${INPUT_VERSION}"}";
FOLDER_NAME="${opt_folder_name:-"${INPUT_FOLDER}"}";
WORKSPACE="${GITHUB_WORKSPACE:-"${PWD}"}";

[[ -p "${REPO_NAME// }" ]] && __error "'-r' (repo name) attribute is required.";
[[ -p "${BUILD_VERSION// }" ]] && __error "'-v' (version) attribute is required.";
[[ -p "${FOLDER_NAME// }" ]] && __error "'-f' (folder name) attribute is required.";

mkdir -p "${WORKSPACE}/temp/";
mkdir -p "${WORKSPACE}/dist/";
cp -r "${WORKSPACE}/script" "${WORKSPACE}/temp/";

for p in ${WORKSPACE}/temp/script/*.py; do
  sed -i "s/Version = \"1.0.0-snapshot\"/Version = \"${BUILD_VERSION}\"/g" "${p}";
done

updater_zip="${WORKSPACE}/temp/script/applicationupdater.zip";
/app/gh-dl-release -o "camalot" -r "chatbotscriptupdater" -t "latest" -n "ApplicationUpdater.Administrator" -f "$updater_zip" -g ${GITHUB_TOKEN};
# curl -sSL $(curl -s "https://api.github.com/repos/camalot/chatbotscriptupdater/releases/latest" \
# 	| jq -r '.assets[] | select(.name|test("ApplicationUpdater.Administrator")) | .browser_download_url') > ${WORKSPACE}/temp/script/applicationupdater.zip;

sleep 2;
mkdir -p ${WORKSPACE}/temp/script/libs/updater/
unzip -d ${WORKSPACE}/temp/script/libs/updater/ $updater_zip;
sleep 2;
rm "${WORKSPACE}/temp/script/applicationupdater.zip";

mv "${WORKSPACE}/temp/script" "${WORKSPACE}/temp/${FOLDER_NAME}";
pushd . || exit 9;
cd "${WORKSPACE}/temp/" || exit 9;
pwd;

[[ ! -f ${WORKSPACE}/.zipignore ]] && touch ${WORKSPACE}/.zipignore;

zip -r "${REPO_NAME}-${BUILD_VERSION}.zip" --exclude=@${WORKSPACE}/.zipignore -- *;
mv "${REPO_NAME}-${BUILD_VERSION}.zip" "${WORKSPACE}/dist/";
popd || exit 9;

echo "::set-output name=releaseZip::${WORKSPACE}/dist/${REPO_NAME}-${BUILD_VERSION}.zip";
