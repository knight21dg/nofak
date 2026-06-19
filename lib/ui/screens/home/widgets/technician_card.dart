import 'package:flutter/material.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';

class TechnicianCard extends StatelessWidget {
  final ItemModel item;
  final double? width;

  const TechnicianCard({super.key, required this.item, this.width});

  @override
  Widget build(BuildContext context) {
    // Determine expertise icon based on category or custom fields
    IconData expertiseIcon = Icons.handyman_rounded;
    String expertiseName = "specialist".translate(context);
    
    if (item.category?.name?.toLowerCase().contains("ac") ?? false) {
      expertiseIcon = Icons.ac_unit_rounded;
      expertiseName = "acSpecialist".translate(context);
    } else if (item.category?.name?.toLowerCase().contains("plumbing") ?? false) {
      expertiseIcon = Icons.plumbing_rounded;
      expertiseName = "plumber".translate(context);
    } else if (item.category?.name?.toLowerCase().contains("electrical") ?? false) {
      expertiseIcon = Icons.electric_bolt_rounded;
      expertiseName = "electrician".translate(context);
    } else if (item.category?.name?.toLowerCase().contains("cars") ?? false) {
      expertiseIcon = Icons.directions_car_rounded;
      expertiseName = "vehicleInspector".translate(context);
    } else if (item.category?.name?.toLowerCase().contains("electronics") ?? false) {
      expertiseIcon = Icons.devices_rounded;
      expertiseName = "electronicsTechnician".translate(context);
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.adDetailsScreen,
            arguments: {"model": item},
          );
        },
        child: Container(
          width: width ?? 280,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: context.color.textLightColor.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.color.territoryColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 35,
                            backgroundColor: context.color.backgroundColor,
                            backgroundImage: (item.user?.profile != null)
                                ? NetworkImage(item.user!.profile!)
                                : null,
                            child: (item.user?.profile == null)
                                ? Icon(Icons.person, size: 40, color: context.color.territoryColor)
                                : null,
                          ),
                        ),
                        if (item.user?.isVerified == 1)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified_rounded,
                                color: context.color.forthColor,
                                size: 20,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            item.user?.name ?? "Specialist",
                            fontSize: context.font.larger,
                            fontWeight: FontWeight.bold,
                            maxLines: 1,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(expertiseIcon, size: 14, color: context.color.territoryColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: CustomText(
                                  expertiseName,
                                  fontSize: context.font.small,
                                  color: context.color.territoryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              CustomText(
                                (item.review != null && item.review!.isNotEmpty)
                                    ? (item.review!.fold<double>(
                                              0,
                                              (p, c) => p + (c.ratings ?? 0),
                                            ) /
                                            item.review!.length)
                                        .toStringAsFixed(1)
                                    : "4.9", // Fallback if no reviews
                                fontSize: context.font.small,
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(width: 4),
                              CustomText(
                                "(${item.review?.length ?? 24} reviews)",
                                fontSize: context.font.smaller,
                                color: context.color.textLightColor,
                              ),
                            ],
                          ),
                          if (item.user?.isAddressVerified == 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_rounded, size: 12, color: context.color.forthColor),
                                  const SizedBox(width: 2),
                                  CustomText(
                                    "verifiedPhysicalLocation".translate(context),
                                    fontSize: 10,
                                    color: context.color.forthColor,
                                    fontWeight: FontWeight.w600,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: context.color.territoryColor.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "startsFrom".translate(context),
                          fontSize: context.font.smaller,
                          color: context.color.textLightColor,
                        ),
                        UiUtils.getPriceWidget(item, context),
                      ],
                    ),
                    UiUtils.buildButton(
                      context,
                      buttonTitle: "hireNow".translate(context),
                      width: 100,
                      height: 35,
                      fontSize: context.font.small,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          Routes.adDetailsScreen,
                          arguments: {"model": item},
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
