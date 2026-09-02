#!/bin/bash

INSTALL_DIR="/opt/realm-entry-node"
source "$INSTALL_DIR/scripts/utils.sh"

check_root

while true; do
    clear
    REALM_VER=$(/usr/local/bin/realm -V 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
    if [[ -z "$REALM_VER" ]]; then
        REALM_VER=$(/usr/local/bin/realm --version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
    fi

    if [[ -n "$REALM_VER" ]]; then
        DISPLAY_VER="v$REALM_VER"
    else
        DISPLAY_VER="Không xác định"
    fi

    echo -e "\n${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}              ${GREEN}BẢNG ĐIỀU KHIỂN REALM ENTRY NODE${NC}              ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${BLUE}Tác giả:${NC} Vietnamvpn  | ${BLUE}Phiên bản Core:${NC} ${GREEN}${DISPLAY_VER}${NC}"
    echo -e "  $(check_service_status) | ${BLUE}Website:${NC} https://linksub24h.com"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════╣${NC}"
    echo -e "  ${YELLOW}1${NC} Thêm cổng chuyển tiếp mới"
    echo -e "  ${YELLOW}2${NC} Xóa cổng chuyển tiếp hiện có"
    echo -e "  ${YELLOW}3${NC} Sửa cổng chuyển tiếp hiện có"
    echo -e "  ${YELLOW}4${NC} Kiểm tra App có đi qua VPS"
    echo -e "  ${YELLOW}5${NC} Cập nhật hệ thống"
    echo -e "  ${YELLOW}6${NC} Khởi động lại dịch vụ Realm"
    echo -e "  ${YELLOW}7${NC} Gỡ cài đặt toàn bộ"
    echo -e "  ${RED}0${NC} Thoát chương trình"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    read -p "Nhập lựa chọn của bạn: " choice

    case $choice in
        1) add_port ;;
        2) delete_port ;;
        3) edit_config ;;
        4) check_traffic ;;
        5) exec bash "$INSTALL_DIR/scripts/update.sh" ;;
        6) systemctl restart realm && print_info "Đã khởi động lại Realm." && pause ;;
        7) bash "$INSTALL_DIR/scripts/uninstall.sh" ; exit 0 ;;
        0) exit 0 ;;
        *) print_error "Lựa chọn không hợp lệ." && pause ;;
    esac
done