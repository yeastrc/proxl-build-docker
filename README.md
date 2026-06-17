# proxl-build-docker

Dockerfile for creating a Docker image in which to build proxl.

The image bundles the proxl build toolchain:

- Ubuntu 24.04 LTS
- Eclipse Temurin JDK 25 (Gradle daemon + Java 25 projects) and JDK 8 (`proxl_submit_import`, which stays on Java 8)
- Node.js 20 + npm 10 (pinned to Node 20 because the web build still uses webpack 4)
- Ant, Gradle (via the Gradle Wrapper in the proxl source)

## Using the prebuilt image

Published images are available (publicly) from GitHub Container Registry. Pull
`:latest` to always track the newest release:

```
docker pull ghcr.io/yeastrc/proxl-build-docker:latest
```

`:latest` is republished automatically with each GitHub release. To pin to a
specific version instead, use a release tag — e.g. `:2.0.0`, or a less specific
`:2` / `:2.0`.

To build proxl with the published image instead of a locally built one, substitute
`ghcr.io/yeastrc/proxl-build-docker:latest` for `local-build-image/build-proxl` in the
build commands below.

## Building the image locally

Run from inside this repository (where the `Dockerfile` lives):

```
docker image build -t local-build-image/build-proxl ./
```

## Building proxl

Run from the **root of the proxl source tree** (the directory containing `ant__build_all_proxl.xml`).
The command below builds as your own user so all generated files are owned by you instead of root:

```
docker run --rm -it \
  --user $(id -u):$(id -g) \
  -v "$(pwd)":"$(pwd)" -w "$(pwd)" \
  --env HOME=. \
  --entrypoint ant \
  local-build-image/build-proxl -f ant__build_all_proxl.xml
```

- `--user $(id -u):$(id -g)` runs the build as your UID/GID, so all output is owned by you.
- `-v "$(pwd)":"$(pwd)" -w "$(pwd)"` mounts your source at the same path inside and out, so artifacts land in your tree.
- `--env HOME=.` gives Gradle/npm a writable `$HOME` (your UID has no home inside the container). Their caches (`.gradle`, `.npm`) are created under the source dir, owned by you.

To keep the Gradle/npm caches out of the source tree (and persist them between builds for speed), point `HOME` at a dedicated mounted directory instead:

```
mkdir -p ~/.proxl-build-home
docker run --rm -it \
  --user $(id -u):$(id -g) \
  -v "$(pwd)":"$(pwd)" -w "$(pwd)" \
  -v ~/.proxl-build-home:/build-home \
  --env HOME=/build-home \
  --entrypoint ant \
  local-build-image/build-proxl -f ant__build_all_proxl.xml
```

(Substitute the GHCR image name from above for `local-build-image/build-proxl` to build with the published image instead of a locally built one.)

## Continuous integration

Two GitHub Actions workflows live in `.github/workflows/`:

- **Docker Build** (`docker-build.yml`) — builds the image on every push and pull request and verifies the bundled tools (`java`, both `javac` versions, `node`, `npm`, `ant`).
- **Docker Release** (`docker-release.yml`) — on a published GitHub release (or manual `workflow_dispatch` with a tag), builds and pushes the image to `ghcr.io` with semver and `latest` tags.
