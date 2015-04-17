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
# Examples:
# ./create-archive-and-update-spec.sh assets-manager  # project-repository and swift-container will be inferred
# ./create-archive-and-update-spec.sh assets-manager --make-targets sass  # Optionally run make target
# ./create-archive-and-update-spec.sh assets-manager --project-repository lp:assets-manager --pip-cache-repository lp:~webteam-backend/assets-maanager/pip-cache --swift-container assets-manager --make-targets sass

PARSED_OPTIONS=$(getopt -n "$0"  -o "r:,p:,f:,m:" --long "project-repository:,pip-cache-repository:,requirements-file:,make-targets:"  -- "$@")
eval set -- "$PARSED_OPTIONS"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -r|--project-repository)   project_repository=$2;   shift 2;;
        -p|--pip-cache-repository) pip_cache_repository=$2; shift 2;;
        -f|--requirements-file)    requirements_file=$2; shift 2;;
        -m|--make-targets)         make_targets=$2;         shift 2;;
        --) shift; break;;
        *) echo "Error: Option parsing failure" ; exit 1;;
    esac
done

# Infer variables from project_name
if [ -z "${project_repository}" ];    then project_repository=lp:${project_name}; fi
if [ -z "${pip_cache_repository}" ];  then pip_cache_repository=lp:~webteam-backend/${project_name}/pip-cache; fi
if [ -z "${requirements_file}" ];     then requirements_file=requirements/standard.txt; fi

# Properties
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

# Get pip-cache
if [ -d ${project_name}/pip-cache ]; then
    bzr pull --directory ${project_name}/pip-cache --overwrite ${pip_cache_repository}
else
    bzr branch ${pip_cache_repository} ${project_name}/pip-cache 
fi

# Get revision ids
dependencies_requirements_revno=$(cat ${project_name}/pip-cache/requirements-revno.txt)

requirements_context=${project_name}/${requirements_file}
requirements_dir=$(dirname ${requirements_context})
if [ "${requirements_dir}" != "${project_name}" ]; then
    requirements_context=${requirements_dir}
fi
latest_requirements_revno=$(bzr-revno ${requirements_context})
latest_revision=$(bzr-revision-id ${project_name})

# Make sure revision info matches
if [ "${dependencies_requirements_revno}" != "${latest_requirements_revno}" ]; then
    echo "Depenencies version (${dependencies_requirements_revno}) doesn't match project version (${latest_requirements_revno})."
    echo "Please run 'rebuild-dependencies' for ${project_name} (E.g., here: http://jenkins.ubuntu.qa/job/rebuild-dependencies)"
    echo "Exiting."
    exit 1
fi

# Run make targets
if [ -n "${make_targets}" ]; then
    # Setup virtual environment
    virtualenv ${project_name}-env
    source ${project_name}-env/bin/activate
    pip install --upgrade -r ${project_name}/${requirements_file} --no-index --find-links=${project_name}/pip-cache
    # Run any necessary make targets
    make -C ${project_name} ${make_targets} 
    # Leave virtual environment
    deactivate
fi

# Create archive
rm -f ${archive_filename}
tar -C ${project_name} --exclude-vcs -czf ${archive_filename} .


# Upload to swift container
swift upload ${project_name} ${archive_filename} --object-name=${latest_revision}/${archive_filename}
# Make sure the container is publicly accessible
swift post -r .r:* ${project_name}

# Save the latest build label
echo ${latest_revision} > latest
swift upload ${project_name} latest

# Get the URL
container_url=`swift stat -v ${project_name} | grep -o 'http.*'`
# Replace kelpie with external interface
container_url=$(echo ${container_url} | sed "s/http:\/\/kelpie.internal:8080/https:\/\/objectstorage.prodstack.canonical.com/")
archive_url="${container_url}/${latest_revision}/${archive_filename}"
latest_file_url=${container_url}/latest

# ===
# Latest revision:  ${latest_revision}
# URL for 'latest': ${latest_file_url}
# URL for archive:  ${archive_url}
# ===
