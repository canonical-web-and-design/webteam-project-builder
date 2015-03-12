#!/usr/bin/env bash

set -ex

# Includes
source lib/bzr-helpers.sh

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

cache_dir=working-cache
project_cache_dir=working-cache/${project_name}
dependencies_dir=${project_cache_dir}/pip-cache
code_dir=${project_cache_dir}/code

# Create cache directories
mkdir -p ${project_cache_dir}

# Get pip-cache
if [ -d ${dependencies_dir} ]; then
    bzr pull --directory ${dependencies_dir} --overwrite ${pip_cache_repo}
else
    # Try-catch
    {
        bzr branch ${pip_cache_repo} ${dependencies_dir}  # Create pip-cache
    } || {
        if [ ! ${create} ]; then
            echo "repository ${pip_cache_repo} doesn't exist";
            exit
        else
            # Create blank pip-cache repo
            mkdir ${dependencies_dir}
            bzr init ${dependencies_dir}
        fi
    }
fi

# Get project
if [ -d ${code_dir} ]; then
    bzr pull --directory ${code_dir} --overwrite ${project_repo}
else
    bzr branch ${project_repo} ${code_dir}
fi

existing_requirements_revno=$(cat ${dependencies_dir}/requirements-revno.txt)
latest_requirements_revno=$(bzr-revno ${code_dir}/requirements)

# Make sure this is a new revision
if [[ "${existing_requirements_revno}" == "${latest_requirements_revno}" ]]; then
    echo "New version (${latest_requirements_revno}) is the same as the existing version (${existing_requirements_revno}). Aborting."
    exit 1
fi

# Clear out existing dependencies, to create from scratch again
rm -r ${dependencies_dir}/*

# Rebuild dependencies
pip install --upgrade --exists-action=w --download ${dependencies_dir} -r ${code_dir}/requirements/standard.txt

# Get latest revision number of the project, store it alongside dependencies
echo ${latest_requirements_revno} > ${dependencies_dir}/requirements-revision.txt

# Commit and push all new files
bzr add ${dependencies_dir}/.
bzr commit ${dependencies_dir} --unchanged -m 'Requirements auto-updated by webteam-project-builder'
bzr push --directory ${dependencies_dir} ${pip_cache_repo}
