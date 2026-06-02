#!/bin/bash

ISO_PATH="/home/thi-phng/goinfre/ubuntu-22.04.5-live-server-amd64.iso"
DISK_PATH="/home/thi-phng/goinfre/IOT.qcow2"

# 1. Tạo ổ đĩa ảo khoảng 15GB (thoải mái chứa các máy ảo con bên trong, file qcow2 ăn theo dung lượng thực tế nên không lo tốn 20GB ngay lập tức)
if [ ! -f "$DISK_PATH" ]; then
    echo "Đang tạo ổ đĩa ảo 15GB cho Máy ảo Tổ trưởng..."
    qemu-img create -f qcow2 "$DISK_PATH" 15G
fi

# 2. Bật QEMU để cài đặt OS từ ISO
# Bắt buộc phải có -cpu host và -enable-kvm để kích hoạt lồng ảo hóa (Nested Virtualization)
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -m 3072 \
    -smp 2 \
    -hda "$DISK_PATH" \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::2222-:22 \
    -vnc :1

