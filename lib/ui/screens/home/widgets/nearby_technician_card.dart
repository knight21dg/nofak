import 'package:flutter/material.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/model/user/user_model.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';

class NearbyTechnicianCard extends StatelessWidget {
  final UserModel technician;
  final double? width;

  const NearbyTechnicianCard({
    super.key,
    required this.technician,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Determine expertise icon based on field of expertise
    IconData expertiseIcon = Icons.handyman_rounded;
    String expertiseName = technician.fieldOfExpertise ?? "Specialist";
    
    final lowerExpertise = expertiseName.toLowerCase();
    if (lowerExpertise.contains("ac")) {
      expertiseIcon = Icons.ac_unit_rounded;
      expertiseName = "acSpecialist".translate(context);
    } else if (lowerExpertise.contains("plumbing") || lowerExpertise.contains("plumber")) {
      expertiseIcon = Icons.plumbing_rounded;
      expertiseName = "plumber".translate(context);
    } else if (lowerExpertise.contains("electrical") || lowerExpertise.contains("electrician")) {
      expertiseIcon = Icons.electric_bolt_rounded;
      expertiseName = "electrician".translate(context);
    } else if (lowerExpertise.contains("cars") || lowerExpertise.contains("vehicle") || lowerExpertise.contains("car")) {
      expertiseIcon = Icons.directions_car_rounded;
      expertiseName = "vehicleInspector".translate(context);
    } else if (lowerExpertise.contains("electronics")) {
      expertiseIcon = Icons.devices_rounded;
      expertiseName = "electronicsTechnician".translate(context);
    }

    return RepaintBoundary(
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(
            context,
            Routes.sellerProfileScreen,
            arguments: {"sellerId": technician.id},
          );
        },
        child: Container(
          width: width ?? double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                            backgroundImage: (technician.profile != null && technician.profile!.isNotEmpty)
                                ? NetworkImage(technician.profile!)
                                : null,
                            child: (technician.profile == null || technician.profile!.isEmpty)
                                ? Icon(Icons.person, size: 40, color: context.color.territoryColor)
                                : null,
                          ),
                        ),
                        if (technician.isVerified == 1)
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
                            technician.name ?? "Specialist",
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
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 2),
                              CustomText(
                                technician.averageRating != null && technician.averageRating! > 0
                                    ? technician.averageRating!.toStringAsFixed(1)
                                    : "5.0",
                                fontSize: context.font.small,
                                fontWeight: FontWeight.bold,
                              ),
                              const SizedBox(width: 6),
                              CustomText(
                                "(${technician.jobsCompleted ?? 0} jobs completed)",
                                fontSize: context.font.smaller,
                                color: context.color.textLightColor,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (technician.distance != null)
                            Row(
                              children: [
                                Icon(Icons.navigation_rounded, size: 12, color: context.color.forthColor),
                                const SizedBox(width: 2),
                                CustomText(
                                  "${technician.distance!.toStringAsFixed(1)} km away",
                                  fontSize: context.font.smaller,
                                  color: context.color.forthColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "Skills",
                            fontSize: context.font.smaller,
                            color: context.color.textLightColor,
                          ),
                          CustomText(
                            technician.skills != null && technician.skills!.isNotEmpty
                                ? technician.skills!
                                : "General Inspection",
                            fontSize: context.font.small,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    UiUtils.buildButton(
                      context,
                      buttonTitle: "View Profile".translate(context),
                      width: 110,
                      height: 35,
                      fontSize: context.font.small,
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          Routes.sellerProfileScreen,
                          arguments: {"sellerId": technician.id},
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
