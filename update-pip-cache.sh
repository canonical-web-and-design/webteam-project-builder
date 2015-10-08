#!/usr/bin/env bash

set -e

# Arguments
project_name=${1}
project_repository=${2:-"git@github.com:ubuntudesign/"${project_name}}

source ./lib.sh

echo -e "\n= Get ${project_name} code from ${project_repository} =\n"
update-from-remote master ${project_repository} ${project_name}

echo -e "\n= Get latest pip-cache dependencies for ${project_name} =\n"
update-from-remote ${project_name} git.launchpad.net:webteam-dependencies ${project_name}/pip-cache/

project_revision=$(git --git-dir=${project_name}/.git rev-parse HEAD)
tag_name=${project_name}-${project_revision}

# Check if the tag already exists, if not create it
if ! git --git-dir ${project_name}/pip-cache/.git rev-parse ${tag_name} > /dev/null 2>&1; then
    echo -e "\n= Tag ${tag_name} doesn't exist yet. =\n"

    echo -e "\n= Remove existing dependencies =\n"
    rm ${project_name}/pip-cache/*

    echo -e "\n= Download new dependencies =\n"
    pip install \
        --exists-action=w \
        --download ${project_name}/pip-cache \
        --requirement ${project_name}/requirements/standard.txt

    echo -e "\n= Create tag ${tag_name} =\n"
    git --git-dir ${project_name}/pip-cache/.git --work-tree ${project_name}/pip-cache add -A .
    git --git-dir ${project_name}/pip-cache/.git commit -m "Dependencies for ubuntu-china version ${project_revision}"
    git --git-dir ${project_name}/pip-cache/.git tag ${tag_name}

    echo -e "\n= Upload tag ${tag_name} =\n"
    git --git-dir ${project_name}/pip-cache/.git push origin ${project_name} --tags
else
    echo -e "\n= Tag already exists: ${tag_name}. Exiting. =\n"
    exit 1
fi
