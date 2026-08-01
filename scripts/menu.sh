#!/bin/bash

INSTALL_DIR="/opt/realm-entry-node"
source "$INSTALL_DIR/scripts/utils.sh"

CONFIG_FILE="/etc/realm/config.toml"

check_root

add_port() {
    echo -e "\n${CYAN}--- THÊM CỔNG CHUYỂN TIẾP ---${NC}"
    read -p "Nhập Cổng (Port) lắng nghe trên VPS hiện tại: " listen_port
    read -p "Nhập IP đích (IP Node Gốc): " remote_ip
    read -p "Nhập Cổng đích (Port Node Gốc): " remote_port

    if [[ -z "$listen_port" || -z "$remote_ip" || -z "$remote_port" ]]; then
        print_error "Thông tin không được để trống."
        return
    fi

    echo "" >> "$CONFIG_FILE"
    echo "[[endpoints]]" >> "$CONFIG_FILE"
    echo "listen = \"0.0.0.0:$listen_port\"" >> "$CONFIG_FILE"
    echo "remote = \"$remote_ip:$remote_port\"" >> "$CONFIG_FILE"

    systemctl restart realm
    print_info "Đã thêm thành công! Cổng $listen_port đang chuyển tới $remote_ip:$remote_port."
}

delete_port() {
    echo -e "\n${CYAN}--- XÓA CỔNG CHUYỂN TIẾP ---${NC}"
    read -p "Nhập Cổng lắng nghe cần xóa (VD: 8080): " listen_port

    if [[ -z "$listen_port" ]]; then
        print_error "Cổng không hợp lệ."
        return
    fi

    LINE_NUM=$(grep -n "listen = \"0.0.0.0:$listen_port\"" "$CONFIG_FILE" | cut -d: -f1)
    
    if [ -z "$LINE_NUM" ]; then
        print_error "Không tìm thấy cấu hình cho cổng $listen_port."
        return
    fi

    START_LINE=$((LINE_NUM - 2))
    END_LINE=$((LINE_NUM + 1))
    
    sed -i "${START_LINE},${END_LINE}d" "$CONFIG_FILE"
    
    systemctl restart realm
    print_info "Đã xóa hoàn toàn chuyển tiếp cho cổng $listen_port."
}

edit_config() {
    nano "$CONFIG_FILE"
    systemctl restart realm
    print_info "Đã áp dụng thay đổi và khởi động lại Realm."
}

while true; do
    echo -e "\n=============================="
    echo -e "   ${CYAN}QUẢN LÝ REALM (Lệnh: vvc)${NC}   "
    echo -e "=============================="
    check_service_status
    echo "------------------------------"
    echo "1. Thêm cổng chuyển tiếp mới"
    echo "2. Xóa cổng chuyển tiếp hiện có"
    echo "3. Sửa file cấu hình thủ công"
    echo "4. Cập nhật hệ thống (Code & Lõi)"
    echo "5. Khởi động lại dịch vụ Realm"
    echo "6. Gỡ cài đặt toàn bộ"
    echo "0. Thoát chương trình"
    echo "------------------------------"
    read -p "Nhập lựa chọn của bạn: " choice

    case $choice in
        1) add_port ;;
        2) delete_port ;;
        3) edit_config ;;
        4) bash "$INSTALL_DIR/scripts/update.sh" ;;
        5) systemctl restart realm && print_info "Đã khởi động lại Realm." ;;
        6) bash "$INSTALL_DIR/scripts/uninstall.sh" ; exit 0 ;;
        0) exit 0 ;;
        *) print_error "Lựa chọn không hợp lệ." ;;
    esac
done