import 'package:Tosell/core/Client/BaseClient.dart';
import 'package:Tosell/core/Client/ApiResponse.dart';
import 'package:Tosell/Features/orders/models/Order.dart';
import 'package:Tosell/Features/orders/models/Shipment.dart';

class OrdersShipmentsService {
  final BaseClient<Order> _orderClient;
  final BaseClient<Shipment> _shipmentClient;

  OrdersShipmentsService()
      : _orderClient = BaseClient<Order>(fromJson: (json) => Order.fromJson(json)),
        _shipmentClient = BaseClient<Shipment>(fromJson: (json) => Shipment.fromJson(json));

  Future<ApiResponse<Order>> getOrders({
    int page = 1, 
    Map<String, dynamic>? queryParams
  }) async {
    try {
      var result = await _orderClient.getAll(
        endpoint: '/order/merchant', 
        page: page, 
        queryParams: queryParams
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<ApiResponse<Shipment>> getShipments({
    int page = 1, 
    Map<String, dynamic>? queryParams
  }) async {
    try {
      var result = await _shipmentClient.getAll(
        endpoint: '/shipment/merchant/my-shipments', 
        page: page, 
        queryParams: queryParams
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<(Shipment?, String?)> createShipment(List<String> orderIds) async {
    try {
      final requestData = {
        "orders": orderIds.map((orderId) => {"orderId": orderId}).toList(),
      };
      
      var result = await _shipmentClient.create(
        endpoint: '/shipment/pick-up', 
        data: requestData
      );

      if (result.code == 200 || result.code == 201) {
        return (result.singleData, null);
      } else {
        return (null, result.message ?? 'فشل في إنشاء الشحنة');
      }
    } catch (e) {
      return (null, e.toString());
    }
  }

  Future<Order?> getOrderByCode({required String code}) async {
    try {
      var result = await _orderClient.getById(endpoint: '/order', id: code);
      return result.singleData;
    } catch (e) {
      rethrow;
    }
  }
}