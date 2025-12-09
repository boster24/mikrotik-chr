#!/bin/bash

set -e

# Update & install dependencies
apt update
apt install -y wget unzip qemu-utils

# Download CHR Image
wget -O chr.zip https://github.com/elseif/MikroTikPatch/releases/download/7.20.6/chr-7.20.6-legacy-bios.img.zip

# Extract
unzip chr.zip
rm -f chr.zip

# Convert RAW → QCOW2
qemu-img convert -f raw -O qcow2 chr-7.20.6-legacy-bios.img chr-7.20.6.qcow2

# Resize QCOW2 → 32GB
qemu-img resize chr-7.20.6.qcow2 32G

# FIX: Create Valid Dockerfile
cat <<EOF > Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y qemu-system-x86

COPY chr-7.20.6.qcow2 /chr.qcow2

EXPOSE 8291
EXPOSE 80
EXPOSE 443
EXPOSE 22
EXPOSE 23
EXPOSE 21
EXPOSE 53/udp
EXPOSE 53/tcp
EXPOSE 123/udp
EXPOSE 8728
EXPOSE 8729

CMD ["qemu-system-x86_64", "-m", "4096M", "-smp", "4", "-hda", "/chr.qcow2", "-serial", "mon:stdio", "-nographic", "-nic", "user,model=e1000,hostfwd=tcp::8291-:8291,hostfwd=tcp::80-:80,hostfwd=tcp::443-:443,hostfwd=tcp::22-:22,hostfwd=tcp::23-:23,hostfwd=tcp::21-:21,hostfwd=udp::53-:53,hostfwd=tcp::53-:53,hostfwd=udp::123-:123,hostfwd=tcp::8728-:8728,hostfwd=tcp::8729-:8729"]
EOF

# Build image
docker build -t chr-image .

# Stop old container
docker rm -f chr 2>/dev/null || true

# Run with auto-restart
docker run -d --name chr --restart=always \
    -p 7000:8291 \
    -p 7001:80 \
    -p 7002:443 \
    -p 7003:22 \
    -p 7004:23 \
    -p 7005:21 \
    -p 7006:53/udp \
    -p 7007:53/tcp \
    -p 7008:123/udp \
    -p 7009:8728 \
    -p 7010:8729 \
    chr-image

echo ""
echo "=============================="
echo " MikroTik CHR is RUNNING!"
echo " Winbox: IP-VPS:7000"
echo "=============================="
