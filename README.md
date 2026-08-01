# Realm Entry Node

Công cụ tự động hóa triển khai và quản lý chuyển tiếp cổng (Port Forwarding) bằng [Realm](https://github.com/zhboner/realm).

## Hướng dẫn cài đặt nhanh

Đăng nhập vào VPS với quyền `root` và chạy duy nhất lệnh sau để tự động cài đặt tất cả:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/Vietnamvpn/realm-entry-node/main/install.sh)
```

## Sử dụng

Sau khi cài đặt xong, bạn có thể gọi menu quản lý tại bất kỳ đâu trong terminal bằng lệnh:

```bash
vvc
```

**Tính năng Menu:**
1. Thêm cổng chuyển tiếp mới.
2. Xóa cổng chuyển tiếp hiện có.
3. Chỉnh sửa file cấu hình `.toml`.
4. Cập nhật mã nguồn và phiên bản Realm.
5. Khởi động lại dịch vụ.
6. Gỡ cài đặt sạch sẽ hệ thống.

## Cấu trúc dự án:

realm-entry-node/
├── install.sh
├── config/
│   └── config.toml
├── systemd/
│   └── realm.service
├── scripts/
│   ├── utils.sh
│   ├── update.sh
│   ├── menu.sh
│   └── uninstall.sh
├── .gitignore
├── LICENSE
└── README.md