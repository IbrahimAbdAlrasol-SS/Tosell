import 'package:gap/gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:Tosell/core/constants/spaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Tosell/Features/orders/models/Order.dart';
import 'package:Tosell/Features/orders/models/order_enum.dart';
import 'package:Tosell/Features/orders/providers/orders_shipments_provider.dart';

class EnhancedSelectableOrderCard extends ConsumerWidget {
  final Order order;
  final Function? onTap;
  final bool isSelectionMode;

  const EnhancedSelectableOrderCard({
    required this.order,
    this.onTap,
    this.isSelectionMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    final selectedOrderIds = ref.watch(multiSelectNotifierProvider);
    final isSelected = selectedOrderIds.contains(order.id);
    
    DateTime date = DateTime.parse(order.creationDate ?? DateTime.now().toString());
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      transform: Matrix4.identity()
        ..scale(isSelected ? 0.98 : 1.0),
      child: GestureDetector(
        onTap: () {
          if (isSelectionMode) {
            ref.read(multiSelectNotifierProvider.notifier)
                .toggleSelection(order.id ?? '');
          } else {
            onTap?.call();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
                width: isSelected ? 2 : 1,
              ),
              color: isSelected 
                ? theme.colorScheme.primary.withOpacity(0.08)
                : const Color(0xffEAEEF0),
              borderRadius: BorderRadius.circular(24),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                )
              ] : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Checkbox for selection mode
                      if (isSelectionMode) ...[
                        AnimatedScale(
                          scale: isSelected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ),
                        const Gap(AppSpaces.medium),
                      ],
                      
                      // Order icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: theme.colorScheme.surface,
                        ),
                        child: SvgPicture.asset(
                          "assets/svg/box.svg",
                          width: 20,
                          height: 20,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      
                      const Gap(AppSpaces.medium),
                      
                      // Order info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.code ?? "لايوجد",
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontFamily: "Tajawal",
                              ),
                            ),
                            const Gap(AppSpaces.exSmall),
                            Text(
                              "${date.day}/${date.month}/${date.year}",
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.w400,
                                fontFamily: "Tajawal",
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Order status
                      _buildOrderStatus(order.status ?? 0, theme),
                    ],
                  ),
                ),
                
                // Details section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // First row - Customer and Content
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildInfoSection(
                              order.customerName ?? "لايوجد",
                              "assets/svg/User.svg",
                              theme,
                            ),
                            VerticalDivider(
                              width: 20,
                              thickness: 1,
                              color: theme.colorScheme.outline,
                            ),
                            _buildInfoSection(
                              order.content ?? "لايوجد",
                              "assets/svg/box.svg",
                              theme,
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        height: 1,
                        color: theme.colorScheme.outline,
                      ),
                      
                      // Second row - Location info
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            _buildInfoSection(
                              order.deliveryZone?.governorate?.name ?? "لايوجد",
                              "assets/svg/MapPinLine.svg",
                              theme,
                            ),
                            VerticalDivider(
                              width: 20,
                              thickness: 1,
                              color: theme.colorScheme.outline,
                            ),
                            _buildInfoSection(
                              order.deliveryZone?.name ?? "لايوجد",
                              "assets/svg/MapPinArea.svg",
                              theme,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatus(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: orderStatus[index].color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        orderStatus[index].name!,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: "Tajawal",
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String iconPath, ThemeData theme) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SvgPicture.asset(
              iconPath,
              width: 18,
              height: 18,
              color: theme.colorScheme.primary,
            ),
            const Gap(AppSpaces.small),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.secondary,
                  fontFamily: "Tajawal",
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}