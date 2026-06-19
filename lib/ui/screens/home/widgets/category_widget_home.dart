import 'dart:math';

import 'package:nofak/app/app_theme.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/category/fetch_category_cubit.dart';
import 'package:nofak/data/cubits/system/app_theme_cubit.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/ui/screens/home/widgets/category_home_card.dart';
import 'package:nofak/ui/screens/main_activity.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryWidgetHome extends StatelessWidget {
  const CategoryWidgetHome({super.key});

  final int maxLimit = 10;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
      builder: (context, state) {
        if (state is FetchCategorySuccess) {
          if (state.categories.isNotEmpty) {
            final length = min(state.categories.length, maxLimit);
            final showMoreCategory = length >= maxLimit;
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                height: 103,
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                  scrollDirection: Axis.horizontal,
                  itemCount: showMoreCategory ? length + 1 : length,
                  itemBuilder: (context, index) {
                    if (index == length && showMoreCategory) {
                      return moreCategory(context);
                    } else {
                      return CategoryHomeCard(
                        title: state.categories[index].name!,
                        url: state.categories[index].url!,
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.categories,
                              arguments: {
                                "from": Routes.home,
                                "selectedCategoryId":
                                    state.categories[index].id,
                              },
                            );
                          },
                      );
                    }
                  },
                  separatorBuilder: (context, index) {
                    return const SizedBox(width: 12);
                  },
                ),
              ),
            );
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget moreCategory(BuildContext context) {
    return BlocBuilder<AppThemeCubit, AppTheme>(
      builder: (context, state) {
        return SizedBox(
          width: 70,
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                Routes.categories,
                arguments: {"from": Routes.home},
              ).then((dynamic value) {
                if (value != null) {
                  selectedCategory = value;
                }
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Column(
                spacing: 4,
                children: [
                  Container(
                    clipBehavior: Clip.antiAlias,
                    height: 70,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.color.secondaryColor,
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: UiUtils.getSvg(
                            AppIcons.more,
                            color: context.color.territoryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: CustomText(
                      "more".translate(context),
                      textAlign: TextAlign.center,
                      fontSize: context.font.smaller,
                      color: context.color.textDefaultColor.withValues(
                        alpha: .7,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
