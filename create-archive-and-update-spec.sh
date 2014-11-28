#!/usr/bin/env bash

set -ex

# Get arguments
# ===
# Example:
# ./create-archive-and-update-spec.sh \
#     --spec-repo=lp:~webteam-backend/canonical-mojo-specs/mojo-webteam-assets \
#     --project-name=assets-manager \
#     --project-repo=lp:assets-manager \
#     --make-targets=pip-cache
#     --location-file=common/scripts/manager-archive-location.cfg

PARSED_OPTIONS=$(getopt -n "$0"  -o "s:,n:,r:,m:,l:" --long "spec-repo:,project-name:,project-repo:,make-targets:,location-file:"  -- "$@")
eval set -- "$PARSED_OPTIONS"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -s|--spec-repo)     spec_repo=$2;     shift 2;;
        -n|--project-name)  project_name=$2;  shift 2;;
        -r|--project-repo)  project_repo=$2;  shift 2;;
        -m|--make-targets)  make_targets=$2;  shift 2;;
        -l|--location-file) location_file=$2; shift 2;;
        --) shift ; break;;
        *) echo "Internal error!" ; exit 1;;
    esac
done

# Constants
project_dir=build/${project_name}
archive_filename=${project_name}.tar.gz
archive_path=build/${archive_filename}
iso_timestamp=$(date --iso-8601=seconds)

# Make sure build directory exists
mkdir -p build

# Checkout project
if [ -d ${project_dir} ]; then
    bzr pull --directory ${project_dir} --overwrite ${project_repo}
else
    bzr branch ${project_repo} ${project_dir}
fi

# Prepare project
make -C ${project_dir} ${make_targets}  # Run any necessary make targets

# Create archive
rm -f ${archive_path}
tar -C ${project_dir} --exclude-vcs -czf ${archive_path} .

# Upload to swift container
swift upload charm-assets ${archive_path} --object-name=${iso_timestamp}/${archive_filename}
# Make sure the container is publicly accessible
swift post -r .r:* charm-assets
# Get the URL
container_url=`swift stat -v charm-assets | grep -o 'http.*'`

# Checkout spec
if [ -d spec ]; then
    bzr pull --directory spec --overwrite ${spec_repo}
else
    bzr branch ${spec_repo} spec
fi

cd spec

# Update manager-archive-location.sh with the new archive location
echo "CODE_ASSETS_URI=${container_url}" > ${location_file}
echo "BUILD_LABEL=${iso_timestamp}" >> ${location_file}
echo "ARCHIVE_FILENAME=${archive_filename}" >> ${location_file}

bzr add ${location_file}
bzr commit ${location_file} -m "Jenkins: updating manager's archive-location for release"
bzr push ${spec_repo}
