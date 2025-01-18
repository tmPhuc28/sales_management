// lib/core/localization/app_strings.dart

class AppStrings {
  // Tên ứng dụng
  static const String appName = 'Quản lý bán hàng';

  // Common
  static const String error = 'Lỗi';
  static const String success = 'Thành công';
  static const String cancel = 'Hủy';
  static const String confirm = 'Xác nhận';
  static const String save = 'Lưu';
  static const String edit = 'Sửa';
  static const String delete = 'Xóa';
  static const String add = 'Thêm';
  static const String close = 'Đóng';
  static const String loading = 'Đang tải...';
  static const String processing = 'Đang xử lý...';
  static const String search = 'Tìm kiếm';
  static const String code = 'Mã';
  static const String noData = 'Không có dữ liệu';

  // Navigation
  static const String home = 'Trang chủ';
  static const String orders = 'Đơn hàng';
  static const String products = 'Sản phẩm';
  static const String categories = 'Danh mục';
  static const String statistics = 'Thống kê';
  static const String settings = 'Cài đặt';

  // Products
  static const String addProduct = 'Thêm sản phẩm';
  static const String editProduct = 'Sửa sản phẩm';
  static const String deleteProduct = 'Xóa sản phẩm';
  static const String productName = 'Tên sản phẩm';
  static const String productCode = 'Mã sản phẩm';
  static const String sellingPrice = 'Giá bán';
  static const String costPrice = 'Giá vốn';
  static const String quantity = 'Số lượng';
  static const String stock = 'Tồn kho';
  static const String category = 'Danh mục';
  static const String noProducts = 'Chưa có sản phẩm';
  static const String confirmDeleteProduct = 'Bạn có chắc muốn xóa sản phẩm này?';
  static const String productSaved = 'Đã lưu sản phẩm';
  static const String productDeleted = 'Đã xóa sản phẩm';
  static const String addImage = 'Thêm hình ảnh';

  // Cart
  static const String cart = 'Giỏ hàng';
  static const String cartEmpty = 'Giỏ hàng trống';
  static const String addToCart = 'Thêm vào giỏ';
  static const String viewCart = 'Xem giỏ hàng';
  static const String clearCart = 'Xóa giỏ hàng';
  static const String confirmClearCart = 'Bạn có chắc muốn xóa giỏ hàng này?';
  static const String notEnoughStock = 'Không đủ số lượng trong kho';
  static String addedToCart(String productName) => 'Đã thêm $productName vào giỏ hàng';

  // Checkout
  static const String checkout = 'Thanh toán';
  static const String price = 'Giá';
  static const String orderSummary = 'Thông tin đơn hàng';
  static const String orderNotes = 'Ghi chú đơn hàng';
  static const String orderNotesHint = 'Nhập ghi chú cho đơn hàng (không bắt buộc)';
  static const String completeOrder = 'Hoàn tất đơn hàng';
  static const String orderSuccess = 'Đặt hàng thành công';
  static const String totalItems = 'Tổng số sản phẩm';
  static const String totalAmount = 'Tổng tiền';

  // Categories
  static const String addCategory = 'Thêm danh mục';
  static const String editCategory = 'Sửa danh mục';
  static const String deleteCategory = 'Xóa danh mục';
  static const String categoryName = 'Tên danh mục';
  static const String categoryCode = 'Mã danh mục';
  static const String noCategories = 'Chưa có danh mục';
  static const String confirmDeleteCategory = 'Bạn có chắc muốn xóa danh mục này?';
  static const String cannotDeleteCategory = 'Không thể xóa danh mục đang có sản phẩm';
  static const String categorySaved = 'Đã lưu danh mục';
  static const String categoryDeleted = 'Đã xóa danh mục';

