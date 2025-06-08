import 'dart:async';
import 'package:Tosell/core/Client/ApiResponse.dart';
import 'package:Tosell/Features/orders/models/Order.dart';
import 'package:Tosell/Features/orders/models/Shipment.dart';
import 'package:Tosell/Features/orders/services/orders_shipments_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'orders_shipments_provider.g.dart';

@riverpod
class OrdersShipmentsNotifier extends _$OrdersShipmentsNotifier {
  final OrdersShipmentsService _service = OrdersShipmentsService();
  
  // للطلبات
  Future<ApiResponse<Order>> getOrders({
    int page = 1, 
    Map<String, dynamic>? queryParams
  }) async {
    return await _service.getOrders(queryParams: queryParams, page: page);
  }

  Future<ApiResponse<Shipment>> getShipments({
    int page = 1, 
    Map<String, dynamic>? queryParams
  }) async {
    return await _service.getShipments(queryParams: queryParams, page: page);
  }

  Future<(Shipment?, String?)> createShipment(List<String> orderIds) async {
    state = const AsyncValue.loading();
    
    try {
      var result = await _service.createShipment(orderIds);
      
      if (result.$1 != null) {
        state = const AsyncValue.data([]); // success state
        return (result.$1, null);
      } else {
        state = AsyncError(result.$2 ?? 'حدث خطأ', StackTrace.current);
        return (null, result.$2);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return (null, e.toString());
    }
  }

  Future<Order?> getOrderByCode({required String code}) async {
    return await _service.getOrderByCode(code: code);
  }

  @override
  FutureOr<List<dynamic>> build() async {
    return [];
  }
}

@riverpod
class MultiSelectNotifier extends _$MultiSelectNotifier {
  void toggleSelection(String orderId) {
    final currentState = state;
    if (currentState.contains(orderId)) {
      state = currentState.where((id) => id != orderId).toList();
    } else {
      state = [...currentState, orderId];
    }
  }

  void selectAll(List<String> orderIds) {
    state = [...orderIds];
  }

  void clearSelection() {
    state = [];
  }

  @override
  List<String> build() {
    return [];
  }
}

@riverpod
class MultiSelectModeNotifier extends _$MultiSelectModeNotifier {
  void toggle() {
    state = !state;
  }

  void enable() {
    state = true;
  }

  void disable() {
    state = false;
  }

  @override
  bool build() {
    return false;
  }
}