import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/location/leaf_location_cubit.dart';
import 'package:nofak/data/model/location/leaf_location.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nofak/utils/tutorial_keys.dart';

class LocationWidget extends StatefulWidget {
  const LocationWidget({super.key});

  @override
  State<LocationWidget> createState() => _LocationWidgetState();
}

class _LocationWidgetState extends State<LocationWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      key: TutorialKeys.locationKey,
      spacing: 10,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            final location =
                await Navigator.of(context).pushNamed(Routes.locationScreen)
                    as LeafLocation?;

            if (location == null) return;

            context.read<LeafLocationCubit>().setLocation(location);
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.color.secondaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: UiUtils.getSvg(
              AppIcons.location,
              fit: BoxFit.none,
              color: context.color.territoryColor,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<LeafLocationCubit, LeafLocation?>(
            builder: (context, state) {
              final location = state;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    location?.primaryText ?? "locationLbl".translate(context),
                    color: context.color.textColorDark,
                    fontSize: context.font.normal,
                    fontWeight: FontWeight.w600,
                  ),
                  if (location?.secondaryText != null)
                    CustomText(
                      location!.secondaryText!,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      fontSize: context.font.small,
                      maxLines: 2,
                    ),
                  if (location == null || location.isEmpty)
                    CustomText(
                      'global'.translate(context),
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      fontSize: context.font.small,
                      maxLines: 2,
                    ),
                ],
              );
            },
          ),
        ),
        SizedBox(width: 10),
      ],
    );
  }
}
