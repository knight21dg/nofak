import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/category/fetch_category_cubit.dart';
import 'package:nofak/data/model/category_model.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/ui_utils.dart';

class CategoryList extends StatefulWidget {
  const CategoryList({super.key});

  @override
  State<CategoryList> createState() => _CategoryListState();

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const CategoryList(),
    );
  }
}

class _CategoryListState extends State<CategoryList>
    with TickerProviderStateMixin {
  final ScrollController _pageScrollController = ScrollController();
  final ValueNotifier<int> _selectedCategoryIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    
    final categoryState = context.read<FetchCategoryCubit>().state;
    if (categoryState is! FetchCategorySuccess && categoryState is! FetchCategoryInProgress) {
      context.read<FetchCategoryCubit>().fetchCategories();
    }

    _pageScrollController.addListener(() {
      if (_pageScrollController.position.pixels ==
          _pageScrollController.position.maxScrollExtent) {
        if (context.read<FetchCategoryCubit>().hasMoreData()) {
          context.read<FetchCategoryCubit>().fetchCategoriesMore();
        }
      }
    });

    // Check for pre-selected category from navigation arguments
    Future.delayed(Duration.zero, () {
      final arguments = ModalRoute.of(context)?.settings.arguments as Map?;
      if (arguments != null && arguments.containsKey('selectedCategoryId')) {
        final selectedId = arguments['selectedCategoryId'];
        final state = context.read<FetchCategoryCubit>().state;
        if (state is FetchCategorySuccess) {
          final index = state.categories.indexWhere((element) => element.id == selectedId);
          if (index != -1) {
            _selectedCategoryIndex.value = index;
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    _selectedCategoryIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: AppBar(
          backgroundColor: context.color.secondaryColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.color.textDefaultColor,
              size: 20,
            ),
          ),
          centerTitle: true,
          title: CustomText(
            "categoriesLbl".translate(context),
            color: context.color.textDefaultColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
            builder: (context, state) {
              if (state is FetchCategoryInProgress) {
                return Center(child: UiUtils.progress());
              }
              if (state is FetchCategorySuccess) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Refurbished Sidebar ---
                    Container(
                      width: 95,
                      decoration: BoxDecoration(
                        color: context.color.primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        itemCount: state.categories.length,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemBuilder: (context, index) {
                          return ValueListenableBuilder(
                            valueListenable: _selectedCategoryIndex,
                            builder: (context, selectedIndex, _) {
                              bool isSelected = selectedIndex == index;
                              return GestureDetector(
                                onTap: () {
                                  _selectedCategoryIndex.value = index;
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  height: 90,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Active Indicator Pill
                                      if (isSelected)
                                        Positioned(
                                          left: 0,
                                          child: Container(
                                            width: 4,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: context.color.territoryColor,
                                              borderRadius: const BorderRadius.only(
                                                topRight: Radius.circular(10),
                                                bottomRight: Radius.circular(10),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: context.color.territoryColor.withValues(alpha: 0.4),
                                                  blurRadius: 8,
                                                  offset: const Offset(2, 0),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      
                                      Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? context.color.territoryColor.withValues(alpha: 0.08)
                                                  : Colors.transparent,
                                              shape: BoxShape.circle,
                                            ),
                                            child: UiUtils.imageType(
                                              state.categories[index].url!,
                                              height: 32,
                                              width: 32,
                                              color: isSelected ? context.color.territoryColor : null,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: CustomText(
                                              state.categories[index].name!,
                                              textAlign: TextAlign.center,
                                              fontSize: 10,
                                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                              color: isSelected
                                                  ? context.color.territoryColor
                                                  : context.color.textDefaultColor.withValues(alpha: 0.6),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),

                    // --- Refurbished Sub-category Area ---
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: _selectedCategoryIndex,
                        builder: (context, selectedIndex, _) {
                          CategoryModel selectedCategory = state.categories[selectedIndex];
                          List<CategoryModel> subCategories = selectedCategory.children ?? [];

                          return Container(
                            color: context.color.secondaryColor.withValues(alpha: 0.2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Header Info
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            CustomText(
                                              selectedCategory.name!,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: context.color.textDefaultColor,
                                            ),
                                            CustomText(
                                              "${subCategories.length} items".translate(context),
                                              fontSize: 12,
                                              color: context.color.textDefaultColor.withValues(alpha: 0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (selectedCategory.slug == 'technician-marketplace' ||
                                              selectedCategory.name!.toLowerCase().contains('technician')) {
                                            Navigator.pushNamed(context, Routes.technicianMarketplace);
                                            return;
                                          }
                                          Constant.itemFilter = null;
                                          HelperUtils.goToNextPage(
                                            Routes.itemsList,
                                            context,
                                            false,
                                            args: {
                                              'catID': selectedCategory.id.toString(),
                                              'catName': selectedCategory.name,
                                              "categoryIds": [selectedCategory.id.toString()],
                                            },
                                          );
                                        },
                                        child: CustomText(
                                          "viewAll".translate(context),
                                          color: context.color.territoryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Expanded(
                                  child: subCategories.isEmpty
                                      ? Center(
                                          child: CustomText(
                                            "noSubCategories".translate(context),
                                            color: context.color.textDefaultColor.withValues(alpha: 0.4),
                                          ),
                                        )
                                      : GridView.builder(
                                          padding: const EdgeInsets.all(16),
                                          physics: const BouncingScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 12,
                                            mainAxisSpacing: 12,
                                            childAspectRatio: 0.9,
                                          ),
                                          itemCount: subCategories.length,
                                          itemBuilder: (context, index) {
                                            CategoryModel subCategory = subCategories[index];
                                            return GestureDetector(
                                              onTap: () {
                                                if (subCategory.slug == 'technician-marketplace' ||
                                                    subCategory.name!.toLowerCase().contains('technician')) {
                                                  Navigator.pushNamed(context, Routes.technicianMarketplace);
                                                  return;
                                                }
                                                if (subCategory.children!.isEmpty &&
                                                    subCategory.subcategoriesCount == 0) {
                                                  Navigator.pushNamed(
                                                    context,
                                                    Routes.itemsList,
                                                    arguments: {
                                                      'catID': subCategory.id.toString(),
                                                      'catName': subCategory.name,
                                                      "categoryIds": [
                                                        selectedCategory.id.toString(),
                                                        subCategory.id.toString(),
                                                      ],
                                                    },
                                                  );
                                                } else {
                                                  Navigator.pushNamed(
                                                    context,
                                                    Routes.subCategoryScreen,
                                                    arguments: {
                                                      "categoryList": subCategory.children,
                                                      "catName": subCategory.name,
                                                      "catId": subCategory.id,
                                                      "categoryIds": [
                                                        selectedCategory.id.toString(),
                                                        subCategory.id.toString(),
                                                      ],
                                                    },
                                                  );
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: context.color.primaryColor,
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.02),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Expanded(
                                                      flex: 3,
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(15.0),
                                                        child: UiUtils.getImage(
                                                          subCategory.url!,
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      flex: 1,
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                                        decoration: BoxDecoration(
                                                          color: context.color.secondaryColor.withValues(alpha: 0.05),
                                                          borderRadius: const BorderRadius.only(
                                                            bottomLeft: Radius.circular(20),
                                                            bottomRight: Radius.circular(20),
                                                          ),
                                                        ),
                                                        child: Center(
                                                          child: CustomText(
                                                            subCategory.name!,
                                                            textAlign: TextAlign.center,
                                                            fontSize: 11,
                                                            fontWeight: FontWeight.w600,
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}