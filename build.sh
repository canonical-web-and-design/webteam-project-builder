#!/usr/bin/env bash

set -e

# Arguments
project_name=${1}
project_repository=${2:-"git.launchpad.net:"${project_name}}

source ./lib.sh

echo -e "\n= Get ${project_name} code from ${project_repository} =\n"
update-from-remote master ${project_repository} ${project_name}
project_version=$(git --git-dir=${project_name}/.git rev-parse HEAD)
archive_filepath=${project_version}/${project_name}.tar.gz

if swift list ${project_name} | grep -q ${archive_filepath}; then
  echo -e "\n= Archive already exists: ${archive_filepath}. Exiting."
  # exit 1
fi

echo -e "\n= Get pip-cache dependencies for ${project_name} =\n"
create-pip-cache ${project_name}

echo -e "\n= Create ${project_version}/${project_name}.tar.gz =\n"
mkdir -p ${project_version}
tar --exclude-vcs -czf ${archive_filepath} -C ${project_name} .

echo -e "\n= Upload ${project_version}/${project_name}.tar.gz to swift container ${project_name} =\n"
source $HOME/.nova-credentials/stg-${project_name}

swift upload ${project_name} ${archive_filepath}

echo -e "\n= Set latest-build-label in ${project_name} to ${project_version} =\n"
echo -e ${project_version} > latest-build-label
swift upload ${project_name} latest-build-label
