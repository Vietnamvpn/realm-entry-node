#!/bin/bash

INSTALL_DIR="/opt/realm-entry-node"
source "$INSTALL_DIR/scripts/utils.sh"

check_root

main() {
    print_info "Đang cập nhật mã nguồn quản lý từ GitHub..."
    cd "$INSTALL_DIR" || exit
    
    # Sửa lại lệnh git để ép đồng bộ 100%
    git fetch --all
    git reset --hard origin/main

    # Tự động cấp lại quyền thực thi
    chmod +x "$INSTALL_DIR/scripts/"*.sh
    chmod +x /usr/local/bin/vvc

    print_info "Đang cập nhật lõi Realm lên bản mới nhất..."
    REALM_URL="https://github.com/zhboner/realm/releases/latest/download/realm-x86_64-unknown-linux-musl.tar.gz"

    systemctl stop realm

    cd /tmp || exit
    wget -qO realm.tar.gz "$REALM_URL"
    tar -xvf realm.tar.gz
    mv realm /usr/local/bin/realm
    chmod +x /usr/local/bin/realm
    rm -f realm.tar.gz

    systemctl start realm
    print_info "Cập nhật mã nguồn và lõi Realm hoàn tất!"

    exit 0
}

# Gọi hàm main để toàn bộ tiến trình chạy trên RAM
main