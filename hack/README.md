# Agent development image

This directory builds an image with Debian, XFCE/Xvfb, Cua spacesd, Cua Driver,
Codex CLI, and BrowserOS Neo installed. It provides the installed software for
subsequent development. The default command is Bash; desktop sessions and
services are started by the caller.

## Build locally

Requirements: Docker with Buildx and Bash 3.2+. Allow approximately 8 GB of free
disk space for the first build.

```sh
./hack/build-image.sh
# Open a shell in the installed environment:
docker run --rm -it --platform linux/amd64 piergo-codex:dev
```

The image uses the `cua` user and `/home/cua/workspace` as its working directory.
It includes no credentials. To use Codex, authenticate inside the container
with `codex login --device-auth`.

The image targets **linux/amd64**, matching the official BrowserOS Neo Linux
package. Apple Silicon requires Docker's AMD64 emulation.

## Component versions

Defaults live in [`versions.env`](versions.env). A nonempty `PIERGO_<KEY>`
environment variable overrides the corresponding default:

```sh
PIERGO_CODEX_VERSION=0.162.1 PIERGO_CUA_DRIVER_VERSION=0.35.4 ./hack/build-image.sh
PIERGO_IMAGE=piergo-codex:experiment ./hack/build-image.sh
# Additional Docker Buildx options are passed through:
./hack/build-image.sh --no-cache
```

| Setting | Component |
| --- | --- |
| `DEBIAN_IMAGE` | Debian base image reference or digest |
| `NODE_IMAGE` | Node image reference or digest |
| `CUA_SPACESD_VERSION` | Cua spacesd, including its viewer and embedded driver |
| `CUA_DRIVER_VERSION` | Standalone Cua Driver |
| `CODEX_VERSION` | Exact `@openai/codex` npm release |
| `BROWSEROS_VERSION` | BrowserOS Neo release, without `v` |

The script passes component versions to Docker and loads the built image.
The Dockerfile downloads release artifacts, verifies GitHub's published SHA256
digests, and installs the software. Docker caches these build layers. Only
the Dockerfile is included in the build context; no host downloads are needed.

## GitHub workflow

[`desktop-image.yml`](../.github/workflows/desktop-image.yml) builds on relevant
pull requests and pushes to `main`. **Run workflow** accepts all six component
versions, an output image tag, and a `publish` checkbox. Empty version inputs
use `versions.env`.

The workflow resolves build parameters, logs in to ECR Public when publishing,
and builds the AMD64 image once. Pushes to `main` and manual runs with `publish`
enabled push that build to `public.ecr.aws/cloudpilotai/piergo-codex:<tag>`.
The default tag is `sha-<12-character-commit>`.

The login command and registry follow the CloudPilot repository's
`.github/workflows/cloudpilot-latest-build.yaml`. This repository uses the
following Actions secret names:

| Setting | Type | Purpose |
| --- | --- | --- |
| `AWS_ACCESS_KEY_ID` | Secret | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | Secret | AWS secret key |

Authentication uses `aws ecr-public get-login-password --region us-east-1`,
matching CloudPilot's ECR Public login. The `piergo-codex` repository must
exist under the `cloudpilotai` public registry before publishing.
Pull requests and manual runs with `publish` disabled only build the image.
AWS credentials are used only by the ECR login step when publishing.
