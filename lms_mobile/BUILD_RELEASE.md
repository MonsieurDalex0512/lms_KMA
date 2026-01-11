# HƯỚNG DẪN BUILD RELEASE APK VỚI OBFUSCATION

## Tổng quan

Hệ thống đã được cấu hình để build APK release với obfuscation tự động. Obfuscation sẽ:
- Bảo vệ mã nguồn khỏi reverse engineering
- Giảm kích thước APK (loại bỏ code không sử dụng)
- Tối ưu hóa performance

## Cách Build

### Windows (PowerShell)

```powershell
cd lms_mobile
.\build-release.ps1
```

### Linux/Mac (Bash)

```bash
cd lms_mobile
chmod +x build-release.sh
./build-release.sh
```

### Build thủ công

```bash
cd lms_mobile
flutter clean
flutter pub get
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

### Build App Bundle (cho Google Play)

```bash
flutter build appbundle --release --obfuscate --split-debug-info=./debug-info
```

## Kết quả Build

Sau khi build thành công, bạn sẽ có:

1. **APK file**: 
   - `build/app/outputs/flutter-apk/app-release.apk`
   - File này đã được obfuscate và tối ưu

2. **Debug info** (để map lại crash reports):
   - `./debug-info/`
   - Chứa các file symbols để deobfuscate

3. **Mapping file** (QUAN TRỌNG):
   - `android/app/build/outputs/mapping/release/mapping.txt`
   - File này map tên gốc với tên đã obfuscate
   - **CẦN LƯU TRỮ AN TOÀN** (không commit vào public repo)

## Lưu ý quan trọng

### Mapping File

File `mapping.txt` rất quan trọng vì:
- Dùng để map lại crash reports từ obfuscated code
- Nếu mất file này, không thể đọc được crash reports
- Không được chia sẻ công khai (kẻ tấn công có thể dùng để reverse)

**Cách lưu trữ:**
- Lưu trong CI/CD pipeline
- Backup vào private repository
- Upload lên Firebase Crashlytics (nếu dùng) để tự động map crash reports

### Kiểm tra Obfuscation

Để kiểm tra obfuscation đã hoạt động:

```bash
# Decompile APK (cần cài jadx)
jadx app-release.apk -d output/

# Kiểm tra trong output/:
# - Tên class/method đã bị đổi thành a, b, c...
# - Không còn tên biến có ý nghĩa
```

### Troubleshooting

**Lỗi build:**
- Kiểm tra ProGuard rules trong `android/app/proguard-rules.pro`
- Có thể cần thêm rules cho các package mới

**App crash sau khi build:**
- Kiểm tra logs để xem class nào bị thiếu
- Thêm `-keep` rules cho class đó trong `proguard-rules.pro`
- Test lại

**Kích thước APK không giảm:**
- Kiểm tra `isShrinkResources = true` trong `build.gradle.kts`
- Kiểm tra resources không sử dụng

## Cấu hình

### File cấu hình

1. **`android/app/build.gradle.kts`**:
   - `isMinifyEnabled = true` - Bật obfuscation
   - `isShrinkResources = true` - Loại bỏ resources không dùng
   - `proguardFiles(...)` - Chỉ định ProGuard rules

2. **`android/app/proguard-rules.pro`**:
   - Định nghĩa các class không được obfuscate
   - Rules cho các thư viện sử dụng

### Thêm ProGuard Rules mới

Khi thêm package mới, có thể cần thêm rules vào `proguard-rules.pro`:

```proguard
# Ví dụ: Thêm rule cho package mới
-keep class new_package.** { *; }
```

Tham khảo documentation của package để biết rules cần thiết.

## So sánh Debug vs Release

| Tính năng | Debug | Release (Obfuscated) |
|-----------|-------|----------------------|
| Kích thước APK | ~50-60 MB | ~25-30 MB |
| Tên class/method | Rõ ràng | a, b, c... |
| Code optimization | Không | Có |
| Debug symbols | Có | Tách riêng |
| Reverse engineering | Dễ | Khó |

## Checklist trước khi release

- [ ] Build thành công với obfuscation
- [ ] Test đầy đủ chức năng app
- [ ] Kiểm tra kích thước APK giảm
- [ ] Lưu trữ `mapping.txt` an toàn
- [ ] Decompile và xác minh obfuscation
- [ ] Cấu hình upload `mapping.txt` lên Crashlytics (nếu dùng)

---

**Lưu ý**: Luôn test kỹ release build trước khi publish lên store!



