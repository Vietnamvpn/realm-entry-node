#!/bin/bash

REPO_URL="https://github.com/Vietnamvpn/realm-entry-node.git"
INSTALL_DIR="/opt/realm-entry-node"

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[LỖI] Bạn phải chạy lệnh này bằng quyền root (sudo).${NC}"
    exit 1
fi

echo -e "${GREEN}[THÔNG BÁO] Bắt đầu cài đặt hệ thống Realm...${NC}"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

echo -e "${GREEN}[THÔNG BÁO] Kiểm tra hệ điều hành ($OS) và cài đặt tường lửa...${NC}"

case "$OS" in
    ubuntu|debian)
        apt-get update -y -q
        apt-get install -y -q git curl wget tar ufw
        systemctl enable ufw
        systemctl start ufw
        ufw allow 22/tcp
        ufw --force enable
        ;;
    centos|rhel|almalinux|rocky|fedora)
        if command -v dnf >/dev/null 2>&1; then
            PKG_MAN="dnf"
        else
            PKG_MAN="yum"
        fi
        $PKG_MAN update -y -q
        $PKG_MAN install -y -q git curl wget tar firewalld
        systemctl enable firewalld
        systemctl start firewalld
        firewall-cmd --permanent --add-service=ssh
        firewall-cmd --reload
        ;;
    *)
        if command -v apt-get >/dev/null 2>&1; then
            apt-get update -y -q
            apt-get install -y -q git curl wget tar ufw
            systemctl enable ufw
            systemctl start ufw
            ufw allow 22/tcp
            ufw --force enable
        elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
            PKG_MAN="yum"
            command -v dnf >/dev/null 2>&1 && PKG_MAN="dnf"
            $PKG_MAN update -y -q
            $PKG_MAN install -y -q git curl wget tar firewalld
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --permanent --add-service=ssh
            firewall-cmd --reload
        else
            echo -e "${RED}[LỖI] Hệ điều hành không hỗ trợ tự động cài tường lửa.${NC}"
            exit 1
        fi
        ;;
esac

if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
fi
git clone "$REPO_URL" "$INSTALL_DIR" -q

REALM_URL="https://github.com/zhboner/realm/releases/latest/download/realm-x86_64-unknown-linux-musl.tar.gz"
cd /tmp || exit
wget -qO realm.tar.gz "$REALM_URL"
tar -xvf realm.tar.gz
mv realm /usr/local/bin/realm
chmod +x /usr/local/bin/realm
rm -f realm.tar.gz

mkdir -p /etc/realm
cp "$INSTALL_DIR/config/config.toml" /etc/realm/config.toml

cp "$INSTALL_DIR/systemd/realm.service" /etc/systemd/system/realm.service
systemctl daemon-reload
systemctl enable realm
systemctl start realm

chmod +x "$INSTALL_DIR/scripts/"*.sh

ln -sf "$INSTALL_DIR/scripts/menu.sh" /usr/local/bin/vvc
chmod +x /usr/local/bin/vvc

echo -e "${GREEN}[THÔNG BÁO] Cài đặt thành công!${NC}"
echo -e "${GREEN}[THÔNG BÁO] Gõ lệnh '${CYAN}vvc${GREEN}' bất cứ lúc nào để mở Menu quản lý.${NC}"