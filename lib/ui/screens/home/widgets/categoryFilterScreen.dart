import 'package:nofak/data/cubits/category/fetch_category_cubit.dart';
import 'package:nofak/data/model/category_model.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryFilterScreen extends StatefulWidget {
  const CategoryFilterScreen({super.key});

  @override
  State<CategoryFilterScreen> createState() => _CategoryFilterScreenState();

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (_) => const CategoryFilterScreen(),
    );
  }
}

class _CategoryFilterScreenState extends State<CategoryFilterScreen>
    with TickerProviderStateMixin {
  final ScrollController _pageScrollController = ScrollController();
  final ValueNotifier<int> _selectedCategoryIndex = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _pageScrollController.addListener(() {
      if (_pageScrollController.position.pixels == _pageScrollController.position.maxScrollExtent) {
        if (context.read<FetchCategoryCubit>().hasMoreData()) {
          context.read<FetchCategoryCubit>().fetchCategoriesMore();
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
    return Scaffold(
      backgroundColor: context.color.primaryColor,
      appBar: AppBar(
        backgroundColor: context.color.secondaryColor,
        elevation: 0,
        leadingWidth: 100,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: CustomText(
              "back".translate(context),
              color: context.color.textDefaultColor.withValues(alpha: 0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        title: Align(
          alignment: Alignment.centerRight,
          child: CustomText(
            "classifieds".translate(context),
            color: context.color.textDefaultColor.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<FetchCategoryCubit, FetchCategoryState>(
          builder: (context, state) {
            if (state is FetchCategoryInProgress) {
              return UiUtils.progress();
            }
            if (state is FetchCategorySuccess) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar
                  Container(
                    width: 100,
                    decoration: BoxDecoration(
                      color: context.color.primaryColor,
                      border: Border(
                        right: BorderSide(
                          color: context.color.borderColor.withValues(
                            alpha: 0.05,
                          ),
                        ),
                      ),
                    ),
                    child: ListView.builder(
                      itemCount: state.categories.length,
                      itemBuilder: (context, index) {
                        return ValueListenableBuilder(
                          valueListenable: _selectedCategoryIndex,
                          builder: (context, selectedIndex, _) {
                            bool isSelected = selectedIndex == index;
                            return GestureDetector(
                              onTap: () {
                                _selectedCategoryIndex.value = index;
                              },
                              child: Container(
                                width: 80,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? context.color.territoryColor
                                          .withValues(alpha: 0.05)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? context.color.territoryColor
                                            .withValues(alpha: 0.4)
                                        : context.color.borderColor
                                            .withValues(alpha: 0.05),
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    UiUtils.getImage(
                                      state.categories[index].url!,
                                      height: 28,
                                      width: 28,
                                    ),
                                    const SizedBox(height: 10),
                                    CustomText(
                                      state.categories[index].name!,
                                      textAlign: TextAlign.center,
                                      fontSize: 9,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? context.color.territoryColor
                                          : context.color.textDefaultColor
                                              .withValues(alpha: 0.7),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                  // Sub-category Grid
                  Expanded(
                    child: Container(
                      color: context.color.secondaryColor.withValues(
                        alpha: 0.3,
                      ),
                      child: ValueListenableBuilder(
                        valueListenable: _selectedCategoryIndex,
                        builder: (context, selectedIndex, _) {
                          CategoryModel selectedCategory =
                              state.categories[selectedIndex];
                          List<CategoryModel> subCategories =
                              selectedCategory.children ?? [];

                          if (subCategories.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText(
                                    "noSubCategories".translate(context),
                                    color: context.color.textDefaultColor
                                        .withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          context.color.territoryColor,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: CustomText(
                                      "selectLbl".translate(context),
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: subCategories.length,
                            itemBuilder: (context, index) {
                              CategoryModel subCategory = subCategories[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.color.primaryColor,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: context.color.borderColor
                                          .withValues(alpha: 0.08),
                                    ),
                                  ),
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: UiUtils.getImage(
                                        subCategory.url!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            }
            return Container();
          },
        ),
      ),
    );
  }
}