  // Orders
  static const String orderDetails = 'Chi tiết đơn hàng';
  static const String orderId = 'Mã đơn hàng';
  static const String orderDate = 'Ngày đặt hàng';
  static const String orderItems = 'Sản phẩm trong đơn';
  static const  String orderTotal = 'Tổng tiền';
  static const String orderStatus = 'Trạng thái đơn hàng';
  static const String noOrders = 'Chưa có đơn hàng';
  static const String orderPending = 'Chờ xử lý';
  static const String orderProcessing = 'Đang xử lý';
  static const String orderCompleted = 'Đã hoàn thành';
  static const String orderCancelled = 'Đã hủy';

  // Statistics
  static const String sales  = 'Doanh số';
  static const String overview = 'Tổng quan';
  static const String totalRevenue = 'Doanh thu';
  static const String totalOrders = 'Số đơn hàng';
  static const String totalProfit = 'Lợi nhuận';
  static const String averageOrderValue = 'Giá trị đơn hàng TB';
  static const String profitMargin = 'Tỷ suất lợi nhuận';
  static const String salesTrend = 'Xu hướng doanh thu';
  static const String salesDistribution = 'Phân bố doanh thu';
  static const String topProducts = 'Top sản phẩm';
  static const String vsLastPeriod = 'so với kỳ trước';
  static const String totalSales = 'Tổng doanh thu';
  static const String averageDailySales = 'Doanh thu TB/ngày';
  static const String numberOfDays = 'Số ngày';
  static const String itemsSold = 'đã bán';
  static const String deletedProduct = 'Sản phẩm đã xóa';
  static const String noSalesData = 'Không có dữ liệu doanh thu';
  static const String noProductsData = 'Không có dữ liệu sản phẩm';
  static const String dailySales = 'Doanh thu theo ngày';

  // Settings
  static const String theme = 'Giao diện';
  static const String themeColor = 'Màu sắc';
  static const String darkMode = 'Chế độ tối';
  static const String lightMode = 'Chế độ sáng';
  static const String systemMode = 'Theo hệ thống';

  // Data Management
  static const String dataManagement = 'Quản lý dữ liệu';
  static const String importData = 'Nhập dữ liệu';
  static const String exportData = 'Xuất dữ liệu';
  static const String clearData = 'Xóa dữ liệu';
  static const String importDataDesc = 'Nhập dữ liệu từ file backup';
  static const String exportDataDesc = 'Tạo file backup dữ liệu';
  static const String clearDataDesc = 'Xóa toàn bộ dữ liệu trong ứng dụng';
  static const String clearDataConfirm = 'Bạn có chắc muốn xóa toàn bộ dữ liệu? Hành động này không thể hoàn tác.';
  static const String dataImportSuccess = 'Nhập dữ liệu thành công';
  static String dataExportSuccess(String path) => 'Đã xuất dữ liệu ra file: $path';
  static const String dataCleared = 'Đã xóa toàn bộ dữ liệu';
  static const String clear = 'Xóa';

  // Validation
  static const String required = 'Vui lòng nhập thông tin này';
  static const String invalidNumber = 'Số không hợp lệ';
  static const String invalidPrice = 'Giá không hợp lệ';
  static const String invalidQuantity = 'Số lượng không hợp lệ';
  static const String sellingPriceTooLow = 'Giá bán phải lớn hơn hoặc bằng giá vốn';
  static const String duplicateCode = 'Mã này đã tồn tại';

  // Date Range
  static const String selectDateRange = 'Chọn khoảng thời gian';
  static const String fromDate = 'Từ ngày';
  static const String toDate = 'Đến ngày';
  static const String apply = 'Áp dụng';
  static const String today = 'Hôm nay';
  static const String yesterday = 'Hôm qua';
  static const String last7Days = '7 ngày qua';
  static const String last30Days = '30 ngày qua';
  static const String thisMonth = 'Tháng này';
  static const String lastMonth = 'Tháng trước';

  // Notes
  static const String notes = 'Ghi chú';
  static const String addNotes = 'Thêm ghi chú';
  static const String notesHint = 'Nhập ghi chú';
  static const String notesOptional = 'Ghi chú (không bắt buộc)';

  static String retry = 'Thử lại';

}