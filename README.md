# muak-os/sbc-raspberrypi

The Raspberry Pi boot overlays for [muak](https://github.com/muak-os/muak).

The Pi 5 firmware moved the GPU firmware into the SPI-flash bootloader on the board, so the boot partition needs no
`start*.elf` / `fixup*.dat` / `bootcode.bin`. This is the only difference between the two overlays.

## Overlay OCI layout

The same UEFI firmware hand-off applies to both overlays; the Pi 5 overlay is
just slimmer because the GPU firmware is baked into its bootloader.

```
rpi_generic/
└── partitions/
    └── C12A7328-F81F-11D2-BA4B-00A0C93EC93B/   # EFI System Partition GUID
        ├── config.txt
        ├── u-boot.bin
        ├── start4.elf
        ├── fixup4.dat
        ├── bootcode.bin
        ├── bcm2711-rpi-4-b.dtb
        ├── bcm2711-rpi-400.dtb
        ├── bcm2711-rpi-cm4.dtb
        ├── overlays/disable-bt.dtbo
        ├── overlays/disable-wifi.dtbo
        └── ... (firmware boot files)

rpi_5/
└── partitions/
    └── C12A7328-F81F-11D2-BA4B-00A0C93EC93B/
        ├── config.txt
        ├── u-boot.bin
        ├── bcm2712-rpi-5-b.dtb
        ├── bcm2712-rpi-cm5-cm4io.dtb
        ├── bcm2712-rpi-cm5-cm5io.dtb
        ├── bcm2712d0-rpi-5-b.dtb
        ├── overlays/...
        └── COPYING.linux
```

## Artifacts

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
