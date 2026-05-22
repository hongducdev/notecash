# NoteCash

Ứng dụng quản lý chi tiêu cá nhân cho Android. Theo dõi tài chính hằng ngày, quét hóa đơn tự động, nhận diện giao dịch ngân hàng.

## ✨ Tính năng

### 🧾 Quản lý chi tiêu

- Ghi chi/thu nhanh với phân loại tự động (Ăn uống, Di chuyển, Mua sắm, Hóa đơn, Giải trí)
- Theo dõi số dư tiền mặt và ngân hàng riêng biệt
- Lịch sử chi tiêu theo ngày, tháng

### 📷 Quét hóa đơn (OCR)

- Chụp ảnh hóa đơn, AI trích xuất tổng tiền và danh sách sản phẩm
- Tối ưu cho hóa đơn Việt Nam (siêu thị, cửa hàng, nhà hàng)
- Lưu theo từng sản phẩm hoặc gộp thành 1 khoản

### 🏦 Nhận diện giao dịch ngân hàng

- Đọc thông báo từ Techcombank, VietinBank, Timo, Cake, MoMo, ZaloPay
- Nhận notification để thêm giao dịch ngay

### 🔁 Nhắc nhở hóa đơn định kỳ

- Quản lý hóa đơn điện, nước, internet, thuê nhà
- Thông báo trước ngày đến hạn
- Tự động tái tạo sau khi thanh toán

### 🔒 Bảo mật & Sao lưu

- Khóa ứng dụng bằng PIN hoặc vân tay/Face ID
- Xuất/nhập file XML để sao lưu
- Dữ liệu lưu cục bộ, không upload lên server

### 🧩 Widget màn hình chính

- Hiển thị số dư và hóa đơn sắp đến hạn
- Nhấn widget để ghi chi tiêu nhanh

## ✅ Yêu cầu

- Android 6.0+ (API 23)
- Quyền: Camera, Thông báo, Notification Listener (tùy chọn)

## ⚙️ Cài đặt

### 📦 Từ Release

1. Tải APK từ [Releases](https://github.com/hongducdev/notecash/releases)
2. Cài đặt trên thiết bị Android
3. Thiết lập số dư ban đầu

### 🛠️ Build từ source

```bash
git clone https://github.com/hongducdev/notecash.git
cd notecash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

## 🧰 Công nghệ

| Component        | Library                        |
| ---------------- | ------------------------------ |
| Framework        | Flutter 3.x                    |
| State Management | Riverpod                       |
| Database         | Isar                           |
| Routing          | GoRouter                       |
| OCR              | Google ML Kit Text Recognition |
| Notifications    | flutter_local_notifications    |
| Home Widget      | home_widget                    |

## 🤝 Đóng góp

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/TinhNangMoi`)
3. Commit thay đổi
4. Push và tạo Pull Request

## 📄 Giấy phép

MIT License

## 👤 Tác giả

**Hong Duc** - [@hongducdev](https://github.com/hongducdev)
