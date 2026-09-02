#!/bin/bash

CONFIG_FILE="/etc/realm/config.toml"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[LỖI] Bạn phải chạy kịch bản này bằng quyền root (sudo).${NC}"
        exit 1
    fi
}

print_info() {
    echo -e "${GREEN}[THÔNG BÁO] $1${NC}"
}

print_warn() {
    echo -e "${YELLOW}[CẢNH BÁO] $1${NC}"
}

print_error() {
    echo -e "${RED}[LỖI] $1${NC}"
}

check_service_status() {
    if systemctl is-active --quiet realm; then
        echo -e "Trạng thái: ${GREEN}Active${NC}"
    else
        echo -e "Trạng thái: ${RED}Inactive${NC}"
    fi
}

pause() {
    echo ""
    read -p "Nhấn Enter để quay lại menu..."
}

open_port() {
    local port="$1"
    if command -v ufw >/dev/null 2>&1; then
        ufw status | grep -q "$port/tcp" || ufw allow "$port"/tcp >/dev/null 2>&1
        ufw status | grep -q "$port/udp" || ufw allow "$port"/udp >/dev/null 2>&1
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --zone=public --query-port="$port"/tcp >/dev/null 2>&1 || firewall-cmd --zone=public --add-port="$port"/tcp --permanent >/dev/null 2>&1
        firewall-cmd --zone=public --query-port="$port"/udp >/dev/null 2>&1 || firewall-cmd --zone=public --add-port="$port"/udp --permanent >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    else
        iptables -C INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null || iptables -I INPUT -p tcp --dport "$port" -j ACCEPT
        iptables -C INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null || iptables -I INPUT -p udp --dport "$port" -j ACCEPT
    fi
}

close_port() {
    local port="$1"
    if command -v ufw >/dev/null 2>&1; then
        ufw delete allow "$port"/tcp >/dev/null 2>&1
        ufw delete allow "$port"/udp >/dev/null 2>&1
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --zone=public --remove-port="$port"/tcp --permanent >/dev/null 2>&1
        firewall-cmd --zone=public --remove-port="$port"/udp --permanent >/dev/null 2>&1
        firewall-cmd --reload >/dev/null 2>&1
    else
        iptables -D INPUT -p tcp --dport "$port" -j ACCEPT 2>/dev/null
        iptables -D INPUT -p udp --dport "$port" -j ACCEPT 2>/dev/null
    fi
}

get_random_port() {
    local port
    while true; do
        port=$((RANDOM % 4001 + 2000))
        if ! ss -tuln | grep -q ":$port " && ! grep -q "0.0.0.0:$port" "$CONFIG_FILE"; then
            echo "$port"
            return 0
        fi
    done
}

