# syntax = docker/dockerfile-upstream:1.26.0-labs
# rpi_5 (Pi 5 / CM5, BCM2712) overlay for muak.

ARG UBOOT_IMAGE=sbc/raspberrypi/u-boot:latest
ARG FIRMWARE_IMAGE=sbc/raspberrypi/firmware:latest

FROM ${UBOOT_IMAGE} AS uboot
FROM ${FIRMWARE_IMAGE} AS firmware

FROM scratch AS prep

COPY --from=uboot /u-boot.bin /esp/u-boot.bin
COPY --from=firmware /boot/bcm2712*.dtb /esp/
COPY --from=firmware /boot/overlays /esp/overlays
COPY --from=firmware /boot/COPYING.linux /esp/

FROM scratch

COPY --from=prep /esp "/rpi_5/partitions/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/"
COPY config.txt "/rpi_5/partitions/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/config.txt"

LABEL org.opencontainers.image.title="muak-sbc-raspberrypi"
LABEL org.opencontainers.image.description="Raspberry Pi 5 boot overlay for Muak"
LABEL org.opencontainers.image.source="https://github.com/muak-os/sbc-raspberrypi"
