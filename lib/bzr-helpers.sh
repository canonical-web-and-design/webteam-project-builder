#!/usr/bin/env bash

function bzr-revno {
    file_path=$1

    echo $(bzr log ${file_path} -l1 --log-format line | egrep -o ^[0-9]+)
}

function bzr-revision-id {
    repo_dir=$1
    if [ -z "${repo_dir}" ]; then repo_dir=.; fi

    revision_identifier=$(bzr revision-info --directory ${repo_dir} | sed 's/ /-/')

    echo ${revision_identifier}
}
