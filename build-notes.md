# phpCollab Docker Image Build Notes

## Automated builds

Currently, GitHub Actions builds and deploys images in a methodology similar to how official Docker images are produced, specifically the WordPress image(s). One major difference is that
`docker buildx` is used to produce the image sets.

## The Build Methodology (cloned from WordPress)

phpCollab's build methodology is essentially a clone of the [WordPress official Docker image](https://github.com/docker-library/wordpress).
It's flow is basically:

1. `update.sh` -> (not currently used) calls `versions.sh` and `apply-template.sh`.
1. `versions.sh` -> (not currently used) automatically creates/updates the `versions.json` file, which is the parameter file for the rest of the process.
   > `versions.json` is manually maintained for phpCollab.
1. `apply-template.sh` -> creates folder and file layouts and processes the `Docker.template` file for each image set.
1. `generate.sh` -> calls `generate-stackbrew-library.sh`, which produces the `bashbrew` input file. `generate.sh` then and produces the command strategic/matrix used by GitHub Actions to build the desired permutation of images.

With the exceptions of the `versions.json` file being manually maintained, the rest of the flow is automated via GitHub actions.

## Cutting New Releases

After a new release of phpCollab has been created and released, the Docker image repo needs to be touched.

> Part of the release process generally requires a Linux (Ubuntu) environment. See the _Local Builds -> "One-time" Setup_ section for details.

1. Make any desired changes to the general source files: `Dockerfile.template`, `docker-entrypoint*.sh`, etc.
1. Update the `versions.json` with at a minimum of the new phpCollab version and download hash.
   > See the _versions.json_ section for details.
1. Run the following to propagate the changes to the raw image source:
   ```sh
   ./apply-template.sh
   ```
1. Commit and push the changes to the GitHub repo.
1. Check the build results on GitHub Actions and Docker Hub.

## Local Builds

The build process generally requires a Linux (Ubuntu) environment. It's easy to create one with Docker.

### "One-time" Setup

1. Start a Docker container `docker run -it --rm -v $(pwd):/tmp/code ubuntu:latest`
   > Note with `--rm` the container will be cleaned up upon exiting.
1. In the container, run:

   ```sh
   apt-get update
   apt-get install -y curl gawk git jq wget

   cd /tmp/code
   curl -o bashbrew https://doi-janky.infosiftr.net/job/bashbrew/job/master/lastSuccessfulBuild/artifact/bashbrew-amd64
   chmod +x bashbrew

   export PATH=".:$PATH"
   export GITHUB_REPOSITORY=phpcollab
   ```

### Iterative Stuff

After making template file changes:

1. Run the following to propagate the changes to the image set:
   ```sh
   ./apply-template.sh
   ```
1. Commit (but not necessarily push).
1. Create the build scripts.
   ```sh
   ./generate.sh
   ```
1. From the host machine (that has `docker buildx` installed) run the appropriate `run` command from the output of the `./generate.sh` script, for the desired image.

### Helpful notes

- Running `./generate-stackbrew-library.sh` can be helpful in viewing the bashbrew manifest used by the `generate.sh` script, **but do not commit this file. It will likely break the build.**

## `versions.json`

Format:

```json
{
  "<label>": {
    "phpVersions": ["<php_docker_image_versions>"],
    "sha1": "<phpCollab_download_hash>",
    "upstream": "<phpCollab_download_version>",
    "variants": ["<php_docker_image_variants>"],
    "version": "<phpCollab_docker_image_version>"
  }
}
```

Example files:

- Barebones (just php 7.4 on Apache):

  ```json
  {
    "latest": {
      "phpVersions": ["7.4"],
      "sha1": "1f0a41545a28d12e7364167544c55ade7b7e7814",
      "upstream": "2.8.1",
      "variants": ["apache"],
      "version": "2.8.1"
    }
  }
  ```

- A fairly complete, but only `latest` and no `fpm-alpine`:
  ```json
  {
    "latest": {
      "phpVersions": ["8.0", "7.4", "7.3"],
      "sha1": "1f0a41545a28d12e7364167544c55ade7b7e7814",
      "upstream": "2.8.1",
      "variants": ["apache", "fpm"],
      "version": "2.8.1"
    }
  }
  ```
- Complete (lots of possibilites):
  ```json
  {
    "beta": {
      "phpVersions": ["8.0", "7.4", "7.3"],
      "sha1": "1f0a41545a28d12e7364167544c55ade7b7e7814",
      "upstream": "2.8.1",
      "variants": ["apache", "fpm", "fpm-alpine"],
      "version": "2.8.1"
    },
    "latest": {
      "phpVersions": ["8.0", "7.4", "7.3"],
      "sha1": "1f0a41545a28d12e7364167544c55ade7b7e7814",
      "upstream": "2.8.1",
      "variants": ["apache", "fpm", "fpm-alpine"],
      "version": "2.8.1"
    }
  }
  ```
  > Note: Beta refers to the Docker image being beta (new entrypoint, configs, etc) and not necessarily the phpCollab deployment itself.
