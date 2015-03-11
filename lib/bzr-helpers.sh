#!/usr/bin/env bash

function bzr-revision-id {
    file_path=$1
    repo_dir=$2
    if [ -z "${repo_dir}" ]; then repo_dir=.; fi

    revno=$(bzr log ${repo_dir}/${file_path} -l1 --log-format line | egrep -o ^[0-9]+)
    revision_identifier=$(bzr revision-info ${revno} --directory ${repo_dir} | sed 's/ /-/')

    echo ${revision_identifier}
}
