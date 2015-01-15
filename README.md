# webteam-project-builder

A script for internal Jenkins deployments at Canonical. Essentially it :

Runs the `spec-repo` mojo spec with with `project-repo` python project, kicking off the `make-targets` maketarget.
Then tarballs everything and uploads to swift, and appends the bucket location to `location-file`

