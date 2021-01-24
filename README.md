# phpCollab Docker Image

This repository host the source to product a Docker Image for [phpCollab](https://www.phpcollab.com/).

## Build notes

### Automated builds

Currently, Docker Hub builds images when a push is made to the GitHub repository.

In the future, the project will be applying to be an official docker image. If approved, Docker will manage the build process, which uses bashbrew. If the official image status is not approved, then GitHub Actions will be used instead of the standard Docker Hub automated build process to simulate the official image build process, which allows us to easily tag multiple image and platform variants very easily.

### Local build using bashbrew

Prereqs:

1. Download `bashbrew` (Referenced in https://github.com/docker-library/bashbrew#readme):
   - Linux (amd64): `curl -o bashbrew https://doi-janky.infosiftr.net/job/bashbrew/job/master/lastSuccessfulBuild/artifact/bashbrew-amd64`
   - Mac: `curl -o bashbrew https://doi-janky.infosiftr.net/job/bashbrew/job/master/lastSuccessfulBuild/artifact/bashbrew-darwin-amd64`
2. Mark the file as executable: `chmod +x bashbrew`

Run the process to build, tag and push:

```sh
./bashbrew build ./phpcollab
./bashbrew tag ./phpcollab --target-namespace phpcollab
./bashbrew push ./phpcollab --target-namespace phpcollab
./bashbrew put-shared ./phpcollab --target-namespace phpcollab
```

```
docker run -it --rm -v $(pwd):/tmp/test ubuntu:latest
apt-get update
apt-get install curl git jq

cd /tmp/test
export PATH=".:$PATH"
export GITHUB_REPOSITORY=phpcollab
./generate.sh
```

Clone from WordPress

- update.sh -> calls versions.sh to automatically created version.json and calls apply-template.sh (not currently used)
- apply-template.sh -> creates folder and file layout
- generate.sh -> calls `generate-stackbrew-library.sh` and builds images (custom from brewstack)

1. Make changes to templates
1. `./apply-template.sh`
1. commit changes
1. Build:
   1. `export GITHUB_REPOSITORY=phpcollab`
   1. `./generate-stackbrew-library.sh`
      > Gets run by `generate.sh`, but useful to run standalone when troubleshooting.
   1. `./generate.sh`
