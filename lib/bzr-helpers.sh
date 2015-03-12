#!/usr/bin/env bash

function bzr-revno {
    file_path=$1

    echo $(bzr log ${file_path} -l1 --log-format line | egrep -o ^[0-9]+)
}
