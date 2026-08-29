# syntax = docker/dockerfile-upstream:1.26.0-labs
# rpi_generic (Pi 4 / 400 / CM4, BCM2711) overlay for muak.

ARG UBOOT_IMAGE=sbc/raspberry-pi/u-boot:latest
ARG FIRMWARE_IMAGE=sbc/raspberry-pi/firmware:latest

FROM ${UBOOT_IMAGE} AS uboot
FROM ${FIRMWARE_IMAGE} AS firmware

FROM scratch AS prep

COPY --from=uboot /u-boot.bin /esp/u-boot.bin
COPY --from=firmware /boot/*.elf /esp/
COPY --from=firmware /boot/*.dat /esp/
COPY --from=firmware /boot/bootcode.bin /esp/
COPY --from=firmware /boot/COPYING.linux /esp/
COPY --from=firmware /boot/LICENCE.broadcom /esp/
COPY --from=firmware /boot/bcm2708*.dtb /esp/
COPY --from=firmware /boot/bcm2709*.dtb /esp/
COPY --from=firmware /boot/bcm2710*.dtb /esp/
COPY --from=firmware /boot/bcm2711*.dtb /esp/
COPY --from=firmware /boot/overlays /esp/overlays

FROM scratch

COPY --from=prep /esp "/rpi_generic/partitions/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/"
COPY config.txt "/rpi_generic/partitions/C12A7328-F81F-11D2-BA4B-00A0C93EC93B/config.txt"

LABEL org.opencontainers.image.title="muak-sbc-raspberrypi"
LABEL org.opencontainers.image.description="Raspberry Pi generic boot overlay for Muak"
LABEL org.opencontainers.image.source="https://github.com/muak-os/sbc-raspberrypi"
