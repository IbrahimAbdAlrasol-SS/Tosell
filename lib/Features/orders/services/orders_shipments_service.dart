import 'package:Tosell/core/Client/BaseClient.dart';
import 'package:Tosell/core/Client/ApiResponse.dart';
import 'package:Tosell/Features/orders/models/Order.dart';
import 'package:Tosell/Features/orders/models/Shipment.dart';
import 'package:Tosell/Features/order/models/add_order_form.dart';

/// خدمة موحدة لإدارة الطلبات والشحنات
/// تتبع مبدأ Single Responsibility مع دمج الوظائف المكررة
class OrdersShipmentsService {
  final BaseClient<Order> _orderClient;
  final BaseClient<Shipment> _shipmentClient;

  // Singleton pattern لتجنب إنشاء instances متعددة
  static final OrdersShipmentsService _instance = OrdersShipmentsService._internal();
  factory OrdersShipmentsService() => _instance;
  
  OrdersShipmentsService._internal()
      : _orderClient = BaseClient<Order>(fromJson: (json) => Order.fromJson(json)),
        _shipmentClient = BaseClient<Shipment>(fromJson: (json) => Shipment.fromJson(json));

  // ============== Orders Methods ==============
  
  /// جلب قائمة الطلبات مع دعم التصفية والترقيم
  Future<ApiResponse<Order>> getOrders({
    int page = 1, 
    Map<String, dynamic>? queryParams
  }) async {
    try {
      return await _orderClient.getAll(
        endpoint: '/order/merchant', 
        page: page, 
        queryParams: queryParams
      );
    } catch (e) {
      // معالجة أفضل للأخطاء
      return ApiResponse<Order>(
        code: 500,
        message: 'فشل في جلب الطلبات: ${e.toString()}',
        data: [],
        errorType: ApiErrorType.unknown,
      );
    }
  }
  
  /// جلب طلب محدد بواسطة الكود
  Future<Order?> getOrderByCode({required String code}) async {
    try {
      if (code.isEmpty) return null;
      
      var result = await _orderClient.getById(
        endpoint: '/order', 
        id: code
      );
      return result.singleData;
    } catch (e) {
      // Log error في development فقط
      return null;
    }
  }
  
  /// التحقق من صحة كود الطلب
  Future<bool> validateCode({required String code}) async {
    try {
      if (code.isEmpty) return false;
      
      var result = await BaseClient<bool>().get(
        endpoint: '/order/$code/available'
      );
      return result.singleData ?? false;
    } catch (e) {
      return false;
    }
  }
  
  /// إضافة طلب جديد
  Future<(Order?, String?)> addOrder({required AddOrderForm orderForm}) async {
    try {
      // التحقق من البيانات المطلوبة
      if (orderForm.customerName?.isEmpty ?? true) {
        return (null, 'يرجى إدخال اسم الزبون');
      }
      
      if (orderForm.customerPhoneNumber?.isEmpty ?? true) {
        return (null, 'يرجى إدخال رقم الهاتف');
      }
      
      var result = await _orderClient.create(
        endpoint: '/order', 
        data: orderForm.toJson()
      );
      
      if (result.code == 200 || result.code == 201) {
        return (result.singleData, null);
      } else {
        return (null, result.message ?? 'فشل في إضافة الطلب');
      }
    } catch (e) {
      return (null, 'حدث خطأ غير متوقع');
    }
  }
  
  /// تغيير حالة الطلب
  Future<(Order?, String?)> changeOrderState({required String code}) async {
    try {
      if (code.isEmpty) {
        return (null, 'كود الطلب مطلوب');
      }
      
      var result = await _orderClient.update(
        endpoint: '/order/$code/state',
        data: {} // البيانات المطلوبة لتغيير الحالة
      );
      
      if (result.code == 200) {
        return (result.singleData, null);
      } else {
        return (null, result.message ?? 'فشل في تغيير حالة الطلب');
      }
    } catch (e) {
      return (null, 'حدث خطأ في تغيير الحالة');
    }
  }

  // ============== Shipments Methods ==============
  
  /// جلب قائمة الشحنات
  Future<ApiResponse<Shipment>> getShipments({
    int page = 1, 
    Map<String, dynamic>? queryParams
  }) async {
    try {
      return await _shipmentClient.getAll(
        endpoint: '/shipment/merchant/my-shipments', 
        page: page, 
        queryParams: queryParams
      );
    } catch (e) {
      return ApiResponse<Shipment>(
        code: 500,
        message: 'فشل في جلب الشحنات',
        data: [],
        errorType: ApiErrorType.unknown,
      );
    }
  }

  /// إنشاء شحنة جديدة من الطلبات المحددة
  Future<(Shipment?, String?)> createShipment(List<String> orderIds) async {
    try {
      // التحقق من المدخلات
      if (orderIds.isEmpty) {
        return (null, 'يرجى اختيار طلب واحد على الأقل');
      }
      
      // إزالة المعرفات الفارغة
      final validOrderIds = orderIds.where((id) => id.isNotEmpty).toList();
      
      if (validOrderIds.isEmpty) {
        return (null, 'معرفات الطلبات غير صحيحة');
      }
      
      final requestData = {
        "orders": validOrderIds.map((orderId) => {
          "orderId": orderId
        }).toList(),
      };
      
      var result = await _shipmentClient.create(
        endpoint: '/shipment/pick-up', 
        data: requestData
      );

      if (result.code == 200 || result.code == 201) {
        return (result.singleData, null);
      } else {
        // معالجة أفضل لرسائل الخطأ
        final errorMessage = result.message ?? 'فشل في إنشاء الشحنة';
        return (null, _translateErrorMessage(errorMessage));
      }
    } catch (e) {
      return (null, 'حدث خطأ في الاتصال بالخادم');
    }
  }
  // 
  String _translateErrorMessage(String message) {
    if (message.toLowerCase().contains('unauthorized')) {
      return 'غير مصرح لك بهذه العملية';
    } else if (message.toLowerCase().contains('not found')) {
      return 'البيانات المطلوبة غير موجودة';
    } else if (message.toLowerCase().contains('network')) {
      return 'خطأ في الاتصال بالشبكة';
    }
    return message;
  }
}