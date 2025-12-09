#!/bin/bash
set -e

# ---- Konfigurasi ----
IMAGE_ZIP_URL="https://github.com/elseif/MikroTikPatch/releases/download/7.20.6/chr-7.20.6-legacy-bios.img.zip"
RAW_IMG="chr-7.20.6-legacy-bios.img"
QCOW2="chr-7.20.6.qcow2"
DOCKER_IMG_NAME="mikrotik-chr-image"
CONTAINER_NAME="mikrotik-chr"

# Update & install deps
apt update
apt install -y wget unzip qemu-utils docker.io

# Download CHR zip (skip if already ada)
if [ ! -f "${RAW_IMG}" ] && [ ! -f "${QCOW2}" ]; then
  echo "Downloading CHR image..."
  wget -O chr.zip "${IMAGE_ZIP_URL}"
  unzip -o chr.zip
  rm -f chr.zip || true
fi

# Jika hanya raw image ada, convert ke qcow2
if [ -f "${RAW_IMG}" ] && [ ! -f "${QCOW2}" ]; then
  echo "Converting ${RAW_IMG} -> ${QCOW2}..."
  qemu-img convert -f raw -O qcow2 "${RAW_IMG}" "${QCOW2}"
fi

# Resize (opsional) -- jalankan hanya jika mau resize
if [ -f "${QCOW2}" ]; then
  echo "Resizing ${QCOW2} to 32G (will keep if already same size)..."
  qemu-img resize "${QCOW2}" 32G || true
fi

# Hapus Dockerfile lama jika ada
rm -f Dockerfile

# Buat Dockerfile yang VALID (CMD satu baris)
cat > Dockerfile <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y qemu-system-x86

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

# Pastikan file QCOW2 ditempatkan dengan nama yang DI COPY di Dockerfile
if [ ! -f "${QCOW2}" ]; then
  echo "ERROR: File ${QCOW2} tidak ditemukan. Pastikan script berhasil mengkonversi atau letakkan file di direktori.
  Aborting."
  exit 1
fi

# Rename/copy QCOW2 ke nama yang dipakai Dockerfile agar konsisten
cp -f "${QCOW2}" ./chr-7.20.6.qcow2

# Convert line endings to unix (hindari CRLF)
if command -v dos2unix >/dev/null 2>&1; then
  dos2unix Dockerfile || true
else
  apt install -y dos2unix
  dos2unix Dockerfile || true
fi

# Build Docker image
echo "Building Docker image ${DOCKER_IMG_NAME}..."
docker build -t "${DOCKER_IMG_NAME}" .

# Stop & remove old container if ada
docker rm -f "${CONTAINER_NAME}" 2>/dev/null || true

# Run container with restart policy
echo "Starting container ${CONTAINER_NAME} with restart=always..."
docker run -d --name "${CONTAINER_NAME}" --restart=always \
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
    "${DOCKER_IMG_NAME}"

echo ""
echo "=============================="
echo " MikroTik CHR is RUNNING!"
echo " Winbox: IP-VPS:7000"
echo " To watch log: docker logs -f ${CONTAINER_NAME}"
echo "=============================="
