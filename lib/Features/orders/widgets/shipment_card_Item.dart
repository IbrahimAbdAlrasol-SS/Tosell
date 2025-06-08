import 'package:gap/gap.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter/material.dart';
import 'package:Tosell/core/constants/spaces.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Tosell/Features/orders/models/Shipment.dart';
import 'package:Tosell/Features/orders/models/order_enum.dart';

class EnhancedShipmentCard extends ConsumerWidget {
  final Shipment shipment;
  final Function? onTap;

  const EnhancedShipmentCard({
    required this.shipment,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var theme = Theme.of(context);
    DateTime date = DateTime.parse(
        shipment.creationDate ?? DateTime.now().toIso8601String());
    
    return GestureDetector(
      onTap: () => onTap?.call(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outline),
            color: const Color(0xffEAEEF0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Shipment icon
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
                    
                    // Shipment info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shipment.code ?? "لايوجد",
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
                    
                    // Shipment status
                    _buildShipmentStatus(shipment.status ?? 0, theme),
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
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      _buildShipmentInfoSection(
                        "وصولات/${shipment.ordersCount ?? 0}",
                        "assets/svg/Files.svg", // تغيير المسار لتجنب الخطأ
                        theme,
                      ),
                      VerticalDivider(
                        width: 20,
                        thickness: 1,
                        color: theme.colorScheme.outline,
                      ),
                      _buildShipmentInfoSection(
                        "التجار/${shipment.merchantsCount ?? 0}",
                        "assets/svg/User.svg",
                        theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShipmentStatus(int index, ThemeData theme) {
    return Container(
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

  Widget _buildShipmentInfoSection(String title, String iconPath, ThemeData theme) {
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
                  color: Colors.black, // النص أسود كما هو مطلوب
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