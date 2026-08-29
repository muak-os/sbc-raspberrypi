# Raspberry Pi boot overlays for muak
#
# Prerequisites: docker/podman, just, git
# Run `just --list` for available recipes

set positional-arguments
set shell := ["bash", "-euo", "pipefail", "-c"]
set script-interpreter := ["bash", "-euo", "pipefail"]

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Global settings

registry := env_var_or_default("REGISTRY", "ghcr.io/muak-os")
tag := env_var_or_default("TAG", "latest")
push := env_var_or_default("PUSH", "false")
latest := env_var_or_default("LATEST", "false")
board := env_var_or_default("BOARD", "rpi_generic")

# Container runtime

container_runtime := env_var_or_default("CONTAINER_RUNTIME", "podman")
build_cmd := if container_runtime == "podman" { "podman build" } else { "docker buildx build" }
provenance_arg := if container_runtime == "podman" { "" } else { "--provenance=false" }
common_args := "--platform=linux/arm64 --progress=" + env_var_or_default("PROGRESS", "auto") + " " + provenance_arg

# Colors

cyan := '\e[36m'
green := '\e[32m'
red := '\e[31m'
reset := '\e[0m'

# ─────────────────────────────────────────────────────────────────────────────
# Recipes
# ─────────────────────────────────────────────────────────────────────────────

# Build the shared images needed by the board overlays (u-boot, firmware)
[script]
shared:
    just _build-oci sbc/raspberry-pi/u-boot shared/u-boot Dockerfile
    just _build-oci sbc/raspberry-pi/firmware shared/raspberrypi-firmware Dockerfile
    printf "{{ green }}Shared images built{{ reset }}\n"

# Build the BOARD overlay image (linux/arm64) and push when PUSH=true
[script]
build: shared
    uboot_image="{{ registry }}/sbc/raspberry-pi/u-boot:{{ tag }}"
    firmware_image="{{ registry }}/sbc/raspberry-pi/firmware:{{ tag }}"
    case "{{ board }}" in
        rpi_generic) image_name="sbc/raspberry-pi" ;;
        rpi_5)       image_name="sbc/raspberry-pi-5" ;;
        *) printf "{{ red }}Error:{{ reset }} no image name for board {{ board }}\n"; exit 1 ;;
    esac
    just _build-oci "$image_name" "{{ board }}" Dockerfile \
        --build-arg "UBOOT_IMAGE=$uboot_image" \
        --build-arg "FIRMWARE_IMAGE=$firmware_image"
    printf "{{ green }}Overlay image built: {{ registry }}/$image_name:{{ tag }}{{ reset }}\n"

# ─────────────────────────────────────────────────────────────────────────────
# Private helpers
# ─────────────────────────────────────────────────────────────────────────────

[private]
[script]
_build-oci name context dockerfile *extra:
    image="{{ registry }}/{{ name }}:{{ tag }}"
    tags="--tag ${image}"
    if [ "{{ latest }}" = "true" ]; then
        tags="${tags} --tag {{ registry }}/{{ name }}:latest"
    fi
    if [ "{{ container_runtime }}" = "podman" ]; then
        push_flags=""
    elif [ "{{ push }}" = "true" ]; then
        push_flags="--push"
    else
        push_flags=""
    fi
    printf "{{ cyan }}Building OCI:{{ reset }} {{ name }} (push={{ push }}, latest={{ latest }})\n"
    {{ build_cmd }} {{ common_args }} ${push_flags} \
        $(just _cache-from "{{ name }}") $(just _cache-to "{{ name }}") \
        ${tags} {{ extra }} \
        --file {{ context }}/{{ dockerfile }} \
        {{ context }}
    if [ "{{ container_runtime }}" = "podman" ] && [ "{{ push }}" = "true" ]; then
        podman push --tls-verify=false "${image}"
        if [ "{{ latest }}" = "true" ]; then
            podman push --tls-verify=false "{{ registry }}/{{ name }}:latest"
        fi
    fi

[private]
_cache-from name:
    @if [ "{{ env_var_or_default("GITHUB_ACTIONS", "false") }}" = "true" ]; then printf '%s' "--cache-from=type=registry,ref={{ registry }}/{{ name }}:buildcache-arm64"; fi

[private]
_cache-to name:
    @if [ "{{ env_var_or_default("GITHUB_ACTIONS", "false") }}" = "true" ] && [ "{{ push }}" = "true" ]; then printf '%s' "--cache-to=type=registry,ref={{ registry }}/{{ name }}:buildcache-arm64,mode=max"; fi
