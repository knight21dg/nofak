import 'package:nofak/app/routes.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class HomeSearchField extends StatelessWidget {
  const HomeSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    Widget buildSearchIcon() {
      return Padding(
          padding: EdgeInsetsDirectional.only(start: 16.0, end: 16),
          child: UiUtils.getSvg(AppIcons.search,
              color: context.color.territoryColor));
    }

    Widget buildMicIcon() {
      return Padding(
          padding: EdgeInsetsDirectional.only(start: 16.0, end: 16),
          child: Icon(Icons.mic_none_rounded,
              color: context.color.textDefaultColor.withValues(alpha: 0.5)));
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        Navigator.pushNamed(context, Routes.searchScreenRoute, arguments: {
          "autoFocus": true,
        });
      },
      child: AbsorbPointer(
        absorbing: true,
        child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: sidePadding, vertical: 15),
            width: context.screenWidth,
            height: 56,
            alignment: AlignmentDirectional.center,
            decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                color: context.color.secondaryColor),
            child: TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  border: InputBorder.none, //OutlineInputBorder()
                  fillColor: Theme.of(context).colorScheme.secondaryColor,
                  hintText: "searchHintLbl".translate(context),
                  hintStyle: TextStyle(
                      color: context.color.textDefaultColor
                          .withValues(alpha: 0.5)),
                  prefixIcon: buildSearchIcon(),
                  prefixIconConstraints:
                      const BoxConstraints(minHeight: 5, minWidth: 5),
                  suffixIcon: buildMicIcon(),
                ),
                enableSuggestions: true,
                onEditingComplete: () {
                  FocusScope.of(context).unfocus();
                },
                onTap: () {
                  //change prefix icon color to primary
                })),
      ),
    );
  }
}
