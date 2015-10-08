#!/usr/bin/env bash

# (From: https://gist.github.com/nottrobin/def07af07fbe1f68317c)
# Update a git dir, either by cloning it or pulling changes down
# Usage:
# update-from-remote ${branch} ${git_url} ${dir_path}
function update-from-remote {
    branch=$1
    git_url=$2
    dir_path=$3

    git clone --depth 1 -b ${branch} ${git_url} ${dir_path} || (
        git --git-dir ${dir_path}/.git --work-tree ${dir_path} clean -fd
        git --git-dir ${dir_path}/.git remote remove origin || true
        git --git-dir ${dir_path}/.git remote add origin ${git_url}
        git --git-dir ${dir_path}/.git fetch origin ${branch}
        git --git-dir ${dir_path}/.git --work-tree ${dir_path} reset --hard FETCH_HEAD
    )
}

function create-pip-cache {
    project_dir=$1

    mkdir -p ${project_dir}/pip-cache

    pip install ${PIP_PROXY:+--proxy ${PIP_PROXY}} \
        --exists-action=w \
        --download ${project_dir}/pip-cache \
        --requirement ${project_dir}/requirements/standard.txt
}