add_port() {
    echo -e "\n${BLUE}==================== THÊM CỔNG CHUYỂN TIẾP ====================${NC}"
    echo -e "${YELLOW}Lưu ý: Để trống cổng lắng nghe sẽ tự động chọn cổng ngẫu nhiên. Nhập 0 để hủy.${NC}"
    echo -e ""
    read -p "Nhập Cổng lắng nghe trên VPS hiện tại (Nhập 0 để hủy): " listen_port

    if [[ "$listen_port" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    if [[ -z "$listen_port" ]]; then
        listen_port=$(get_random_port)
        print_info "Đã tự động chọn cổng ngẫu nhiên chưa sử dụng: $listen_port"
    fi

    read -p "Nhập IP Node Gốc (Nhập 0 để hủy): " remote_ip
    if [[ "$remote_ip" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    read -p "Nhập Cổng Node Gốc (Nhập 0 để hủy): " remote_port
    if [[ "$remote_port" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    if [[ -z "$remote_ip" || -z "$remote_port" ]]; then
        print_error "IP và Cổng Node Gốc không được để trống."
        pause
        return
    fi

    open_port "$listen_port"

    echo "" >> "$CONFIG_FILE"
    echo "[[endpoints]]" >> "$CONFIG_FILE"
    echo "listen = \"0.0.0.0:$listen_port\"" >> "$CONFIG_FILE"
    echo "remote = \"$remote_ip:$remote_port\"" >> "$CONFIG_FILE"

    systemctl restart realm
    print_info "Đã thêm thành công! Cổng $listen_port đang chuyển tới $remote_ip:$remote_port."
    pause
}

delete_port() {
    echo -e "\n${BLUE}==================== XÓA CỔNG CHUYỂN TIẾP ====================${NC}"
    
    mapfile -t listens < <(grep -E 'listen\s*=' "$CONFIG_FILE" | sed -E 's/.*listen\s*=\s*"([^"]+)".*/\1/')
    mapfile -t remotes < <(grep -E 'remote\s*=' "$CONFIG_FILE" | sed -E 's/.*remote\s*=\s*"([^"]+)".*/\1/')

    if [ ${#listens[@]} -eq 0 ]; then
        print_error "Chưa có cổng chuyển tiếp nào trong cấu hình."
        pause
        return
    fi

    echo -e "${CYAN}Danh sách cổng chuyển tiếp hiện tại:${NC}"
    for i in "${!listens[@]}"; do
        echo -e "  ${YELLOW}$((i+1))${NC}. Cổng lắng nghe: ${GREEN}${listens[$i]}${NC} -> Gốc: ${GREEN}${remotes[$i]}${NC}"
    done

    read -p "Chọn số thứ tự cổng cần xóa (Để trống để xóa tất cả, nhập 0 để hủy): " choice_num

    if [[ "$choice_num" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    if [[ -z "$choice_num" ]]; then
        for item in "${listens[@]}"; do
            listen_port=$(echo "$item" | sed 's/.*://')
            close_port "$listen_port"
        done
        > "$CONFIG_FILE"
        systemctl restart realm
        print_info "Đã xóa toàn bộ cổng chuyển tiếp."
        pause
        return
    fi

    if ! [[ "$choice_num" =~ ^[0-9]+$ ]] || [ "$choice_num" -lt 1 ] || [ "$choice_num" -gt "${#listens[@]}" ]; then
        print_error "Lựa chọn không hợp lệ."
        pause
        return
    fi

    idx=$((choice_num - 1))
    target_listen="${listens[$idx]}"
    listen_port=$(echo "$target_listen" | sed 's/.*://')

    LINE_NUM=$(grep -n -F "listen = \"$target_listen\"" "$CONFIG_FILE" | head -n1 | cut -d: -f1)

    if [ -z "$LINE_NUM" ]; then
        print_error "Không tìm thấy cấu hình trong file."
        pause
        return
    fi

    START_LINE=$(sed -n "1,${LINE_NUM}p" "$CONFIG_FILE" | grep -n "\[\[endpoints\]\]" | tail -n1 | cut -d: -f1)
    END_LINE=$((LINE_NUM + 1))

    if [ -n "$START_LINE" ]; then
        sed -i "${START_LINE},${END_LINE}d" "$CONFIG_FILE"
    fi

    close_port "$listen_port"

    systemctl restart realm
    print_info "Đã xóa hoàn toàn chuyển tiếp và đóng cổng $listen_port."
    pause
}

edit_config() {
    echo -e "\n${BLUE}==================== SỬA CỔNG CHUYỂN TIẾP ====================${NC}"

    mapfile -t listens < <(grep -E 'listen\s*=' "$CONFIG_FILE" | sed -E 's/.*listen\s*=\s*"([^"]+)".*/\1/')
    mapfile -t remotes < <(grep -E 'remote\s*=' "$CONFIG_FILE" | sed -E 's/.*remote\s*=\s*"([^"]+)".*/\1/')

    if [ ${#listens[@]} -eq 0 ]; then
        print_error "Chưa có cổng chuyển tiếp nào trong cấu hình."
        pause
        return
    fi

    echo -e "${CYAN}Danh sách cổng chuyển tiếp hiện tại:${NC}"
    for i in "${!listens[@]}"; do
        echo -e "  ${YELLOW}$((i+1))${NC}. Cổng lắng nghe: ${GREEN}${listens[$i]}${NC} -> Gốc: ${GREEN}${remotes[$i]}${NC}"
    done

    read -p "Chọn số thứ tự cổng cần sửa (Nhập 0 để hủy): " choice_num

    if [[ "$choice_num" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    if ! [[ "$choice_num" =~ ^[0-9]+$ ]] || [ "$choice_num" -lt 1 ] || [ "$choice_num" -gt "${#listens[@]}" ]; then
        print_error "Lựa chọn không hợp lệ."
        pause
        return
    fi

    idx=$((choice_num - 1))
    old_listen="${listens[$idx]}"
    old_remote="${remotes[$idx]}"
    old_port=$(echo "$old_listen" | sed 's/.*://')

    LINE_NUM=$(grep -n -F "listen = \"$old_listen\"" "$CONFIG_FILE" | head -n1 | cut -d: -f1)

    if [ -z "$LINE_NUM" ]; then
        print_error "Không tìm thấy cấu hình trong file."
        pause
        return
    fi

    old_remote_ip=$(echo "$old_remote" | cut -d: -f1)
    old_remote_port=$(echo "$old_remote" | cut -d: -f2)

    read -p "Cổng lắng nghe mới (Mặc định: $old_port, Nhập 0 để hủy): " new_listen_port
    if [[ "$new_listen_port" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    read -p "IP Node Gốc mới (Mặc định: $old_remote_ip, Nhập 0 để hủy): " new_remote_ip
    if [[ "$new_remote_ip" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    read -p "Cổng Node Gốc mới (Mặc định: $old_remote_port, Nhập 0 để hủy): " new_remote_port
    if [[ "$new_remote_port" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    new_listen_port=${new_listen_port:-$old_port}
    new_remote_ip=${new_remote_ip:-$old_remote_ip}
    new_remote_port=${new_remote_port:-$old_remote_port}

    if [ "$old_port" != "$new_listen_port" ]; then
        close_port "$old_port"
        open_port "$new_listen_port"
    else
        open_port "$new_listen_port"
    fi

    sed -i "${LINE_NUM}s|.*|listen = \"0.0.0.0:$new_listen_port\"|" "$CONFIG_FILE"
    sed -i "$((LINE_NUM + 1))s|.*|remote = \"$new_remote_ip:$new_remote_port\"|" "$CONFIG_FILE"

    systemctl restart realm
    print_info "Đã cập nhật thành công cổng $new_listen_port -> $new_remote_ip:$new_remote_port."
    pause
}

check_traffic() {
    echo -e "\n${BLUE}==================== KIỂM TRA LƯU LƯỢNG KẾT NỐI ====================${NC}"
    read -p "Nhập Cổng cần kiểm tra (Nhập 0 để hủy): " check_port

    if [[ "$check_port" == "0" ]]; then
        print_info "Đã hủy thao tác."
        pause
        return
    fi

    if [[ -z "$check_port" ]]; then
        print_error "Cổng không được để trống."
        pause
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
    pause
}