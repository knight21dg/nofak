import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/fetch_technicians_cubit.dart';
import 'package:nofak/data/cubits/location/leaf_location_cubit.dart';
import 'package:nofak/data/model/user/user_model.dart';
import 'package:nofak/ui/screens/home/widgets/nearby_technician_card.dart';
import 'package:nofak/ui/screens/widgets/errors/no_data_found.dart';
import 'package:nofak/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';

class TechnicianMarketplaceScreen extends StatefulWidget {
  const TechnicianMarketplaceScreen({super.key});

  @override
  State<TechnicianMarketplaceScreen> createState() => _TechnicianMarketplaceScreenState();
}

class _TechnicianMarketplaceScreenState extends State<TechnicianMarketplaceScreen> {
  late ScrollController controller;
  late TextEditingController _searchController;
  Timer? _searchDelay;
  String? sortBy = 'distance';

  final List<Map<String, dynamic>> _expertiseFilters = [
    {'name': 'All', 'slug': ''},
    {'name': 'AC', 'slug': 'ac'},
    {'name': 'Plumbing', 'slug': 'plumbing'},
    {'name': 'Electrical', 'slug': 'electrical'},
    {'name': 'Electronics', 'slug': 'electronics'},
    {'name': 'Vehicle', 'slug': 'cars'},
  ];

  String _selectedFilter = '';

  @override
  void initState() {
    super.initState();
    controller = ScrollController();
    controller.addListener(_loadMore);
    _searchController = TextEditingController();
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchTechnicians();
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _searchController.dispose();
    _searchDelay?.cancel();
    super.dispose();
  }

  void _fetchTechnicians() {
    final leafLocation = context.read<LeafLocationCubit>().state;
    context.read<FetchTechniciansCubit>().fetchTechnicians(
          lat: leafLocation?.latitude,
          lng: leafLocation?.longitude,
          category: _selectedFilter,
          search: _searchController.text,
          sortBy: sortBy,
        );
  }

  void _loadMore() {
    if (controller.isEndReached()) {
      if (context.read<FetchTechniciansCubit>().hasMoreData()) {
        final leafLocation = context.read<LeafLocationCubit>().state;
        context.read<FetchTechniciansCubit>().fetchMoreTechnicians(
              lat: leafLocation?.latitude,
              lng: leafLocation?.longitude,
              category: _selectedFilter,
              search: _searchController.text,
              sortBy: sortBy,
            );
      }
    }
  }

  void _onSearchChanged(String query) {
    _searchDelay?.cancel();
    _searchDelay = Timer(const Duration(milliseconds: 500), () {
      _fetchTechnicians();
    });
  }

  @override
  Widget build(BuildContext context) {
    return bodyWidget();
  }

