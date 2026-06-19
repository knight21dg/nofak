import 'package:nofak/app/routes.dart';
import 'package:nofak/ui/screens/widgets/bottom_navigation_bar/hexagon_shape_border.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nofak/utils/tutorial_keys.dart';

enum FabType { diamond, round, ellipse, svg }

class DiamondFab extends StatelessWidget {
  const DiamondFab({
    this.type = FabType.diamond,
    this.borderRadius = 20,
    this.svgAsset,
    this.svgSize = 80,
    super.key,
  }) : assert(
         type != FabType.svg || svgAsset != null,
         'svgAsset must not be null when type is FabType.svg',
       );
  final FabType type;
  final double borderRadius;
  final String? svgAsset;
  final double? svgSize;

  ShapeBorder? get _shapeBorder {
    return switch (type) {
      FabType.diamond => HexagonBorderShape(cornerRadius: 10),
      FabType.round => CircleBorder(),
      FabType.ellipse => RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      FabType.svg => null,
    };
  }

  void _onPressed(BuildContext context) {
    print("DIAMOND_FAB: _onPressed triggered");
    UiUtils.checkUser(
      onNotGuest: () {
        print("DIAMOND_FAB: User is not guest, pushing SelectCategoryScreen");
        Navigator.pushNamed(
          context,
          Routes.selectCategoryScreen,
          arguments: <String, dynamic>{},
        );
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (type == FabType.svg) {
      if (svgAsset == null) {
        throw Exception('svgAsset must not be null when type is FabType.svg');
      }
      child = GestureDetector(
        onTap: () => _onPressed(context),
        child: SvgPicture.asset(svgAsset!, height: svgSize, width: svgSize),
      );
    } else {
      child = FloatingActionButton(
        onPressed: () => _onPressed(context),
        backgroundColor: context.color.territoryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: _shapeBorder,
        child: Icon(Icons.add),
      );
    }

    return KeyedSubtree(
      key: TutorialKeys.sellKey,
      child: child,
    );
  }
}
