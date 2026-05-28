#!/bin/bash

ISO_PATH="/home/thi-phng/goinfre/alpine-standard-3.23.4-x86_64.iso"
DISK_PATH="/home/thi-phng/goinfre/alpine_main_bignode.qcow2"

# 1. Tạo ổ đĩa ảo khoảng 20GB (thoải mái chứa các máy ảo con bên trong, file qcow2 ăn theo dung lượng thực tế nên không lo tốn 20GB ngay lập tức)
if [ ! -f "$DISK_PATH" ]; then
    echo "Đang tạo ổ đĩa ảo 20GB cho Máy ảo Tổ trưởng..."
    qemu-img create -f qcow2 "$DISK_PATH" 20G
fi

# 2. Bật QEMU để cài đặt OS từ ISO
# Bắt buộc phải có -cpu host và -enable-kvm để kích hoạt lồng ảo hóa (Nested Virtualization)
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -m 3072 \
    -smp 2 \
    -hda "$DISK_PATH" \
    -cdrom "$ISO_PATH" \
    -boot d \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::2222-:22 \
    -nographic
