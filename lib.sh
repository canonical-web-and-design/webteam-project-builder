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
        git -C ${dir_path} clean -fd
        git -C ${dir_path} remote remove origin || true
        git -C ${dir_path} remote add origin ${git_url}
        git -C ${dir_path} fetch origin ${branch}
        git -C ${dir_path} reset --hard FETCH_HEAD
    )
}
