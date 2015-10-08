#!/usr/bin/env bash

set -e

# Arguments
project_name=${1}
project_repository=${2:-"git.launchpad.net:"${project_name}}

source ./lib.sh

echo -e "\n= Get ${project_name} code from ${project_repository} =\n"
update-from-remote master ${project_repository} ${project_name}
project_version=$(git --git-dir=${project_name}/.git rev-parse HEAD)

echo -e "\n= Get pip-cache dependencies for ${project_name}-${project_version} =\n"
tag_name=${project_name}-${project_version}

update-from-remote ${tag_name} git.launchpad.net:webteam-dependencies ${project_name}/pip-cache || true

if [[ ! -d ${project_name}/pip-cache ]]; then
    echo -e "\n= Missing correct version of pip-cache. Please create it first. ="
    echo -e "= Update pip-cache here: http://jenkins.demo.haus/job/update-pip-cache/parambuild/?project_name=${project_name} =\n"
    exit 1
fi

echo -e "\n= Create ${project_version}/${project_name}.tar.gz =\n"
mkdir -p ${project_version}
tar --exclude-vcs -czf ${project_version}/${project_name}.tar.gz -C ${project_name} .

echo -e "\n= Upload ${project_version}/${project_name}.tar.gz to swift container ${project_name} =\n"
source $HOME/.nova-credentials/stg-${project_name}
swift upload ${project_name} ${project_version}/${project_name}.tar.gz

echo -e "\n= Set latest in ${project_name} to ${project_version} =\n"
echo -e ${project_version} > latest
swift upload ${project_name} latest
