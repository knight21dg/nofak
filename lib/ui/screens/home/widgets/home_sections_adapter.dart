import 'package:nofak/app/app_theme.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/favorite/favorite_cubit.dart';
import 'package:nofak/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:nofak/data/cubits/system/app_theme_cubit.dart';
import 'package:nofak/data/model/home/home_screen_section_model.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/data/repositories/item/favourites_repository.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/ui/screens/home/widgets/grid_list_adapter.dart';
import 'package:nofak/ui/screens/widgets/promoted_widget.dart';
import 'package:nofak/ui/screens/widgets/video_view_screen.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:nofak/ui/screens/home/widgets/technician_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class HomeSectionsAdapter extends StatelessWidget {
  final HomeScreenSection section;

  const HomeSectionsAdapter({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    if (section.style == "style_1") {
      return section.sectionData!.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.sectionWiseItemsScreen,
                      arguments: {
                        "title": section.title,
                        "sectionId": section.sectionId,
                      },
                    );
                  },
                  // section: section,
                ),
                GridListAdapter(
                  type: ListUiType.List,
                  height: MediaQuery.of(context).size.height / 3.2,
                  listAxis: Axis.horizontal,
                  listSeparator: (BuildContext p0, int p1) =>
                      const SizedBox(width: 14),
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return _buildCard(item);
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else if (section.style == "style_2") {
      return section.sectionData!.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.sectionWiseItemsScreen,
                      arguments: {
                        "title": section.title,
                        "sectionId": section.sectionId,
                      },
                    );
                  },
                ),
                GridListAdapter(
                  type: ListUiType.List,
                  height: MediaQuery.of(context).size.height / 3.2,
                  listAxis: Axis.horizontal,
                  listSeparator: (BuildContext p0, int p1) =>
                      const SizedBox(width: 14),
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return _buildCard(item, width: 144);
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else if (section.style == "style_3") {
      return section.sectionData!.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.sectionWiseItemsScreen,
                      arguments: {
                        "title": section.title,
                        "sectionId": section.sectionId,
                      },
                    );
                  },
                ),
                GridListAdapter(
                  type: ListUiType.Grid,
                  crossAxisCount: 2,
                  height: MediaQuery.of(context).size.height / 3.2,
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return _buildCard(item, width: 192);
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else if (section.style == "style_4") {
      return section.sectionData!.isNotEmpty
          ? Column(
              children: [
                TitleHeader(
                  title: section.title ?? "",
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      Routes.sectionWiseItemsScreen,
                      arguments: {
                        "title": section.title,
                        "sectionId": section.sectionId,
                      },
                    );
                  },
                ),
                GridListAdapter(
                  type: ListUiType.List,
                  height: MediaQuery.of(context).size.height / 3.2,
                  listAxis: Axis.horizontal,
                  listSeparator: (BuildContext p0, int p1) =>
                      const SizedBox(width: 14),
                  builder: (context, int index, bool) {
                    ItemModel? item = section.sectionData?[index];

                    return _buildCard(item, width: 192);
                  },
                  total: section.sectionData?.length ?? 0,
                ),
              ],
            )
          : SizedBox.shrink();
    } else {
      return Container();
    }
  }

  Widget _buildCard(ItemModel? item, {double? width}) {
    if (item == null) return const SizedBox.shrink();

    // Check if item belongs to Technician Marketplace category
    bool isTechnician = item.category?.slug == 'technician-marketplace' ||
        item.category?.name?.toLowerCase().contains('technician') == true ||
        item.category?.name?.toLowerCase().contains('professional') == true;

    if (isTechnician) {
      return TechnicianCard(item: item, width: width);
    }
    return ItemCard(item: item, width: width);
  }
}

class TitleHeader extends StatelessWidget {
  final String title;
  final Function() onTap;
  final bool? hideSeeAll;

