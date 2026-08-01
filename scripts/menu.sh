#!/bin/bash

INSTALL_DIR="/opt/realm-entry-node"
source "$INSTALL_DIR/scripts/utils.sh"

CONFIG_FILE="/etc/realm/config.toml"

check_root

add_port() {
    echo -e "\n${BLUE}--- THÊM CỔNG CHUYỂN TIẾP ---${NC}"
    read -p "Nhập Cổng lắng nghe trên VPS hiện tại: " listen_port
    read -p "Nhập IP Node Gốc: " remote_ip
    read -p "Nhập Cổng Node Gốc: " remote_port

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
    echo -e "\n${BLUE}--- XÓA CỔNG CHUYỂN TIẾP ---${NC}"
    read -p "Nhập Cổng cần xóa (VD: 8080): " listen_port

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

check_traffic() {
    echo -e "\n${BLUE}--- KIỂM TRA LƯU LƯỢNG KẾT NỐI ---${NC}"
    read -p "Nhập Cổng cần kiểm tra: " check_port

    if [[ -z "$check_port" ]]; then
        print_error "Cổng không được để trống."
        return
    fi

    echo -e "\n${YELLOW}[+] Đang kiểm tra kết nối TCP (VLESS/Trojan/Shadowsocks...):${NC}"
    TCP_RESULT=$(ss -tunp | grep ":$check_port ")
    if [[ -n "$TCP_RESULT" ]]; then
        echo "$TCP_RESULT"
    else
        echo "-> Không có kết nối TCP nào đang hoạt động."
    fi

    echo -e "\n${YELLOW}[+] Đang kiểm tra kết nối UDP (Hysteria2/WireGuard/TUIC...):${NC}"
    if ! command -v tcpdump &> /dev/null; then
        apt-get install tcpdump -y -q > /dev/null 2>&1
    fi
    
    echo -e "${CYAN}--> Vui lòng mở App và lướt web ngay bây giờ. Đang chờ 5 giây để bắt tín hiệu...${NC}"
    timeout 5 tcpdump -i any udp port "$check_port" -n -c 10 2>/dev/null
    
    if [ $? -eq 124 ]; then
        echo -e "${RED}-> Không phát hiện tín hiệu UDP nào trong 5 giây qua.${NC}"
    else
        echo -e "${GREEN}-> Đã bắt được dữ liệu UDP thành công.${NC}"
    fi
}

while true; do
    echo -e "\n${BLUE}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}         ${GREEN}BẢNG ĐIỀU KHIỂN REALM ENTRY NODE${NC}         ${BLUE}║${NC}"
    echo -e "${BLUE}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}Tác giả:${NC} Vietnamvpn | ${BLUE}Website:${NC} https://linksub24h.com"
    echo -e "$(check_service_status)"
    echo -e "${BLUE}╠══════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}1${NC} Thêm cổng chuyển tiếp mới"
    echo -e "  ${YELLOW}2${NC} Xóa cổng chuyển tiếp hiện có"
    echo -e "  ${YELLOW}3${NC} Sửa file cấu hình thủ công"
    echo -e "  ${YELLOW}4${NC} Kiểm tra App có đi qua VPS"
    echo -e "  ${YELLOW}5${NC} Cập nhật hệ thống"
    echo -e "  ${YELLOW}6${NC} Khởi động lại dịch vụ Realm"
    echo -e "  ${YELLOW}7${NC} Gỡ cài đặt toàn bộ"
    echo -e "  ${RED}0${NC} Thoát chương trình"
    echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
    read -p "Nhập lựa chọn của bạn: " choice

    case $choice in
        1) add_port ;;
        2) delete_port ;;
        3) edit_config ;;
        4) check_traffic ;;
        5) exec bash "$INSTALL_DIR/scripts/update.sh" ;;
        6) systemctl restart realm && print_info "Đã khởi động lại Realm." ;;
        7) bash "$INSTALL_DIR/scripts/uninstall.sh" ; exit 0 ;;
        0) exit 0 ;;
        *) print_error "Lựa chọn không hợp lệ." ;;
    esac
done