import 'package:Tosell/Features/orders/widgets/order_card.dart';
import 'package:gap/gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Tosell/core/constants/spaces.dart';
import 'package:Tosell/core/utils/extensions.dart';
import 'package:Tosell/core/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Tosell/Features/orders/models/Order.dart';
import 'package:Tosell/Features/orders/models/Shipment.dart';
import 'package:Tosell/Features/orders/models/order_enum.dart';
import 'package:Tosell/Features/orders/models/OrderFilter.dart';
import 'package:Tosell/Features/orders/providers/orders_shipments_provider.dart';
import 'package:Tosell/core/widgets/CustomAppBar.dart';
import 'package:Tosell/core/widgets/custom_section.dart';

class ShipmentDetailsScreen extends ConsumerStatefulWidget {
  final Shipment shipment;
  const ShipmentDetailsScreen({super.key, required this.shipment});

  @override
  ConsumerState<ShipmentDetailsScreen> createState() => _ShipmentDetailsScreenState();
}

class _ShipmentDetailsScreenState extends ConsumerState<ShipmentDetailsScreen>
    with SingleTickerProviderStateMixin {
  
  List<Order>? _shipmentOrders;
  bool _ordersLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadShipmentOrders();
  }

  Future<void> _loadShipmentOrders() async {
    // تحميل الطلبات المرتبطة بالشحنة
    final result = await ref.read(ordersShipmentsNotifierProvider.notifier).getOrders(
      page: 1,
      queryParams: OrderFilter(
        shipmentId: widget.shipment.id,
        shipmentCode: widget.shipment.code,
      ).toJson(),
    );
    
    setState(() {
      _shipmentOrders = result.data ?? [];
      _ordersLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    DateTime date = DateTime.parse(widget.shipment.creationDate ?? DateTime.now().toIso8601String());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar مخصص
            CustomAppBar(
              title: 'تفاصيل الشحنة',
              showBackButton: true,
              onBackButtonPressed: () => context.pop(),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // بطاقة معلومات الشحنة
                    _buildShipmentInfoCard(theme, date),
                    
                    const Gap(AppSpaces.medium),
                    
                    // إحصائيات الشحنة
                          
                    // قائمة الطلبات في الشحنة
                    _buildOrdersSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentInfoCard(ThemeData theme, DateTime date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                child: SvgPicture.asset(
                  "assets/svg/box.svg",
                  width: 32,
                  height: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Gap(AppSpaces.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shipment.code ?? "لايوجد",
                      style: TextStyle(
                        fontSize: 20,
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Tajawal",
                      ),
                    ),
                    const Gap(AppSpaces.exSmall),
                    Text(
                      "تاريخ الإنشاء: ${date.day}/${date.month}/${date.year}",
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w400,
                        fontFamily: "Tajawal",
                      ),
                    ),
                  ],
                ),
              ),
              _buildShipmentStatus(widget.shipment.status ?? 0),
            ],
          ),
        ],
      ),
    );
  }

  
  Widget _buildStatCard(String title, String value, String iconPath, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 32,
            height: 32,
            color: color,
          ),
          const Gap(AppSpaces.small),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.bold,
              fontFamily: "Tajawal",
            ),
          ),
          const Gap(AppSpaces.exSmall),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
              fontFamily: "Tajawal",
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    return CustomSection(
      title: 'الطلبات في الشحنة (${_shipmentOrders?.length ?? 0})',
      icon: SvgPicture.asset(
        "assets/svg/48. Files.svg",
        width: 24,
        height: 24,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        if (_ordersLoaded) ...[
          if (_shipmentOrders != null && _shipmentOrders!.isNotEmpty) ...[
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _shipmentOrders!.length,
                itemBuilder: (context, index) {
                  return OrderCardItem(
                    order: _shipmentOrders![index],
                    onTap: () => context.push(
                      AppRoutes.orderDetails, 
                      extra: _shipmentOrders![index].code
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  SvgPicture.asset(
                    'assets/svg/box.svg',
                    width: 64,
                    height: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const Gap(AppSpaces.medium),
                  Text(
                    'لا توجد طلبات في هذه الشحنة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.secondary,
                      fontFamily: "Tajawal",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...[
          Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShipmentStatus(int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: orderStatus[index].color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        orderStatus[index].name!,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: "Tajawal",
        ),
      ),
    );
  }
}