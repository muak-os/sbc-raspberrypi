# muak-os/sbc-raspberrypi

The Raspberry Pi boot overlays for [muak](https://github.com/muak-os/muak).

The Pi 5 firmware moved the GPU firmware into the SPI-flash bootloader on the board, so the boot partition needs no
`start*.elf` / `fixup*.dat` / `bootcode.bin`. This is the only difference between the two overlays.

## Shared Blobs

| Artifact | Version | Source |
| -------- | ------- | ------ |
| U-Boot (`rpi_arm64_defconfig`) | `2026.01` | https://ftp.denx.de/pub/u-boot/ |
| Raspberry Pi firmware | `1.20260521` | https://github.com/raspberrypi/firmware |


## Local Development

A local OCI registry makes iterative testing easy:

```sh
podman run -d -p 5000:5000 --name registry docker.io/library/registry:3

REGISTRY="localhost:5000" BOARD=rpi_5 PUSH=true LATEST=true just build
```

## Flash And Test

1. Get the raw artifact.
2. Decompress and write it to an SD card:
   ```sh
   zstd -d muak.raw.zst -o muak.raw
   sudo dd if=muak.raw of=/dev/sdX bs=4M conv=fsync
   ```
3. Attach a USB-UART adapter to the Pi GPIO (pin 8 = TXD, pin 10 = RXD,
   GND), 115200 8N1.
4. Power on. You should see the U-Boot banner, then muak's kernel console
   (`console=ttyAMA0,115200`).
