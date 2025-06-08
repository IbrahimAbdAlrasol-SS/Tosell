import 'package:Tosell/Features/orders/widgets/enhanced_selectable_order_card.dart';
import 'package:Tosell/Features/orders/widgets/shipment_card.dart';
import 'package:gap/gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:Tosell/core/constants/spaces.dart';
import 'package:Tosell/core/utils/extensions.dart';
import 'package:Tosell/core/router/app_router.dart';
import 'package:Tosell/core/widgets/FillButton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Tosell/Features/orders/models/Order.dart';
import 'package:Tosell/Features/orders/models/Shipment.dart';
import 'package:Tosell/paging/generic_paged_list_view.dart';
import 'package:Tosell/core/widgets/CustomTextFormField.dart';
import 'package:Tosell/Features/orders/models/order_enum.dart';
import 'package:Tosell/Features/orders/models/OrderFilter.dart';

import 'package:Tosell/Features/orders/providers/orders_shipments_provider.dart';
import 'package:Tosell/Features/orders/screens/orders_filter_bottom_sheet.dart';
import 'package:Tosell/core/utils/GlobalToast.dart';


class OrdersShipmentsTabBarScreen extends ConsumerStatefulWidget {
  final OrderFilter? filter;
  const OrdersShipmentsTabBarScreen({super.key, this.filter});

  @override
  ConsumerState<OrdersShipmentsTabBarScreen> createState() =>
      _OrdersShipmentsTabBarScreenState();
}

