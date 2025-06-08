import 'package:Tosell/Features/orders/widgets/order_card_item.dart';
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
import 'package:Tosell/Features/orders/widgets/shipment_card_item.dart';
import 'package:Tosell/Features/orders/providers/orders_shipments_provider.dart';
import 'package:Tosell/Features/orders/screens/orders_filter_bottom_sheet.dart';
import 'package:Tosell/Features/orders/screens/shipment_details_screen.dart';
import 'package:Tosell/core/utils/GlobalToast.dart';

class OrdersShipmentsScreen extends ConsumerStatefulWidget {
  final OrderFilter? filter;
  const OrdersShipmentsScreen({super.key, this.filter});

  @override
  ConsumerState<OrdersShipmentsScreen> createState() =>
      _OrdersShipmentsScreenState();
}

class _OrdersShipmentsScreenState extends ConsumerState<OrdersShipmentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late OrderFilter? _currentFilter;
  bool _isLoading = false;

  List<Order>? _cachedOrders;
  List<Shipment>? _cachedShipments;
  bool _ordersLoaded = false;
  bool _shipmentsLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentFilter = widget.filter;

    // تحميل البيانات عند بدء الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    // تحميل الطلبات والشحنات معاً مرة واحدة فقط
    if (!_ordersLoaded || !_shipmentsLoaded) {
      final results = await Future.wait([
        ref.read(ordersShipmentsNotifierProvider.notifier).getOrders(
              page: 1,
              queryParams: _currentFilter?.toJson(),
            ),
        ref
            .read(ordersShipmentsNotifierProvider.notifier)
            .getShipments(page: 1),
      ]);

      _cachedOrders = (results[0].data as List<Order>?) ?? [];
      _cachedShipments = (results[1].data as List<Shipment>?) ?? [];
      _ordersLoaded = true;
      _shipmentsLoaded = true;
    }
  }

  @override
  void didUpdateWidget(covariant OrdersShipmentsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _currentFilter = widget.filter ?? OrderFilter();
      _ordersLoaded = false; // إعادة تحميل الطلبات عند تغيير الفلتر
      _loadInitialData();
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

            // شريط البحث والفلتر أولاً
            _buildSearchAndFilterBar(),

            const Gap(AppSpaces.medium),

            // TabBar المحسن
            _buildCustomTabBar(),

            const Gap(AppSpaces.medium),

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

    return Row(
      children: [
        const Gap(5),
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
                width: 3,
                height: 3,
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

        // زر الفلتر
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
        const Gap(5),
      ],
    );
  }

  // TabBar محسن
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

  // تاب الطلبات
  Widget _buildOrdersTab() {
    final selectedOrderIds = ref.watch(multiSelectNotifierProvider);
    final isSelectionMode = ref.watch(multiSelectModeNotifierProvider);

    return Column(
      children: [
        if (isSelectionMode) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  'تم اختيار ${selectedOrderIds.length} طلب',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    ref
                        .read(multiSelectNotifierProvider.notifier)
                        .clearSelection();
                  },
                  child: Text(
                    'إلغاء الكل',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          const Gap(AppSpaces.exSmall),
        ],

        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            widget.filter == null
                ? 'جميع الطلبات'
                : 'جميع الطلبات "${orderStatus[widget.filter?.status ?? 0].name}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),

        // قائمة الطلبات مع Cache
        Expanded(
          child: _cachedOrders != null
              ? _buildCachedOrdersList()
              : _buildPagedOrdersList(),
        ),

        // زر إرسال الطلبات المختارة
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

  // تاب الشحنات
  Widget _buildShipmentsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'جميع الوصولات',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: _cachedShipments != null
              ? _buildCachedShipmentsList()
              : _buildPagedShipmentsList(),
        ),
      ],
    );
  }

  // قائمة الطلبات مع Cache
  Widget _buildCachedOrdersList() {
    if (_cachedOrders!.isEmpty) {
      return _buildNoOrdersFound();
    }

    final isSelectionMode = ref.watch(multiSelectModeNotifierProvider);

    return ListView.builder(
      itemCount: _cachedOrders!.length,
      itemBuilder: (context, index) {
        return SelectableOrderCardItem(
          order: _cachedOrders![index],
          isSelectionMode: isSelectionMode,
          onTap: () => context.push(AppRoutes.orderDetails,
              extra: _cachedOrders![index].code),
        );
      },
    );
  }

  // قائمة الشحنات مع Cache
  Widget _buildCachedShipmentsList() {
    if (_cachedShipments!.isEmpty) {
      return _buildNoShipmentsFound();
    }

    return ListView.builder(
      itemCount: _cachedShipments!.length,
      itemBuilder: (context, index) {
        return ShipmentCartItem(
          shipment: _cachedShipments![index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ShipmentDetailsScreen(shipment: _cachedShipments![index]),
              ),
            );
          },
        );
      },
    );
  }

  // قائمة الطلبات العادية (عند عدم وجود Cache)
  Widget _buildPagedOrdersList() {
    return GenericPagedListView<Order>(
      key: ValueKey(widget.filter?.toJson()),
      noItemsFoundIndicatorBuilder: _buildNoOrdersFound(),
      fetchPage: (pageKey, _) async {
        final result =
            await ref.read(ordersShipmentsNotifierProvider.notifier).getOrders(
                  page: pageKey,
                  queryParams: _currentFilter?.toJson(),
                );
        if (pageKey == 1) {
          _cachedOrders = result.data ?? [];
          _ordersLoaded = true;
        }
        return result;
      },
      itemBuilder: (context, order, index) {
        final isSelectionMode = ref.watch(multiSelectModeNotifierProvider);
        return SelectableOrderCardItem(
          order: order,
          isSelectionMode: isSelectionMode,
          onTap: () => context.push(AppRoutes.orderDetails, extra: order.code),
        );
      },
    );
  }

  // قائمة الشحنات العادية (عند عدم وجود Cache)
  Widget _buildPagedShipmentsList() {
    return GenericPagedListView<Shipment>(
      noItemsFoundIndicatorBuilder: _buildNoShipmentsFound(),
      fetchPage: (pageKey, _) async {
        final result = await ref
            .read(ordersShipmentsNotifierProvider.notifier)
            .getShipments(
              page: pageKey,
            );
        if (pageKey == 1) {
          _cachedShipments = result.data ?? [];
          _shipmentsLoaded = true;
        }
        return result;
      },
      itemBuilder: (context, shipment, index) => ShipmentCartItem(
        shipment: shipment,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShipmentDetailsScreen(shipment: shipment),
            ),
          );
        },
      ),
    );
  }

  // إرسال الطلبات المختارة
  Future<void> _sendSelectedOrders() async {
    final selectedOrderIds = ref.read(multiSelectNotifierProvider);

    if (selectedOrderIds.isEmpty) {
      GlobalToast.show(message: 'يرجى اختيار طلبات للإرسال');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await ref
        .read(ordersShipmentsNotifierProvider.notifier)
        .createShipment(selectedOrderIds);

    setState(() {
      _isLoading = false;
    });

    if (result.$1 != null) {
      GlobalToast.showSuccess(message: 'تم إرسال الطلبات بنجاح');
      ref.read(multiSelectNotifierProvider.notifier).clearSelection();
      ref.read(multiSelectModeNotifierProvider.notifier).disable();

      // تحديث البيانات
      _ordersLoaded = false;
      _shipmentsLoaded = false;
      _loadInitialData();
    } else {
      GlobalToast.show(
        message: result.$2 ?? 'فشل في إرسال الطلبات',
        backgroundColor: Colors.red,
      );
    }
  }

  Widget _buildNoOrdersFound() {
    return Column(
      children: [
        Image.asset('assets/svg/NoItemsFound.gif', width: 240, height: 240),
        Text(
          'لا توجد طلبات مضافة',
          style: context.textTheme.bodyLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: const Color(0xffE96363),
            fontSize: 24,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'اضغط على زر "جديد" لإضافة طلب جديد و ارساله الى زبونك',
          style: context.textTheme.bodySmall!.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xff698596),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: FillButton(
            label: 'إضافة اول طلب',
            onPressed: () => context.push(AppRoutes.addOrder),
            icon: SvgPicture.asset('assets/svg/navigation_add.svg',
                color: const Color(0xffFAFEFD)),
            reverse: true,
          ),
        )
      ],
    );
  }

  Widget _buildNoShipmentsFound() {
    return Column(
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
            fontWeight: FontWeight.w700,
            color: context.colorScheme.primary,
            fontSize: 24,
          ),
        ),
      ],
    );
  }
}