  const TitleHeader({
    super.key,
    required this.title,
    required this.onTap,
    this.hideSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        top: 18,
        bottom: 12,
        start: sidePadding,
        end: sidePadding,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: CustomText(
              title,
              fontSize: context.font.larger,
              fontWeight: FontWeight.w600,
              maxLines: 1,
            ),
          ),
          const Spacer(),
          if (!(hideSeeAll ?? false))
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2.2,
                ),
                child: CustomText(
                  "seeAll".translate(context),
                  fontSize: context.font.smaller + 1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ItemCard extends StatefulWidget {
  final double? width;
  final bool? bigCard;
  final ItemModel? item;

  const ItemCard({super.key, required this.item, this.width, this.bigCard});

  @override
  _ItemCardState createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  double likeButtonSize = 32;
  FlickManager? flickManager;
  bool isVideoPlaying = false;
  late final UpdateFavoriteCubit _updateFavoriteCubit;

  @override
  void initState() {
    super.initState();
    _updateFavoriteCubit = UpdateFavoriteCubit(FavoriteRepository());
  }

  @override
  void dispose() {
    flickManager?.dispose();
    _updateFavoriteCubit.close();
    super.dispose();
  }

  bool get _hasVideo => widget.item?.videoLink != null && widget.item!.videoLink!.trim().isNotEmpty && !HelperUtils.isYoutubeVideo(widget.item!.videoLink!);

  void _playVideo() {
    if (_hasVideo && !isVideoPlaying) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(widget.item!.videoLink!),
        ),
      );
      flickManager?.onVideoEnd = () {
        if (mounted) {
          setState(() {
            isVideoPlaying = false;
          });
          flickManager?.dispose();
          flickManager = null;
        }
      };
      setState(() {
        isVideoPlaying = true;
      });
    }
  }

   @override
   Widget build(BuildContext context) {
     return RepaintBoundary(
       child: GestureDetector(
         onTap: () {
           Navigator.pushNamed(
             context,
             Routes.adDetailsScreen,
             arguments: {"model": widget.item},
           );
         },
         child: Container(
          width: widget.width ?? 250,
          decoration: BoxDecoration(
            border: Border.all(
              color: context.color.textLightColor.withValues(alpha: 0.13),
              width: 1,
            ),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (isVideoPlaying && flickManager != null)
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height / 5.45,
                      width: double.infinity,
                      child: FlickVideoPlayer(flickManager: flickManager!),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: UiUtils.getImage(
                        widget.item?.image ?? "",
                        height: MediaQuery.sizeOf(context).height / 5.45,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  if (widget.item?.isFeature ?? false)
                    const PositionedDirectional(
                      start: 10,
                      top: 5,
                      child: PromotedCard(type: PromoteCardType.icon),
                    ),
                  if (!isVideoPlaying && _hasVideo)
                    Positioned.fill(
                      child: Center(
                        child: GestureDetector(
                          onTap: _playVideo,
                          child: Opacity(
                            opacity: 0.6,
                            child: CircleAvatar(
                              backgroundColor: Colors.black26,
                              radius: 20,
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  favButton(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (UiUtils.displayPrice(widget.item!))
                      UiUtils.getPriceWidget(widget.item!, context),
                    CustomText(
                      widget.item!.translatedName!,
                      fontSize: context.font.larger,
                      maxLines: 1,
                      firstUpperCaseWidget: true,
                    ),
                    if (widget.item?.translatedAddress != "")
                      Row(
                        children: [
                          UiUtils.getSvg(
                            AppIcons.location,
                            width: widget.bigCard == true ? 10 : 8,
                            height: widget.bigCard == true ? 13 : 11,
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: 3.0),
                              child: CustomText(
                                UiUtils.formatDisplayAddress(
                                  widget.item?.translatedAddress ?? '',
                                ),
                                fontSize: (widget.bigCard == true)
                                    ? context.font.small
                                    : context.font.smaller,
                                color: context.color.textDefaultColor
                                    .withValues(alpha: 0.5),
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (widget.item?.created != "")
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: widget.bigCard == true ? 12 : 10,
                            color: context.color.textDefaultColor.withValues(
                              alpha: 0.3,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.only(start: 3.0),
                              child: Timeago(
                                locale: Constant.currentLocale,
                                builder: (context, data) => CustomText(
                                  data,
                                  fontSize: (widget.bigCard == true)
                                      ? context.font.small
                                      : context.font.smaller,
                                  color: context.color.textDefaultColor
                                      .withValues(alpha: 0.5),
                                  maxLines: 1,
                                ),
                                date: DateTime.parse(widget.item!.created!),
                              ),
                            ),
                          ),
                        ],
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

  Widget favButton() {
    bool isLike = context.read<FavoriteCubit>().isItemFavorite(
      widget.item!.id!,
    );

    return BlocProvider.value(
      value: _updateFavoriteCubit,
      child: BlocConsumer<FavoriteCubit, FavoriteState>(
        bloc: context.read<FavoriteCubit>(),
        listener: ((context, state) {
          if (state is FavoriteFetchSuccess) {
            isLike = context.read<FavoriteCubit>().isItemFavorite(
              widget.item!.id!,
            );
          }
        }),
        builder: (context, likeAndDislikeState) {
          return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
            bloc: _updateFavoriteCubit,
            listener: ((context, state) {
              if (state is UpdateFavoriteSuccess && state.item.id == widget.item!.id!) {
                if (state.wasProcess) {
                  context.read<FavoriteCubit>().addFavoriteitem(state.item);
                } else {
                  context.read<FavoriteCubit>().removeFavoriteItem(state.item);
                }
              }
            }),
            builder: (context, state) {
              return PositionedDirectional(
                bottom: -10,
                end: 16,
                child: InkWell(
                  onTap: () {
                    UiUtils.checkUser(
                      onNotGuest: () {
                        context.read<UpdateFavoriteCubit>().setFavoriteItem(
                          item: widget.item!,
                          type: isLike ? 0 : 1,
                        );
                      },
                      context: context,
                    );
                  },
                  child: Container(
                    width: likeButtonSize,
                    height: likeButtonSize,
                    decoration: BoxDecoration(
                      color: context.color.secondaryColor,
                      shape: BoxShape.circle,
                      boxShadow:
                          context.read<AppThemeCubit>().state == AppTheme.dark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.grey[300]!,
                                offset: const Offset(0, 2),
                                spreadRadius: 2,
                                blurRadius: 4,
                                  ),
                                ],
                    ),
                    child: FittedBox(
                      fit: BoxFit.none,
                      child: state is UpdateFavoriteInProgress
                          ? Center(child: UiUtils.progress())
                          : UiUtils.getSvg(
                              isLike ? AppIcons.like_fill : AppIcons.like,
                              width: 22,
                              height: 22,
                              color: context.color.territoryColor,
                            ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
