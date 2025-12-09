FROM alpine:3.20.2

RUN apk update && apk add --no-cache qemu-system-x86_64

VOLUME /chr

COPY chr-7.20.6.qcow2 /chr/chr-7.20.6.qcow2

EXPOSE 8291 80 443 22 23 21 53 123 8728 8729 2210 179 8292 1723
EXPOSE 1194/udp 53/udp 123/udp 1701/udp 500/udp 4500/udp 1812/udp 1813/udp

CMD ["qemu-system-x86_64", "-m", "4096M", "-smp", "4", "-hda", "/chr/chr-7.20.6.qcow2", "-serial", "mon:stdio", "-nographic", "-nic", "user,model=e1000,hostfwd=tcp::8291-:8291,hostfwd=tcp::80-:80,hostfwd=tcp::443-:443,hostfwd=tcp::22-:22,hostfwd=tcp::23-:23,hostfwd=tcp::21-:21,hostfwd=udp::53-:53,hostfwd=tcp::53-:53,hostfwd=udp::123-:123,hostfwd=tcp::8728-:8728,hostfwd=tcp::8729-:8729,hostfwd=tcp::2210-:2210,hostfwd=tcp::179-:179,hostfwd=tcp::8292-:8292,hostfwd=udp::1194-:1194,hostfwd=tcp::1194-:1194,hostfwd=udp::1701-:1701,hostfwd=tcp::1723-:1723,hostfwd=udp::500-:500,hostfwd=udp::4500-:4500,hostfwd=tcp::50-:50,hostfwd=tcp::51-:51,hostfwd=udp::1812-:1812,hostfwd=udp::1813-:1813"]
