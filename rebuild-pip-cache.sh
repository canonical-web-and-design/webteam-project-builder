#!/usr/bin/env bash

set -ex

# Get project name
if [ -z "${project_name}" ]; then
    if [ -n "${1}" ]; then
        project_name=${1}
    else
        echo "Usage: ./rebuild-pip-cache.sh {project_name}";
        exit;
    fi
fi

# Get arguments
# ===
# Example:
# ./rebuild-pip-cache.sh assets-mapper  # project-repo and pip-cache-repo will be inferred
# ./rebuild-pip-cache.sh assets-mapper -r lp:assets-manager -c lp:~webteam-backend/assets-manager/pip-cache
# ./rebuild-pip-cache.sh assets-manager --project-repo=lp:assets-manager --pip-cache-repo=lp:~webteam-backend/assets-manager/pip-cache

PARSED_OPTIONS=$(getopt -n "$0"  -o "r:,p:,:c" --long "project-repo:,pip-cache-repo:,create"  -- "$@")
eval set -- "$PARSED_OPTIONS"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -r|--project-repo)   project_repo=$2;   shift 2;;
        -p|--pip-cache-repo) pip_cache_repo=$2; shift 2;;
        -c|--create) create=true; shift;;
        --) shift; break;;
        *) echo "Error: Option parsing failure"; exit 1;;
    esac
done

# Infer variables from project_name
if [ -z "${project_repo}" ];   then project_repo=lp:${project_name}; fi
if [ -z "${pip_cache_repo}" ]; then pip_cache_repo=lp:~webteam-backend/${project_name}/pip-cache; fi

# Create project directory in pip-caches
mkdir -p pip-caches/${project_name}
cd pip-caches/${project_name}

# Get pip-cache
if [ -d pip-cache ]; then
    bzr pull --directory pip-cache --overwrite ${pip_cache_repo}
else
    # Try-catch
    {
        bzr branch ${pip_cache_repo} pip-cache  # Create pip-cache
    } || {
        if [ ! ${create} ]; then
            echo "repository ${pip_cache_repo} doesn't exist";
            exit
        else
            # Create blank pip-cache repo
            mkdir pip-cache
            bzr init pip-cache
        fi
    }
fi

# Get project
if [ -d code ]; then
    bzr pull --directory code --overwrite ${project_repo}
else
    bzr branch ${project_repo} code
fi

# Build pip-cache
pip install --exists-action=w --download pip-cache/ -r code/requirements/standard.txt
bzr add pip-cache/.
bzr commit pip-cache/ --unchanged -m 'Requirements auto-updated by webteam-project-builder'
bzr push --directory pip-cache ${pip_cache_repo}
