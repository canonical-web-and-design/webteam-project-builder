# webteam-project-builder

A script for internal Jenkins deployments at Canonical. There are two scripts:

```
./build.sh {project-name} [{project-repository}]  # Create and upload an archive of the code
./update-pip-cache.sh {project-name}              # Upload the latest version of the pip dependencies
```