class _OrdersShipmentsTabBarScreenState extends ConsumerState<OrdersShipmentsTabBarScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  List<Order>? _cachedOrders;
  List<Shipment>? _cachedShipments;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    if (_dataLoaded) return;
    
    try {
      final ordersResult = await ref.read(ordersShipmentsNotifierProvider.notifier).getOrders(
        page: 1,
        queryParams: widget.filter?.toJson(),
      );
      
      final shipmentsResult = await ref.read(ordersShipmentsNotifierProvider.notifier).getShipments(page: 1);

      setState(() {
        _cachedOrders = ordersResult.data ?? [];
        _cachedShipments = shipmentsResult.data ?? [];
        _dataLoaded = true;
      });
    } catch (e) {
      GlobalToast.show(message: 'حدث خطأ في تحميل البيانات');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            const Gap(AppSpaces.large),
            
            // شريط البحث والفلتر
            _buildSearchAndFilterBar(),
            
            const Gap(AppSpaces.medium),
            
            // TabBar مخصص
            _buildCustomTabBar(),
            
            const Gap(AppSpaces.small),
            
            // محتوى التابات
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrdersTab(),
                  _buildShipmentsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final selectedOrderIds = ref.watch(multiSelectNotifierProvider);
    final isSelectionMode = ref.watch(multiSelectModeNotifierProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // حقل البحث
          Expanded(
            child: CustomTextFormField(
              label: '',
              showLabel: false,
              hint: _tabController.index == 0 ? 'رقم الطلب' : 'رقم الوصل',
              prefixInner: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SvgPicture.asset(
                  'assets/svg/search.svg',
                  color: Theme.of(context).colorScheme.primary,
                  width: 20,
                  height: 20,
                ),
              ),
            ),
          ),
          
          const Gap(AppSpaces.small),

          if (_tabController.index == 0) ...[
            GestureDetector(
              onTap: () {
                ref.read(multiSelectModeNotifierProvider.notifier).toggle();
                if (!isSelectionMode) {
                  ref.read(multiSelectNotifierProvider.notifier).clearSelection();
                }
              },
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelectionMode
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelectionMode
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Icon(
                  isSelectionMode ? Icons.close : Icons.checklist,
                  color: isSelectionMode
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const Gap(AppSpaces.small),
          ],

          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                isScrollControlled: true,
                context: context,
                builder: (_) => const OrdersFilterBottomSheet(),
              );
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.filter?.status == null
                          ? Theme.of(context).colorScheme.outline
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      'assets/svg/Funnel.svg',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (widget.filter != null)
                  Positioned(
                    top: 6,
                    right: 10,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          setState(() {});
        },
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.secondary,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          fontFamily: "Tajawal",
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          fontFamily: "Tajawal",
        ),
        tabs: const [
          Tab(text: 'الطلبات'),
          Tab(text: 'الشحنات'),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final selectedOrderIds = ref.watch(multiSelectNotifierProvider);
    final isSelectionMode = ref.watch(multiSelectModeNotifierProvider);

    return Column(
      children: [
        if (isSelectionMode) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3)
              ),
            ),
            child: Row(
              children: [
                Text(
                  'تم اختيار ${selectedOrderIds.length} طلب',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontFamily: "Tajawal",
                  ),
                ),
                const Spacer(),
                if (selectedOrderIds.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      ref.read(multiSelectNotifierProvider.notifier).selectAll(
                        _cachedOrders?.map((order) => order.id ?? '').toList() ?? []
                      );
                    },
                    child: Text(
                      'اختيار الكل',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                        fontFamily: "Tajawal",
                      ),
                    ),
                  ),
                const Gap(AppSpaces.medium),
                GestureDetector(
                  onTap: () {
                    ref.read(multiSelectNotifierProvider.notifier).clearSelection();
                  },
                  child: Text(
                    'إلغاء الكل',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                      fontFamily: "Tajawal",
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpaces.small),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                widget.filter == null
                    ? 'جميع الطلبات'
                    : 'جميع الطلبات "${orderStatus[widget.filter?.status ?? 0].name}"',
                style: const TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w500,
                  fontFamily: "Tajawal",
                ),
              ),
            ],
          ),
        ),

        const Gap(AppSpaces.small),
        Expanded(
          child: _buildOrdersList(isSelectionMode),
        ),
        if (isSelectionMode && selectedOrderIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: FillButton(
              label: 'إرسال ${selectedOrderIds.length} طلب للشحن',
              isLoading: _isLoading,
              onPressed: () => _sendSelectedOrders(),
              icon: SvgPicture.asset(
                'assets/svg/box.svg',
                color: Colors.white,
                width: 20,
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildShipmentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'جميع الوصولات',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.w500,
                  fontFamily: "Tajawal",
                ),
              ),
            ],
          ),
        ),
        
        const Gap(AppSpaces.small),
        
        Expanded(
          child: _buildShipmentsList(),
        ),
      ],
    );
  }

  Widget _buildOrdersList(bool isSelectionMode) {
    if (!_dataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedOrders == null || _cachedOrders!.isEmpty) {
      return _buildNoOrdersFound();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _cachedOrders!.length,
      itemBuilder: (context, index) {
        return EnhancedSelectableOrderCard(
          order: _cachedOrders![index],
          isSelectionMode: isSelectionMode,
          onTap: () => context.push(
            AppRoutes.orderDetails,
            extra: _cachedOrders![index].code,
          ),
        );
      },
    );
  }

  Widget _buildShipmentsList() {
    if (!_dataLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_cachedShipments == null || _cachedShipments!.isEmpty) {
      return _buildNoShipmentsFound();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: _cachedShipments!.length,
      itemBuilder: (context, index) {
        return EnhancedShipmentCard(
          shipment: _cachedShipments![index],
          onTap: () => _showShipmentOrders(_cachedShipments![index]),
        );
      },
    );
  }

  void _showShipmentOrders(Shipment shipment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
                        Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const Gap(AppSpaces.medium),
                  Expanded(
                    child: Text(
                      'طلبات الشحنة ${shipment.code ?? ""}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        fontFamily: "Tajawal",
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            Expanded(
              child: FutureBuilder<List<Order>>(
                future: _getShipmentOrders(shipment.id ?? ''),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/svg/box.svg',
                            width: 64,
                            height: 64,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const Gap(AppSpaces.medium),
                          const Text(
                            'لا توجد طلبات في هذه الشحنة',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: "Tajawal",
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return EnhancedSelectableOrderCard(
                        order: snapshot.data![index],
                        isSelectionMode: false,
                        onTap: () {
                          Navigator.pop(context);
                          context.push(
                            AppRoutes.orderDetails,
                            extra: snapshot.data![index].code,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Order>> _getShipmentOrders(String shipmentId) async {
    try {
      final result = await ref.read(ordersShipmentsNotifierProvider.notifier).getOrders(
        page: 1,
        queryParams: OrderFilter(shipmentId: shipmentId).toJson(),
      );
      return result.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<void> _sendSelectedOrders() async {
    final selectedOrderIds = ref.read(multiSelectNotifierProvider);

    if (selectedOrderIds.isEmpty) {
      GlobalToast.show(message: 'يرجى اختيار طلبات للإرسال');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ref
          .read(ordersShipmentsNotifierProvider.notifier)
          .createShipment(selectedOrderIds);

      if (result.$1 != null) {
        GlobalToast.showSuccess(message: 'تم إرسال الطلبات بنجاح');
        ref.read(multiSelectNotifierProvider.notifier).clearSelection();
        ref.read(multiSelectModeNotifierProvider.notifier).disable();

        _dataLoaded = false;
        _loadInitialData();
      } else {
        GlobalToast.show(
          message: result.$2 ?? 'فشل في إرسال الطلبات',
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      GlobalToast.show(
        message: 'حدث خطأ أثناء الإرسال',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildNoOrdersFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/svg/NoItemsFound.gif', width: 240, height: 240),
          const Gap(AppSpaces.medium),
          Text(
            'لا توجد طلبات مضافة',
            style: context.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w500,
              color: const Color(0xffE96363),
              fontSize: 24,
              fontFamily: "Tajawal",
            ),
          ),
          const Gap(AppSpaces.small),
          Text(
            'اضغط على زر "جديد" لإضافة طلب جديد و ارساله الى زبونك',
            textAlign: TextAlign.center,
            style: context.textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w400,
              color: const Color(0xff698596),
              fontSize: 16,
              fontFamily: "Tajawal",
            ),
          ),
          const Gap(AppSpaces.large),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: FillButton(
              label: 'إضافة أول طلب',
              onPressed: () => context.push(AppRoutes.addOrder),
              icon: SvgPicture.asset(
                'assets/svg/navigation_add.svg',
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNoShipmentsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/svg/NoItemsFound.gif',
            width: 240,
            height: 240,
          ),
          const Gap(AppSpaces.medium),
          Text(
            'لا توجد وصولات',
            style: context.textTheme.bodyLarge!.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colorScheme.primary,
              fontSize: 24,
              fontFamily: "Tajawal",
            ),
          ),
        ],
      ),
    );
  }
}