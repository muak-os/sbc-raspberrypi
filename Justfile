# Raspberry Pi boot overlays for muak
#
# Prerequisites: docker/podman, just, git
# Run `just --list` for available recipes

set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]
set positional-arguments

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Global settings

registry := env_var_or_default("REGISTRY", "ghcr.io/muak-os")
tag := env_var_or_default("TAG", "latest")
toolchain := env_var_or_default("TOOLCHAIN", "ghcr.io/muak-os/toolchain@sha256:aa9208691a4799dc34b42acb9a14aef4d7599d554ecaac1e36c9c76319cbd960")
push := env_var_or_default("PUSH", "false")
latest := env_var_or_default("LATEST", "false")
board := env_var_or_default("BOARD", "rpi_generic")

# Overlay image repository

overlay_repository := if board == "rpi_5" { "sbc/raspberrypi-5" } else { "sbc/raspberrypi" }

# Architecture (arm64 only)

[private]
_arch_env := env_var_or_default("ARCH", "arm64")
arch := if _arch_env == "arm64" { "aarch64" } else if _arch_env == "aarch64" { "aarch64" } else { error("unsupported ARCH '" + _arch_env + "': only arm64/aarch64 is supported") }
oci_arch := if arch == "aarch64" { "arm64" } else { error("unsupported arch '" + arch + "': only aarch64 is supported") }

# Container runtime

container_runtime := env_var_or_default("CONTAINER_RUNTIME", "podman")
build_cmd := if container_runtime == "podman" { "podman build" } else { "docker buildx build" }
pull_arg := if container_runtime == "podman" { "--pull=missing" } else { "" }
push_arg := if container_runtime == "podman" { "" } else { if push == "true" { "--push" } else { "" } }
provenance_arg := if container_runtime == "podman" { "" } else { "--provenance=false" }
common_args := "--platform=linux/" + oci_arch + " --progress=" + env_var_or_default("PROGRESS", "auto") + " " + provenance_arg

# Colors

bold := '\e[1m'
cyan := '\e[36m'
green := '\e[32m'
red := '\e[31m'
reset := '\e[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Build
# ─────────────────────────────────────────────────────────────────────────────

# Full local development build (build → annotate)
[group('build')]
dev: build annotate
    @printf "{{ green }}Development build complete. Toolchain used: {{ bold }}{{ toolchain }}{{ reset }}\n"

# Build the shared images needed by the board overlays (u-boot, firmware)
[group('build')]
[script]
shared:
    just _build-oci sbc/raspberrypi/u-boot shared/u-boot Dockerfile
    just _build-oci sbc/raspberrypi/firmware shared/raspberrypi-firmware Dockerfile
    printf "{{ green }}Shared images built{{ reset }}\n"

# Build the specific board overlay image and push when PUSH=true
[group('build')]
[script]
build: shared
    case "{{ board }}" in
        rpi_generic|rpi_5) ;;
        *) printf "{{ red }}{{ bold }}Error:{{ reset }} no image name for board {{ board }}\n"; exit 1 ;;
    esac
    uboot_image="{{ registry }}/sbc/raspberrypi/u-boot:{{ tag }}"
    firmware_image="{{ registry }}/sbc/raspberrypi/firmware:{{ tag }}"
    just _build-oci "{{ overlay_repository }}" "{{ board }}" Dockerfile \
        --build-arg "UBOOT_IMAGE=$uboot_image" \
        --build-arg "FIRMWARE_IMAGE=$firmware_image"
    printf "{{ green }}Overlay image built: {{ registry }}/{{ overlay_repository }}:{{ tag }}{{ reset }}\n"

# ─────────────────────────────────────────────────────────────────────────────
# OCI Images
# ─────────────────────────────────────────────────────────────────────────────

# Annotate an OCI image in the registry with per-entry sizes.
[group('oci')]
[arg("image", long="image")]
annotate image=(registry + "/" + overlay_repository + ":" + tag):
    @printf "{{ cyan }}Annotating OCI image {{ image }}{{ reset }}\n"
    {{ container_runtime }} run --rm --network=host \
        -e KOCI_REGISTRY_USERNAME -e KOCI_REGISTRY_PASSWORD \
        {{ toolchain }} \
        /koci annotate \
            --image "{{ image }}" \
            --annotation dev.muak.sizes

# ─────────────────────────────────────────────────────────────────────────────
# Private Helpers
# ─────────────────────────────────────────────────────────────────────────────

[private]
[script]
_build-oci name context dockerfile *extra:
    image="{{ registry }}/{{ name }}:{{ tag }}"
    cache_from=$(just _cache-from "{{ name }}")
    cache_to=$(just _cache-to "{{ name }}")
    tags="--tag ${image}"
    if [ "{{ latest }}" = "true" ]; then
        tags="${tags} --tag {{ registry }}/{{ name }}:latest"
    fi
    printf "{{ cyan }}Building OCI:{{ reset }} {{ name }} (push={{ push }}, latest={{ latest }})\n"
    {{ build_cmd }} {{ common_args }} {{ pull_arg }} \
        ${cache_from} ${cache_to} {{ push_arg }} ${tags} {{ extra }} \
        --file {{ context }}/{{ dockerfile }} \
        {{ context }}
    if [ "{{ container_runtime }}" = "podman" ] && [ "{{ push }}" = "true" ]; then
        {{ container_runtime }} push "${image}"
        if [ "{{ latest }}" = "true" ]; then {{ container_runtime }} push "{{ registry }}/{{ name }}:latest"; fi
    fi

[private]
_cache-from name:
    @if [ "{{ env_var_or_default("GITHUB_ACTIONS", "false") }}" = "true" ]; then printf '%s' "--cache-from=type=registry,ref={{ registry }}/{{ name }}:buildcache-{{ oci_arch }}"; fi

[private]
_cache-to name:
    @if [ "{{ env_var_or_default("GITHUB_ACTIONS", "false") }}" = "true" ] && [ "{{ push }}" = "true" ]; then printf '%s' "--cache-to=type=registry,ref={{ registry }}/{{ name }}:buildcache-{{ oci_arch }},mode=max"; fi
