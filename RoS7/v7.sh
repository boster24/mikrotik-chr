#!/bin/bash

# Update dan instal dependensi QEMU
sudo apt update
sudo apt install -y wget unzip qemu-utils qemu-user-static

# Download MikroTik CHR Image
wget https://github.com/elseif/MikroTikPatch/releases/download/7.20.6/chr-7.20.6-legacy-bios.img.zip

# Ekstrak Image
unzip chr-7.20.6-legacy-bios.img.zip

# Konversi Image ke QCOW2
qemu-img convert -f raw -O qcow2 chr-7.20.6-legacy-bios.img chr-7.20.6.qcow2

# Resize QCOW2 menjadi 32GB
qemu-img resize chr-7.20.6.qcow2 32G

# Buat Dockerfile
cat <<EOF > Dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y qemu-user-static qemu-system-x86

COPY chr-7.20.6.qcow2 /chr-7.20.6.qcow2

EXPOSE 8291 80 443 22 23 21 53/udp 53/tcp 123/udp 8728 8729

CMD ["qemu-system-x86_64",
     "-m", "4096M",
     "-smp", "4",
     "-hda", "/chr-7.20.6.qcow2",
     "-serial", "mon:stdio",
     "-nographic",
     "-nic", "user,model=e1000,hostfwd=tcp::8291-:8291,hostfwd=tcp::80-:80,hostfwd=tcp::443-:443,hostfwd=tcp::22-:22,hostfwd=tcp::23-:23,hostfwd=tcp::21-:21,hostfwd=udp::53-:53,hostfwd=tcp::53-:53,hostfwd=udp::123-:123,hostfwd=tcp::8728-:8728,hostfwd=tcp::8729-:8729"]
EOF

# Build Docker Image
sudo docker build -t mikrotik-chr .

# Hentikan container lama (jika ada)
sudo docker rm -f mikrotik-chr 2>/dev/null

# Jalankan container MikroTik CHR (auto-boot + auto-restart)
sudo docker run -d --name mikrotik-chr --restart unless-stopped \
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
    mikrotik-chr

echo ""
echo "=============================="
echo " MikroTik CHR is RUNNING!"
echo " Access Winbox: IP-VPS:7000"
echo "=============================="