  Widget bodyWidget() {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        backgroundColor: context.color.primaryColor,
        appBar: AppBar(
          titleSpacing: 0,
          title: CustomText("Technician Directory".translate(context), maxLines: 1),
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh_rounded,
                color: context.color.textDefaultColor,
              ),
              onPressed: _fetchTechnicians,
            ),
          ],
        ),
        bottomNavigationBar: bottomWidget(),
        body: Column(
          children: [
            searchBarWidget(),
            filterChipsWidget(),
            locationInfoWidget(),
            Expanded(child: fetchTechniciansList()),
          ],
        ),
      ),
    );
  }

  Widget searchBarWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: context.color.textLightColor.withValues(alpha: 0.1),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: "searchTechniciansHint".translate(context).isEmpty
                ? "Search by name, skills or address..."
                : "searchTechniciansHint".translate(context),
            prefixIcon: Icon(Icons.search, color: context.color.textLightColor),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.color.textLightColor),
                    onPressed: () {
                      _searchController.clear();
                      _fetchTechnicians();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget filterChipsWidget() {
    return Container(
      height: 50,
      color: context.color.primaryColor,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: _expertiseFilters.map((filter) {
            final isSelected = _selectedFilter == filter['slug'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter['slug'];
                  });
                  _fetchTechnicians();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? context.color.territoryColor 
                        : context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? context.color.territoryColor 
                          : context.color.textLightColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    filter['name'],
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white 
                          : context.color.textDefaultColor,
                      fontSize: context.font.small,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget locationInfoWidget() {
    final leafLocation = context.watch<LeafLocationCubit>().state;
    final hasCoords = leafLocation?.latitude != null && leafLocation?.longitude != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: context.color.secondaryColor.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(
            hasCoords ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
            size: 16,
            color: hasCoords ? Colors.green : Colors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CustomText(
              hasCoords
                  ? "Showing technicians near ${leafLocation?.primaryText ?? 'your location'}"
                  : "GPS not set. Showing all technicians. Tap to set location.",
              fontSize: context.font.smaller,
              color: context.color.textDefaultColor.withValues(alpha: 0.8),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, Routes.locationScreen).then((value) {
                _fetchTechnicians();
              });
            },
            child: CustomText(
              "Change",
              color: context.color.territoryColor,
              fontWeight: FontWeight.bold,
              fontSize: context.font.small,
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomWidget() {
    return SafeArea(
      bottom: Platform.isAndroid,
      child: ColoredBox(
        color: context.color.secondaryColor,
        child: SizedBox(
          height: 45 + (Platform.isIOS ? MediaQuery.of(context).padding.bottom : 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, Routes.locationScreen).then((value) {
                        _fetchTechnicians();
                      });
                    },
                    icon: Icon(Icons.location_on, color: context.color.textDefaultColor),
                    label: CustomText("Location".translate(context)),
                  ),
                ),
                VerticalDivider(
                  color: context.color.textLightColor.withValues(alpha: 0.3),
                ),
                Expanded(child: sortByWidget()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget sortByWidget() {
    return TextButton.icon(
      onPressed: showSortByBottomSheet,
      icon: Icon(Icons.sort_rounded, color: context.color.textDefaultColor),
      label: CustomText('sortBy'.translate(context)),
    );
  }

  void showSortByBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.color.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 17,
                ),
                child: CustomText(
                  'sortBy'.translate(context),
                  textAlign: TextAlign.start,
                  fontWeight: FontWeight.bold,
                  fontSize: context.font.large,
                ),
              ),
              const Divider(height: 1),
              sortByItemWidget('Distance', "distance"),
              const Divider(height: 1),
              sortByItemWidget('Average Rating', "rating"),
              const Divider(height: 1),
              sortByItemWidget('Jobs Completed', "jobs"),
            ],
          ),
        );
      },
    );
  }

  Widget sortByItemWidget(String title, String value) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        setState(() {
          sortBy = value;
        });
        _fetchTechnicians();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          children: [
            CustomText(
              title,
              fontSize: context.font.large,
            ),
            const Spacer(),
            if (sortBy == value)
              Icon(
                Icons.check,
                color: context.color.territoryColor,
              ),
          ],
        ),
      ),
    );
  }

  Widget fetchTechniciansList() {
    return BlocBuilder<FetchTechniciansCubit, FetchTechniciansState>(
      builder: (context, state) {
        if (state is FetchTechniciansInProgress) {
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: 5,
            itemBuilder: (context, index) {
              return buildShimmerCard();
            },
          );
        }

        if (state is FetchTechniciansFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomText(state.errorMessage, textAlign: TextAlign.center),
            ),
          );
        }

        if (state is FetchTechniciansSuccess) {
          if (state.technicians.isEmpty) {
            return Center(
              child: NoDataFound(
                onTap: _fetchTechnicians,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: state.technicians.length,
                  itemBuilder: (context, index) {
                    final tech = state.technicians[index];
                    return NearbyTechnicianCard(technician: tech);
                  },
                ),
              ),
              if (state.isLoadingMore) UiUtils.progress(),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget buildShimmerCard() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(width: 1.5, color: context.color.borderColor),
        color: context.color.secondaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const CustomShimmer(height: 70, width: 70, borderRadius: 35),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomShimmer(width: context.screenWidth * 0.4, height: 12, borderRadius: 7),
                const SizedBox(height: 8),
                CustomShimmer(width: context.screenWidth * 0.3, height: 10, borderRadius: 7),
                const SizedBox(height: 8),
                CustomShimmer(width: context.screenWidth * 0.25, height: 10, borderRadius: 7),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
