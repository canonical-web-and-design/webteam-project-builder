#!/usr/bin/env bash

function bzr-revision-id {
    repo_dir=$1
    if [ -z "${repo_dir}" ]; then repo_dir=.; fi

    revision_identifier=$(bzr revision-info --directory ${repo_dir} | sed 's/ /-/')

    echo ${revision_identifier}
}
