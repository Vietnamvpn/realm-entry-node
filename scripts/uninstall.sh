#!/bin/bash

INSTALL_DIR="/opt/realm-entry-node"
source "$INSTALL_DIR/scripts/utils.sh"

check_root

print_warn "Bạn có chắc chắn muốn GỠ BỎ TOÀN BỘ hệ thống Realm không? (y/n)"
read -r confirm

if [ "$confirm" != "y" ]; then
    print_info "Đã hủy tác vụ gỡ cài đặt."
    exit 0
fi

systemctl stop realm
systemctl disable realm
rm -f /etc/systemd/system/realm.service
systemctl daemon-reload

rm -f /usr/local/bin/realm
rm -rf /etc/realm
rm -f /usr/local/bin/vvc
rm -rf "$INSTALL_DIR"

print_info "Đã xóa toàn bộ phần mềm, cấu hình và lệnh 'vvc' khỏi hệ thống!"