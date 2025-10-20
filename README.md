# BookSell Flutter

Ứng dụng bán sách trực tuyến được phát triển bằng Flutter, migrate từ ứng dụng Android gốc.

## Tính năng chính

### Người dùng
- ✅ Đăng ký/Đăng nhập với Firebase Authentication
- ✅ Duyệt sản phẩm theo danh mục
- ✅ Tìm kiếm sản phẩm
- ✅ Xem chi tiết sản phẩm
- ✅ Thêm vào giỏ hàng (SQLite local)
- ✅ Xem lịch sử đơn hàng
- ✅ AI Chatbot với Gemini API
- ✅ Đặt hàng qua chat
- ✅ Quản lý tài khoản

### Admin (Sẽ được implement)
- ⏳ Quản lý sản phẩm
- ⏳ Quản lý danh mục
- ⏳ Quản lý đơn hàng
- ⏳ Quản lý voucher
- ⏳ Thống kê doanh thu
- ⏳ Quản lý phản hồi

## Công nghệ sử dụng

- **Flutter**: Framework chính
- **Firebase**: Authentication, Realtime Database
- **SQLite**: Local database cho giỏ hàng
- **Provider**: State management
- **Gemini API**: AI Chatbot
- **ZaloPay**: Thanh toán (sẽ implement)

## Cài đặt

### 1. Clone repository
```bash
git clone <repository-url>
cd BookSellFlutter
```

### 2. Cài đặt dependencies
```bash
flutter pub get
```

### 3. Cấu hình Firebase
1. Copy file `google-services.json` từ project Android gốc vào `android/app/`
2. Cấu hình Firebase project cho Flutter

### 4. Cấu hình Gemini API
1. Mở file `lib/constants/config.dart`
2. Thay thế `YOUR_GEMINI_API_KEY_HERE` bằng API key thực tế
3. Lấy API key tại: https://aistudio.google.com/app/apikey

### 5. Chạy ứng dụng
```bash
flutter run
```

## Cấu trúc project

```
lib/
├── constants/          # Constants và config
├── models/            # Data models
├── providers/         # State management
├── screens/           # UI screens
├── services/          # Business logic
├── widgets/           # Reusable widgets
└── main.dart          # Entry point
```

## Models

- `Product`: Sản phẩm sách
- `User`: Thông tin người dùng
- `Order`: Đơn hàng
- `Category`: Danh mục sách
- `Address`: Địa chỉ giao hàng
- `Voucher`: Mã giảm giá
- `Feedback`: Phản hồi khách hàng
- `Message`: Tin nhắn chat

## Services

- `FirebaseService`: Kết nối Firebase
- `DatabaseService`: SQLite local database
- `GeminiService`: AI Chatbot
- `ZaloPayService`: Thanh toán (sẽ implement)

## Providers

- `AuthProvider`: Quản lý đăng nhập
- `CartProvider`: Quản lý giỏ hàng
- `ProductProvider`: Quản lý sản phẩm
- `OrderProvider`: Quản lý đơn hàng
- `ChatProvider`: Quản lý chat

## Screens chính

### User Screens
- `SplashScreen`: Màn hình khởi động
- `LoginScreen`: Đăng nhập
- `RegisterScreen`: Đăng ký
- `MainScreen`: Màn hình chính với BottomNavigation
- `HomeTab`: Trang chủ
- `ProductTab`: Danh sách sản phẩm
- `HistoryTab`: Lịch sử đơn hàng
- `AccountTab`: Tài khoản
- `ChatScreen`: AI Chatbot
- `ProductDetailScreen`: Chi tiết sản phẩm

### Admin Screens (Sẽ implement)
- `AdminMainScreen`: Màn hình admin chính
- `AdminProductScreen`: Quản lý sản phẩm
- `AdminOrderScreen`: Quản lý đơn hàng
- `AdminVoucherScreen`: Quản lý voucher
- Và nhiều screens khác...

## Tính năng AI Chat

Chatbot được tích hợp Gemini API với các tính năng:

- Trả lời câu hỏi về sản phẩm
- Tư vấn sách phù hợp
- Kiểm tra đơn hàng
- Đặt hàng trực tiếp qua chat
- Xem voucher và khuyến mãi
- Phân tích sản phẩm bán chạy

## ZaloPay Integration (Sẽ implement)

- Platform Channels để gọi native SDK
- Tạo đơn hàng thanh toán
- Xử lý callback
- Deep link handling

## Database Schema

### SQLite (Local)
- `product`: Sản phẩm cho offline cart
- `cart`: Giỏ hàng local

### Firebase (Remote)
- `product`: Sản phẩm
- `category`: Danh mục
- `order`: Đơn hàng
- `voucher`: Mã giảm giá
- `feedback`: Phản hồi
- `admin`: Thông tin admin

## Lưu ý

1. **API Key**: Cần cập nhật Gemini API key trong `config.dart`
2. **Firebase**: Cần cấu hình Firebase project
3. **ZaloPay**: Cần implement Platform Channels
4. **Admin**: Các tính năng admin chưa được implement
5. **Assets**: Cần copy images từ project Android gốc

## Roadmap

- [ ] Implement ZaloPay payment
- [ ] Implement admin screens
- [ ] Add push notifications
- [ ] Add offline mode
- [ ] Add unit tests
- [ ] Add integration tests
- [ ] Deploy to app stores

## Liên hệ

Nếu có vấn đề gì, vui lòng tạo issue hoặc liên hệ qua email.