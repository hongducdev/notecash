# NoteCash

Ung dung quan ly chi tieu ca nhan cho Android. Theo doi tai chinh hang ngay, quet hoa don tu dong, nhan dien giao dich ngan hang.

## Tinh nang

### Quan ly chi tieu
- Ghi chi/thu nhanh voi phan loai tu dong (An uong, Di chuyen, Mua sam, Hoa don, Giai tri)
- Theo doi so du tien mat va ngan hang rieng biet
- Lich su chi tieu theo ngay, thang

### Quet hoa don (OCR)
- Chup anh hoa don, AI trich xuat tong tien va danh sach san pham
- Toi uu cho hoa don Viet Nam (sieu thi, cua hang, nha hang)
- Luu theo tung san pham hoac gop thanh 1 khoan

### Nhan dien giao dich ngan hang
- Doc thong bao tu Techcombank, Vietinbank, Timo, Cake, Momo, ZaloPay
- Nhan notification de them giao dich ngay

### Nhac nho hoa don dinh ky
- Quan ly hoa don dien, nuoc, internet, thue nha
- Thong bao truoc ngay den han
- Tu dong tai tao sau khi thanh toan

### Bao mat & Sao luu
- Khoa ung dung bang PIN hoac van tay/Face ID
- Xuat/nhap file XML de backup
- Du lieu luu cuc bo, khong upload len server

### Widget man hinh chinh
- Hien thi so du va hoa don sap den han
- Nhan widget de ghi chi tieu nhanh

## Yeu cau

- Android 6.0+ (API 23)
- Quyen: Camera, Thong bao, Notification Listener (tuy chon)

## Cai dat

### Tu Release
1. Tai APK tu [Releases](https://github.com/hongducdev/notecash/releases)
2. Cai dat tren thiet bi Android
3. Thiet lap so du ban dau

### Build tu source
```bash
git clone https://github.com/hongducdev/notecash.git
cd notecash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

## Cong nghe

| Component | Library |
|-----------|---------|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Database | Isar |
| Routing | GoRouter |
| OCR | Google ML Kit Text Recognition |
| Notifications | flutter_local_notifications |
| Home Widget | home_widget |

## Dong gop

1. Fork repository
2. Tao branch moi (`git checkout -b feature/TinhNangMoi`)
3. Commit thay doi
4. Push va tao Pull Request

## Giay phep

MIT License

## Tac gia

**Hong Duc** - [@hongducdev](https://github.com/hongducdev)
