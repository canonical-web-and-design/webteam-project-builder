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
# Examples:
# ./create-archive-and-update-spec.sh assets-manager  # project-repository and swift-container will be inferred
# ./create-archive-and-update-spec.sh assets-manager --make-targets sass  # Optionally run make target
# ./create-archive-and-update-spec.sh assets-manager --project-repository lp:assets-manager --pip-cache-repository lp:~webteam-backend/assets-maanager/pip-cache --swift-container assets-manager --make-targets sass

PARSED_OPTIONS=$(getopt -n "$0"  -o "r:,p:,m:" --long "project-repository:,pip-cache-repository:,make-targets:"  -- "$@")
eval set -- "$PARSED_OPTIONS"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -r|--project-repository)   project_repository=$2;   shift 2;;
        -p|--pip-cache-repository) pip_cache_repository=$2; shift 2;;
        -m|--make-targets)         make_targets=$2;         shift 2;;
        --) shift; break;;
        *) echo "Error: Option parsing failure" ; exit 1;;
    esac
done

# Infer variables from project_name
if [ -z "${project_repository}" ];    then project_repository=lp:${project_name}; fi
if [ -z "${pip_cache_repository}" ];  then pip_cache_repository=lp:~webteam-backend/${project_name}/pip-cache; fi

# Constants
archive_filename=${project_name}.tar.gz

# Make sure builds directory exists
mkdir -p builds
cd builds

# Checkout project
if [ -d ${project_name} ]; then
    bzr pull --directory ${project_name} --overwrite ${project_repository}
else
    bzr branch ${project_repository} ${project_name}
fi

# Create pip-cache
rm -rf ${project_name}/pip-cache
bzr branch ${pip_cache_repository} ${project_name}/pip-cache 

# Run make targets
if [ -n "${make_targets}" ]; then
    make -C ${project_name} ${make_targets}  # Run any necessary make targets
fi

# Create archive
rm -f ${archive_filename}
tar -C ${project_name} --exclude-vcs -czf ${archive_filename} .

# Get revision
latest_revision=$(bzr revno ${project_name})

# Upload to swift container
swift upload ${project_name} ${archive_filename} --object-name=${latest_revision}/${archive_filename}
# Make sure the container is publicly accessible
swift post -r .r:* ${project_name}

# Save the latest build label
echo ${latest_revision} > latest
swift upload ${project_name} latest

# Get the URL
container_url=`swift stat -v ${project_name} | grep -o 'http.*'`
archive_url="${container_url}/${latest_revision}/${archive_filename}"
latest_file_url=${container_url}/latest

# ===
# Latest revision:  ${latest_revision}
# URL for 'latest': ${latest_file_url}
# URL for archive:  ${archive_url}
# ===
