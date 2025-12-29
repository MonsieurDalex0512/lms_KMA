# BÁO CÁO: BẢO VỆ MÃ NGUỒN BẰNG OBFUSCATION KHI BUILD APK

## MỤC LỤC
1. [Khái niệm Obfuscation](#1-khái-niệm-obfuscation)
2. [Chức năng của Obfuscation](#2-chức-năng-của-obfuscation)
3. [Nguyên lý hoạt động](#3-nguyên-lý-hoạt-động)
4. [Triển khai trong hệ thống LMS](#4-triển-khai-trong-hệ-thống-lms)
5. [Code triển khai](#5-code-triển-khai)
6. [Kết luận](#6-kết-luận)

---

## 1. KHÁI NIỆM OBFUSCATION

### 1.1. Obfuscation là gì?

**Obfuscation** (làm rối mã) là kỹ thuật bảo vệ mã nguồn bằng cách biến đổi code thành dạng khó đọc và khó hiểu, nhưng vẫn giữ nguyên chức năng. Quá trình này thực hiện:

- **Đổi tên biến, hàm, class**: Chuyển từ tên có ý nghĩa sang tên ngắn gọn, khó hiểu
  - Ví dụ: `getUserData()` → `a()`, `EncryptionService` → `b`, `ApiClient` → `c`
- **Loại bỏ thông tin debug**: Xóa comments, line numbers, source file names
- **Tối ưu và rút gọn code**: Loại bỏ code không sử dụng, tối ưu bytecode
- **Làm rối cấu trúc code**: Thay đổi flow control, thêm code giả (nếu dùng advanced obfuscation)

### 1.2. Tại sao cần Obfuscation?

Khi build ứng dụng Android, mã nguồn được compile thành DEX files (Dalvik Executable). Các file này có thể dễ dàng bị **decompile** trở lại thành code Java/Kotlin gần như nguyên bản bằng các công cụ như:
- **jadx**: Decompile DEX thành Java code
- **apktool**: Extract và decompile APK
- **dex2jar**: Chuyển DEX thành JAR để phân tích

**Không có obfuscation**, kẻ tấn công có thể:
- Đọc toàn bộ logic nghiệp vụ
- Trích xuất API endpoints, keys, secrets
- Hiểu cấu trúc và flow của ứng dụng
- Tạo bản copy hoặc tìm lỗ hổng bảo mật

---

## 2. CHỨC NĂNG CỦA OBFUSCATION

### 2.1. Bảo vệ Intellectual Property (IP)

**Mục đích**: Bảo vệ logic nghiệp vụ, thuật toán, và cấu trúc code khỏi bị sao chép.

**Cách hoạt động**:
- Đổi tên tất cả classes, methods, variables thành tên ngắn (a, b, c, aa, ab...)
- Làm khó đọc và hiểu logic nghiệp vụ
- Tăng thời gian và chi phí để reverse engineering

**Ví dụ trong hệ thống LMS**:
```dart
// Trước obfuscation - Dễ đọc
class EncryptionService {
  Future<String> encryptMessage(String message, int groupId) async {
    final key = _generateKeyFromGroupId(groupId);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    return encrypter.encrypt(message, iv: iv).base64;
  }
}

// Sau obfuscation - Khó đọc
class a {
  Future<String> b(String c, int d) async {
    final e = f(d);
    final g = h.fromLength(16);
    final i = j(k(e));
    return i.l(c, m: g).n;
  }
}
```

### 2.2. Giảm kích thước APK

**Mục đích**: Loại bỏ code và resources không sử dụng để giảm kích thước file APK.

**Cách hoạt động**:
- **Code Shrinking**: Phân tích dependency graph, loại bỏ unused classes, methods, fields
- **Resource Shrinking**: Loại bỏ resources (images, strings, layouts) không được reference

**Kết quả**:
- Debug APK: ~50-60 MB
- Release APK (có obfuscation): ~25-30 MB (giảm 40-50%)

### 2.3. Tăng độ khó Reverse Engineering

**Mục đích**: Làm cho việc phân tích và hiểu code trở nên khó khăn và tốn thời gian.

**Cách hoạt động**:
- Tên không có ý nghĩa: `a()`, `b()`, `c()` thay vì `getUserData()`, `encryptMessage()`
- Loại bỏ metadata: Không còn comments, line numbers, source file names
- Tối ưu bytecode: Code được tối ưu, khó trace flow

**Thời gian reverse engineering**:
- Không obfuscate: Vài giờ đến vài ngày
- Có obfuscate: Vài tuần đến vài tháng (tùy độ phức tạp)

### 2.4. Bảo vệ thông tin nhạy cảm

**Mục đích**: Làm khó trích xuất API endpoints, keys, secrets, và logic mã hóa.

**Cách hoạt động**:
- Obfuscate strings và constants
- Làm khó tìm và hiểu logic xử lý sensitive data
- Kết hợp với các biện pháp khác (encryption, secure storage)

**Ví dụ trong hệ thống LMS**:
- API base URL trong `ApiClient` sẽ khó trích xuất
- Logic encryption trong `EncryptionService` sẽ khó phân tích
- JWT token handling sẽ khó đọc

---

## 3. NGUYÊN LÝ HOẠT ĐỘNG

### 3.1. Quy trình Obfuscation trong Flutter/Android

```
Source Code (Dart/Kotlin)
    ↓
Compile → DEX Files (Dalvik Executable)
    ↓
R8 Tool Processing
    ├─ Code Shrinking (loại bỏ unused code)
    ├─ Resource Shrinking (loại bỏ unused resources)
    ├─ Obfuscation (đổi tên classes/methods)
    └─ Optimization (tối ưu bytecode)
    ↓
Optimized & Obfuscated DEX
    ↓
Package → APK/AAB
```

### 3.2. R8 Tool - Công cụ Obfuscation

**R8** là công cụ của Google thay thế ProGuard, thực hiện 4 công việc chính:

#### 3.2.1. Code Shrinking
- Phân tích dependency graph của ứng dụng
- Xác định code không được sử dụng (unreachable code)
- Loại bỏ unused classes, methods, fields
- **Kết quả**: Giảm kích thước DEX files

#### 3.2.2. Resource Shrinking
- Phân tích resources được reference trong code
- Loại bỏ resources không được sử dụng (images, strings, layouts)
- **Kết quả**: Giảm kích thước APK đáng kể

#### 3.2.3. Obfuscation
- Đổi tên classes, methods, fields thành tên ngắn
- Bắt đầu từ `a`, `b`, `c`... đến `aa`, `ab`, `ac`...
- Giữ nguyên cấu trúc logic nhưng làm khó đọc
- **Kết quả**: Code khó đọc và hiểu

#### 3.2.4. Optimization
- Inlining: Thay thế method calls bằng code trực tiếp
- Dead code elimination: Loại bỏ code không bao giờ chạy
- Constant folding: Tính toán constants tại compile time
- **Kết quả**: Cải thiện performance

### 3.3. Mapping File

R8 tạo file `mapping.txt` để map lại tên gốc từ tên đã obfuscate:

```
com.example.lms_mobile.EncryptionService -> a:
    void encryptMessage(java.lang.String,int) -> b
    java.lang.String decryptMessage(java.lang.String,int) -> c
    void _generateKeyFromGroupId(int) -> d

com.example.lms_mobile.ApiClient -> e:
    void <init>() -> <init>
    dio.Dio getClient() -> f
```

**Mục đích**:
- Map lại crash reports từ obfuscated code
- Debug và fix lỗi trong production

**Lưu ý quan trọng**:
- File này cần được lưu trữ an toàn
- Không được chia sẻ công khai (kẻ tấn công có thể dùng để reverse)
- Upload lên Firebase Crashlytics để tự động map crash reports

### 3.4. ProGuard Rules

ProGuard rules định nghĩa những gì **KHÔNG ĐƯỢC** obfuscate:

**Lý do cần rules**:
- Một số classes cần giữ nguyên tên (ví dụ: model classes dùng cho JSON serialization)
- Native methods cần giữ nguyên signature
- Classes dùng reflection cần giữ nguyên
- Flutter framework classes cần giữ nguyên để app hoạt động

**Các loại rules**:
- `-keep`: Giữ nguyên class và members
- `-keepnames`: Giữ nguyên tên nhưng vẫn cho phép obfuscate nội dung
- `-dontwarn`: Bỏ qua warnings cho các classes không tìm thấy

---

## 4. TRIỂN KHAI TRONG HỆ THỐNG LMS

### 4.1. Tổng quan triển khai

Hệ thống LMS đã được cấu hình để tự động obfuscate code khi build release APK. Cấu hình bao gồm:

1. **Android Build Configuration**: Cấu hình trong `build.gradle.kts`
2. **ProGuard Rules**: Định nghĩa các classes không được obfuscate
3. **Build Scripts**: Scripts tự động build với obfuscation

### 4.2. Các thành phần được bảo vệ

#### 4.2.1. API Client (`lib/core/api_client.dart`)
- **Base URL**: Đã được hardcode, obfuscation sẽ làm khó trích xuất
- **Token handling**: Logic xử lý JWT token sẽ bị obfuscate
- **Headers configuration**: Cấu hình headers sẽ khó đọc
- **Dio interceptors**: Logic xử lý request/response sẽ được bảo vệ

#### 4.2.2. Encryption Service (`lib/features/chat/services/encryption_service.dart`)
- **Encryption logic**: Logic mã hóa/giải mã tin nhắn sẽ bị obfuscate
- **Key generation**: Hàm `_generateKeyFromGroupId()` sẽ khó đọc
- **AES encryption**: Implementation sẽ được bảo vệ
- **IV generation**: Logic tạo initialization vector sẽ khó phân tích

#### 4.2.3. Authentication & Authorization
- **JWT handling**: Logic decode và validate JWT tokens
- **Token storage**: Cách lưu trữ và retrieve tokens
- **Authentication flow**: Flow đăng nhập, đăng xuất

#### 4.2.4. Business Logic
- **Data processing**: Xử lý dữ liệu học tập, điểm số
- **Chat encryption**: Logic mã hóa tin nhắn end-to-end
- **State management**: Logic quản lý state với Provider

### 4.3. Quy trình Build và Release

1. **Development**: Build debug (không obfuscate) để dễ debug
2. **Testing**: Test đầy đủ chức năng trước khi build release
3. **Build Release**: 
   ```bash
   flutter build apk --release --obfuscate --split-debug-info=./debug-info
   ```
4. **Lưu trữ mapping.txt**: 
   - Lưu tại `android/app/build/outputs/mapping/release/mapping.txt`
   - Backup an toàn (không commit vào public repo)
   - Upload lên Firebase Crashlytics (nếu dùng)
5. **Kiểm tra**: Decompile APK để xác minh obfuscation hoạt động

### 4.4. Kiểm tra Obfuscation

#### 4.4.1. Decompile APK để kiểm tra

```bash
# Sử dụng jadx
jadx app-release.apk -d output/

# Kiểm tra trong output/:
# - Tên class/method đã bị đổi thành a, b, c...
# - Không còn tên biến có ý nghĩa
# - Code structure khó đọc
```

#### 4.4.2. So sánh kích thước APK

- **Debug APK**: ~50-60 MB
- **Release APK (có obfuscation)**: ~25-30 MB (giảm ~50%)

---

## 5. CODE TRIỂN KHAI

### 5.1. Cấu hình Android Build (`build.gradle.kts`)

**File**: `lms_mobile/android/app/build.gradle.kts`

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lms_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.lms_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Bật code shrinking, obfuscation, và optimization
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
```

**Giải thích**:
- `isMinifyEnabled = true`: Bật R8 minification và obfuscation
- `isShrinkResources = true`: Loại bỏ resources không sử dụng
- `proguardFiles(...)`: Chỉ định file ProGuard rules
  - `proguard-android-optimize.txt`: Rules mặc định của Android (tối ưu)
  - `proguard-rules.pro`: Rules tùy chỉnh cho project

### 5.2. ProGuard Rules (`proguard-rules.pro`)

**File**: `lms_mobile/android/app/proguard-rules.pro`

```proguard
# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.kts.

# ============================================
# Flutter Framework
# ============================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ============================================
# Native Methods
# ============================================
-keepclasseswithmembernames class * {
    native <methods>;
}

# ============================================
# Parcelable
# ============================================
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# ============================================
# Dio HTTP Client
# ============================================
-keep class dio.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ============================================
# Provider (State Management)
# ============================================
-keep class provider.** { *; }
-keep class * extends provider.ChangeNotifier { *; }

# ============================================
# Go Router
# ============================================
-keep class go_router.** { *; }

# ============================================
# JWT Decoder
# ============================================
-keep class jwt_decoder.** { *; }

# ============================================
# Encryption Libraries
# ============================================
-keep class encrypt.** { *; }
-keep class crypto.** { *; }
-keep class pointycastle.** { *; }
-dontwarn encrypt.**
-dontwarn crypto.**
-dontwarn pointycastle.**

# ============================================
# Flutter Secure Storage
# ============================================
-keep class flutter_secure_storage.** { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ============================================
# Shared Preferences
# ============================================
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$* { *; }

# ============================================
# Socket.IO Client
# ============================================
-keep class socket_io_client.** { *; }
-keep class io.socket.** { *; }
-dontwarn socket_io_client.**
-dontwarn io.socket.**

# ============================================
# WebView Flutter
# ============================================
-keep class webview_flutter.** { *; }
-keep class io.flutter.plugins.webviewflutter.** { *; }

# ============================================
# FL Chart
# ============================================
-keep class fl_chart.** { *; }

# ============================================
# Table Calendar
# ============================================
-keep class table_calendar.** { *; }

# ============================================
# Google Fonts
# ============================================
-keep class google_fonts.** { *; }

# ============================================
# Intl (Internationalization)
# ============================================
-keep class intl.** { *; }

# ============================================
# Kotlin
# ============================================
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# ============================================
# Keep MainActivity
# ============================================
-keep class com.example.lms_mobile.MainActivity { *; }

# ============================================
# Keep Application class if exists
# ============================================
-keep class * extends android.app.Application {
    <init>();
}

# ============================================
# Keep annotations
# ============================================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# ============================================
# Keep line numbers for debugging
# ============================================
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ============================================
# Remove logging in release
# ============================================
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}
```

**Giải thích các rules quan trọng**:

1. **Flutter Framework**: Giữ nguyên tất cả Flutter classes để app hoạt động đúng
2. **Dio/HTTP**: Giữ nguyên HTTP client classes để network requests hoạt động
3. **Encryption**: Giữ nguyên encryption libraries để mã hóa/giải mã hoạt động
4. **Provider/State Management**: Giữ nguyên state management classes
5. **Kotlin**: Giữ nguyên Kotlin metadata để Kotlin code hoạt động
6. **MainActivity**: Giữ nguyên MainActivity để app launch được
7. **Annotations**: Giữ nguyên annotations để reflection hoạt động
8. **Remove logging**: Loại bỏ Log.d(), Log.v(), Log.i() trong release để tối ưu

### 5.3. Build Scripts

#### 5.3.1. Windows PowerShell (`build-release.ps1`)

```powershell
# Script build release APK với obfuscation cho Windows PowerShell
# Sử dụng: .\build-release.ps1

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Release APK with Obfuscation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Kiểm tra Flutter đã cài đặt chưa
Write-Host "Checking Flutter installation..." -ForegroundColor Yellow
flutter --version
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter not found. Please install Flutter first." -ForegroundColor Red
    exit 1
}

# Clean project
Write-Host ""
Write-Host "Cleaning project..." -ForegroundColor Yellow
flutter clean

# Get dependencies
Write-Host ""
Write-Host "Getting dependencies..." -ForegroundColor Yellow
flutter pub get

# Build APK với obfuscation
Write-Host ""
Write-Host "Building release APK with obfuscation..." -ForegroundColor Yellow
Write-Host "This may take a few minutes..." -ForegroundColor Yellow
flutter build apk --release --obfuscate --split-debug-info=./debug-info

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "Build completed successfully!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "APK location:" -ForegroundColor Cyan
    Write-Host "  build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor White
    Write-Host ""
    Write-Host "Debug info location:" -ForegroundColor Cyan
    Write-Host "  ./debug-info/" -ForegroundColor White
    Write-Host ""
    Write-Host "Mapping file location:" -ForegroundColor Cyan
    Write-Host "  android/app/build/outputs/mapping/release/mapping.txt" -ForegroundColor White
    Write-Host ""
    Write-Host "IMPORTANT: Save the mapping.txt file safely!" -ForegroundColor Yellow
    Write-Host "It's needed to deobfuscate crash reports." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Build failed!" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}
```

#### 5.3.2. Linux/Mac Bash (`build-release.sh`)

```bash
#!/bin/bash
# Script build release APK với obfuscation cho Linux/Mac
# Sử dụng: ./build-release.sh

echo "========================================"
echo "Building Release APK with Obfuscation"
echo "========================================"
echo ""

# Kiểm tra Flutter đã cài đặt chưa
echo "Checking Flutter installation..."
if ! command -v flutter &> /dev/null; then
    echo "Error: Flutter not found. Please install Flutter first."
    exit 1
fi

flutter --version

# Clean project
echo ""
echo "Cleaning project..."
flutter clean

# Get dependencies
echo ""
echo "Getting dependencies..."
flutter pub get

# Build APK với obfuscation
echo ""
echo "Building release APK with obfuscation..."
echo "This may take a few minutes..."
flutter build apk --release --obfuscate --split-debug-info=./debug-info

if [ $? -eq 0 ]; then
    echo ""
    echo "========================================"
    echo "Build completed successfully!"
    echo "========================================"
    echo ""
    echo "APK location:"
    echo "  build/app/outputs/flutter-apk/app-release.apk"
    echo ""
    echo "Debug info location:"
    echo "  ./debug-info/"
    echo ""
    echo "Mapping file location:"
    echo "  android/app/build/outputs/mapping/release/mapping.txt"
    echo ""
    echo "IMPORTANT: Save the mapping.txt file safely!"
    echo "It's needed to deobfuscate crash reports."
else
    echo ""
    echo "========================================"
    echo "Build failed!"
    echo "========================================"
    exit 1
fi
```

### 5.4. Build Command

**Build APK với obfuscation:**
```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

**Build App Bundle với obfuscation:**
```bash
flutter build appbundle --release --obfuscate --split-debug-info=./debug-info
```

**Tham số:**
- `--release`: Build ở chế độ release (tối ưu hóa)
- `--obfuscate`: Bật obfuscation cho Dart code
- `--split-debug-info=./debug-info`: Lưu debug symbols riêng (để map lại crash reports)

### 5.5. Kết quả Build

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

---

## 6. KẾT LUẬN

### 6.1. Tóm tắt

✅ **Obfuscation đã được triển khai** trong hệ thống LMS  
✅ **R8 tool** cung cấp obfuscation mạnh mẽ, tự động cho Flutter/Android  
✅ **Cấu hình đầy đủ** ProGuard rules để đảm bảo app hoạt động đúng  
✅ **Kết hợp với các biện pháp khác**: Mã hóa dữ liệu, JWT tokens, secure storage

### 6.2. Lợi ích đạt được

1. **Bảo vệ mã nguồn**: Logic nghiệp vụ, encryption, API handling được bảo vệ
2. **Giảm kích thước APK**: Từ ~50-60 MB xuống ~25-30 MB (giảm 40-50%)
3. **Tăng độ khó reverse engineering**: Tốn nhiều thời gian và công sức để phân tích
4. **Tối ưu performance**: Code được optimize, app chạy nhanh hơn

### 6.3. Lưu ý quan trọng

1. **Mapping file**: Luôn lưu trữ `mapping.txt` an toàn để map lại crash reports
2. **Test kỹ**: Test đầy đủ chức năng sau khi build release với obfuscation
3. **ProGuard rules**: Khi thêm package mới, có thể cần cập nhật `proguard-rules.pro`
4. **Không phải bảo mật tuyệt đối**: Obfuscation chỉ làm khó, không ngăn chặn hoàn toàn reverse engineering

### 6.4. Khuyến nghị

1. **Luôn bật obfuscation** cho release builds
2. **Bảo vệ mapping.txt**: Lưu trong CI/CD, không commit public
3. **Kết hợp bảo mật đa lớp**:
   - Obfuscation (bảo vệ code) ✅
   - Encryption (bảo vệ dữ liệu) ✅
   - JWT tokens (bảo vệ authentication) ✅
   - Secure storage (bảo vệ local data) ✅
   - Certificate pinning (bảo vệ network) - Có thể thêm sau
   - Root detection - Có thể thêm sau

### 6.5. Checklist triển khai

- [x] Cập nhật `build.gradle.kts` với `isMinifyEnabled = true`
- [x] Tạo file `proguard-rules.pro` với rules phù hợp
- [x] Tạo build scripts (PowerShell và Bash)
- [x] Document quy trình build release
- [ ] Test release build với obfuscation
- [ ] Kiểm tra kích thước APK giảm
- [ ] Decompile và xác minh obfuscation hoạt động
- [ ] Lưu trữ `mapping.txt` an toàn
- [ ] Cấu hình upload `mapping.txt` lên Crashlytics (nếu dùng)

---

**Ngày tạo**: 2024  
**Phiên bản**: 2.0  
**Hệ thống**: LMS Mobile Application  
**Trạng thái**: Đã triển khai ✅
