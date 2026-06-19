// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:nofak/app/app_theme.dart';
import 'package:nofak/data/cubits/favorite/favorite_cubit.dart';
import 'package:nofak/data/cubits/favorite/manage_fav_cubit.dart';
import 'package:nofak/data/cubits/system/app_theme_cubit.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/data/repositories/item/favourites_repository.dart';
import 'package:nofak/ui/screens/widgets/promoted_widget.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

class ItemHorizontalCard extends StatefulWidget {
  final ItemModel item;
  final List<Widget>? addBottom;
  final double? additionalHeight;
  final StatusButton? statusButton;
  final bool? useRow;
  final VoidCallback? onDeleteTap;
  final double? additionalImageWidth;
  final bool? showLikeButton;

  const ItemHorizontalCard({
    super.key,
    required this.item,
    this.useRow,
    this.addBottom,
    this.additionalHeight,
    this.statusButton,
    this.onDeleteTap,
    this.showLikeButton,
    this.additionalImageWidth,
  });

  @override
  State<ItemHorizontalCard> createState() => _ItemHorizontalCardState();
}

class _ItemHorizontalCardState extends State<ItemHorizontalCard> {
  late final UpdateFavoriteCubit _updateFavoriteCubit;

  @override
  void initState() {
    super.initState();
    _updateFavoriteCubit = UpdateFavoriteCubit(FavoriteRepository());
  }

  @override
  void dispose() {
    _updateFavoriteCubit.close();
    super.dispose();
  }

  Widget favButton(BuildContext context) {
    bool isLike = context.read<FavoriteCubit>().isItemFavorite(widget.item.id!);
    return BlocProvider.value(
      value: _updateFavoriteCubit,
      child: BlocConsumer<FavoriteCubit, FavoriteState>(
        bloc: context.read<FavoriteCubit>(),
        listener: ((context, state) {
          if (state is FavoriteFetchSuccess) {
            isLike = context.read<FavoriteCubit>().isItemFavorite(widget.item.id!);
          }
        }),
        builder: (context, likeAndDislikeState) {
          return BlocConsumer<UpdateFavoriteCubit, UpdateFavoriteState>(
            bloc: _updateFavoriteCubit,
            listener: ((context, state) {
              if (state is UpdateFavoriteSuccess && state.item.id == widget.item.id!) {
                if (state.wasProcess) {
                  context.read<FavoriteCubit>().addFavoriteitem(state.item);
                } else {
                  context.read<FavoriteCubit>().removeFavoriteItem(state.item);
                }
              }
            }),
            builder: (context, state) {
              return InkWell(
                onTap: () {
                  UiUtils.checkUser(
                    onNotGuest: () {
                      _updateFavoriteCubit.setFavoriteItem(
                        item: widget.item,
                        type: isLike ? 0 : 1,
                      );
                    },
                    context: context,
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    shape: BoxShape.circle,
                    boxShadow:
                        context.read<AppThemeCubit>().state == AppTheme.dark
                        ? null
                        : [
                            BoxShadow(
                              color: Color.fromARGB(12, 0, 0, 0),
                              offset: Offset(0, 2),
                              blurRadius: 10,
                              spreadRadius: 4,
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
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.5),
        child: Container(
          height: widget.addBottom == null ? 124 : (124 + (widget.additionalHeight ?? 0)),
          decoration: BoxDecoration(
            border: Border.all(
              color: context.color.textLightColor.withValues(alpha: 0.28),
            ),
            color: context.color.secondaryColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Column(
                          children: [
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: UiUtils.getImage(
                                    widget.item.image ?? "",
                                    height: widget.addBottom == null
                                        ? 122
                                        : (122 + (widget.additionalHeight ?? 0)),
                                    width: 100 + (widget.additionalImageWidth ?? 0),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // CustomText(item.promoted.toString()),
                                  if (widget.item.isFeature ?? false)
                                    const PositionedDirectional(
                                      start: 5,
                                      top: 5,
                                      child: PromotedCard(
                                        type: PromoteCardType.icon,
                                      ),
                                    ),
                                  if (widget.item.videoLink != null &&
                                      widget.item.videoLink!.isNotEmpty)
                                    Positioned.fill(
                                      child: Center(
                                        child: Opacity(
                                          opacity: 0.6,
                                          child: CircleAvatar(
                                            backgroundColor: Colors.black26,
                                            radius: 18,
                                            child: Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                            if (widget.statusButton != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3.0,
                                  horizontal: 3.0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: widget.statusButton!.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  width: 80,
                                  height: 120 - 90 - 8,
                                  child: Center(
                                    child: CustomText(
                                      widget.statusButton!.lable,
                                      fontSize: context.font.small,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          widget.statusButton?.textColor ?? Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              top: 0,
                              start: 12,
                              bottom: 5,
                              end: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Row(
                                  children: [
                                    if (UiUtils.displayPrice(widget.item))
                                      Expanded(
                                        child: UiUtils.getPriceWidget(
                                          widget.item,
                                          context,
                                        ),
                                      )
                                    else
                                      Expanded(
                                        child: CustomText(
                                          widget.item.translatedName ?? "",
                                          maxLines: 2,
                                          firstUpperCaseWidget: true,
                                        ),
                                      ),
                                    if (widget.showLikeButton ?? true)
                                      favButton(context),
                                  ],
                                ),
                                if (UiUtils.displayPrice(widget.item))
                                  CustomText(
                                    widget.item.translatedName!.firstUpperCase(),
                                    fontSize: context.font.normal,
                                    color: context.color.textDefaultColor,
                                    maxLines: 2,
                                  ),
                                if (widget.item.translatedAddress != "")
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: context.color.textDefaultColor
                                            .withValues(alpha: 0.5),
                                      ),
                                      Expanded(
                                        child: CustomText(
                                          UiUtils.formatDisplayAddress(
                                            widget.item.translatedAddress ?? '',
                                          ),
                                          fontSize: context.font.smaller,
                                          color: context.color.textDefaultColor
                                              .withValues(alpha: 0.5),
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (widget.item.created != null && widget.item.created != '')
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 12,
                                        color: context.color.textDefaultColor
                                            .withValues(alpha: 0.5),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                start: 2.0,
                                              ),
                                          child: Timeago(
                                            locale: Constant.currentLocale,
                                            builder: (context, data) =>
                                                CustomText(
                                                  data,
                                                  fontSize: context.font.smaller,
                                                  color: context
                                                      .color
                                                      .textDefaultColor
                                                      .withValues(alpha: 0.5),
                                                  maxLines: 1,
                                                ),
                                            date: DateTime.parse(widget.item.created!),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.useRow == false || widget.useRow == null) ...widget.addBottom ?? [],
                  if (widget.useRow == true) ...{Row(children: widget.addBottom ?? [])},
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusButton {
  final String lable;
  final Color color;
  final Color? textColor;

  StatusButton({required this.lable, required this.color, this.textColor});
}
