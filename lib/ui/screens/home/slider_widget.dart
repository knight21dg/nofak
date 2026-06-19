import 'dart:async';

import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/slider_cubit.dart';
import 'package:nofak/data/model/category_model.dart';
import 'package:nofak/data/model/data_output.dart';
import 'package:nofak/data/model/home/home_slider.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/data/repositories/item/item_repository.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/widgets.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart' as urllauncher;
import 'package:url_launcher/url_launcher.dart';
// Import your SliderCubit and other necessary dependencies

class SliderWidget extends StatefulWidget {
  const SliderWidget({super.key});

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<int> _bannerIndex = ValueNotifier(0);
  late Timer _timer;
  int bannersLength = 0;
  final PageController _pageController = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startAutoSlider();
  }

  @override
  void dispose() {
    _bannerIndex.dispose();
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoSlider() {
    // Set up a timer to automatically change the banner index
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      final int nextPage = _bannerIndex.value + 1;
      if (nextPage < bannersLength) {
        _bannerIndex.value = nextPage;
      } else {
        _bannerIndex.value = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _bannerIndex.value,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<SliderCubit, SliderState>(
      builder: (context, SliderState state) {
        if (state is SliderFetchSuccess && state.sliderlist.isNotEmpty) {
          bannersLength = state.sliderlist.length; // Update bannersLength
          return SizedBox(
            height: 170,
            child: PageView.builder(
              itemCount: bannersLength,
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              onPageChanged: (index) {
                _bannerIndex.value =
                    index; // Update bannerIndex when page changes manually
              },
              itemBuilder: (context, index) {
                HomeSlider homeSlider = state.sliderlist[index];
                return InkWell(
                  onTap: () async {
                    sliderTap(homeSlider);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: sidePadding),
                    width: MediaQuery.of(context).size.width - 16,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: context.color.secondaryColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: UiUtils.getImage(
                        homeSlider.image ?? "",
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }

  Future<void> sliderTap(HomeSlider homeSlider) async {
    if (homeSlider.thirdPartyLink != "") {
      await urllauncher.launchUrl(
        Uri.parse(homeSlider.thirdPartyLink!),
        mode: LaunchMode.externalApplication,
      );
    } else if (homeSlider.modelType!.contains("Category")) {
      if (homeSlider.model!.subCategoriesCount! > 0) {
        Navigator.pushNamed(
          context,
          Routes.subCategoryScreen,
          arguments: {
            "categoryList": <CategoryModel>[],
            "catName": homeSlider.model?.name?.localized,
            "catId": homeSlider.modelId,
            "categoryIds": [
              homeSlider.model!.parentCategoryId.toString(),
              homeSlider.modelId.toString(),
            ],
          },
        );
      } else {
        Navigator.pushNamed(
          context,
          Routes.itemsList,
          arguments: {
            'catID': homeSlider.modelId.toString(),
            'catName': homeSlider.model?.name?.localized,
            "categoryIds": [homeSlider.modelId.toString()],
          },
        );
      }
    } else {
      try {
        ItemRepository fetch = ItemRepository();

        LoadingWidgets.showLoader(context);

        DataOutput<ItemModel> dataOutput = await fetch.fetchItemFromItemId(
          homeSlider.modelId!,
        );

        Future.delayed(Duration.zero, () {
          LoadingWidgets.hideLoader(context);
          Navigator.pushNamed(
            context,
            Routes.adDetailsScreen,
            arguments: {"model": dataOutput.modelList[0]},
          );
        });
      } catch (e) {
        LoadingWidgets.hideLoader(context);
        UiUtils.showError(context, e);
      }
    }
  }
}
