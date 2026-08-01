#!/bin/bash

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