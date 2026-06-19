import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/seller/fetch_seller_item_cubit.dart';
import 'package:nofak/data/cubits/seller/fetch_seller_ratings_cubit.dart';
import 'package:nofak/data/model/item/item_model.dart';
import 'package:nofak/data/model/user/seller_ratings_model.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/ui/screens/home/widgets/home_sections_adapter.dart';
import 'package:nofak/ui/screens/widgets/errors/no_data_found.dart';
import 'package:nofak/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:nofak/ui/screens/widgets/shimmer_loading_container.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/custom_hero_animation.dart';
import 'package:nofak/utils/custom_silver_grid_delegate.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/helper_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flick_video_player/flick_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:nofak/data/cubits/manage_job_request_cubit.dart';
import 'package:nofak/ui/screens/widgets/video_view_screen.dart';
import 'package:nofak/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:nofak/data/cubits/chat/send_message.dart';
import 'package:nofak/data/cubits/chat/load_chat_messages.dart';
import 'package:nofak/data/cubits/chat/delete_message_cubit.dart';
import 'package:nofak/ui/screens/chat/chat_screen.dart';
import 'package:nofak/data/model/chat/chat_user_model.dart' as chat_model;
import 'package:nofak/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:nofak/data/cubits/auth/user_profile_cubit.dart';
import 'package:nofak/data/cubits/system/user_details.dart';
import 'package:nofak/data/cubits/location/leaf_location_cubit.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:nofak/ui/screens/widgets/blurred_dialog_box.dart';
import 'package:nofak/utils/widgets.dart';

class SellerProfileScreen extends StatefulWidget {
  final int sellerId;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
  });

  @override
  SellerProfileScreenState createState() => SellerProfileScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider(
                  create: (context) => FetchSellerItemsCubit(),
                ),
                BlocProvider(
                  create: (context) => FetchSellerRatingsCubit(),
                ),
                BlocProvider(
                  create: (context) => MakeAnOfferItemCubit(),
                ),
              ],
              child: SellerProfileScreen(
                sellerId: arguments?['sellerId'],
              ),
            ));
  }
}

class SellerProfileScreenState extends State<SellerProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  FlickManager? _flickManager;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      setState(() {});
    });

    context.read<FetchSellerItemsCubit>().fetch(sellerId: widget.sellerId);
    context.read<FetchSellerRatingsCubit>().fetch(sellerId: widget.sellerId);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _flickManager?.dispose();
    super.dispose();
  }

  void _loadMore() async {
    if (context.read<FetchSellerItemsCubit>().hasMoreData()) {
      context
          .read<FetchSellerItemsCubit>()
          .fetchMore(sellerId: widget.sellerId);
    }
  }

  void _reviewLoadMore() async {
    if (context.read<FetchSellerRatingsCubit>().hasMoreData()) {
      context
          .read<FetchSellerRatingsCubit>()
          .fetchMore(sellerId: widget.sellerId);
    }
  }

  void _showHireSheet(Seller technician) {
    final TextEditingController descController = TextEditingController();
    final TextEditingController addrController = TextEditingController(
      text: HiveUtils.getUserDetails().address ?? "",
    );
    final TextEditingController feeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.color.secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.color.textLightColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText(
                  "Hire ${technician.name}",
                  fontSize: context.font.larger,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 15),
                CustomText(
                  "Job Description *",
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: "Explain what service you need (e.g. AC leaking, Car inspection)...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText(
                  "Service Address *",
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: addrController,
                  decoration: InputDecoration(
                    hintText: "Enter service location address...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                CustomText(
                  "Proposed Fee (Optional)",
                  fontSize: context.font.small,
                  color: context.color.textLightColor,
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Enter proposed fee amount...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                UiUtils.buildButton(
                  context,
                  buttonTitle: "Send Request",
                  onPressed: () {
                    if (descController.text.trim().isEmpty) {
                      HelperUtils.showSnackBarMessage(context, "Please enter a job description.");
                      return;
                    }
                    if (addrController.text.trim().isEmpty) {
                      HelperUtils.showSnackBarMessage(context, "Please enter a service address.");
                      return;
                    }

                    Navigator.pop(bottomSheetContext);

                    final leafLocation = context.read<LeafLocationCubit>().state;
                    final proposedFee = double.tryParse(feeController.text.trim());

                    context.read<ManageJobRequestCubit>().submitJobRequest(
                          technicianId: technician.id!,
                          description: descController.text.trim(),
                          address: addrController.text.trim(),
                          latitude: leafLocation?.latitude,
                          longitude: leafLocation?.longitude,
                          proposedFee: proposedFee,
                        );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  void _proceedToChat(Seller technician) {
    chat_model.ChatUser? chatedUser = context.read<GetBuyerChatListCubit>().getOfferForItem(0); // Dummy item ID check
    // Wait, let's check by technician ID in buyer chat list!
    final chatList = context.read<GetBuyerChatListCubit>().state;
    if (chatList is GetBuyerChatListSuccess) {
      final existingChat = chatList.chatedUserList.firstWhere(
        (c) => c.sellerId == technician.id || c.buyerId == technician.id,
        orElse: () => chat_model.ChatUser(),
      );
      if (existingChat.id != null) {
        chatedUser = existingChat;
      }
    }

    if (chatedUser != null && chatedUser.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return MultiBlocProvider(
              providers: [
                BlocProvider(create: (context) => SendMessageCubit()),
                BlocProvider(create: (context) => LoadChatMessagesCubit()),
                BlocProvider(create: (context) => DeleteMessageCubit()),
              ],
              child: ChatScreen(
                itemId: chatedUser!.itemId.toString(),
                profilePicture: chatedUser.seller != null && chatedUser.seller!.profile != null
                    ? chatedUser.seller!.profile!
                    : (chatedUser.buyer != null && chatedUser.buyer!.profile != null
                        ? chatedUser.buyer!.profile!
                        : ""),
                userName: chatedUser.seller != null && chatedUser.seller!.name != null
                    ? chatedUser.seller!.name!
                    : (chatedUser.buyer != null && chatedUser.buyer!.name != null
                        ? chatedUser.buyer!.name!
                        : ""),
                date: chatedUser.createdAt!,
                itemOfferId: chatedUser.id!,
                itemPrice: null,
                itemOfferPrice: chatedUser.amount,
                itemImage: chatedUser.item != null ? chatedUser.item!.image ?? "" : "",
                itemTitle: chatedUser.item != null ? chatedUser.item!.name?.localized ?? "" : "",
                userId: chatedUser.sellerId.toString() == HiveUtils.getUserId()
                    ? chatedUser.buyerId.toString()
                    : chatedUser.sellerId.toString(),
                buyerId: chatedUser.buyerId.toString(),
                status: "approved",
                from: "item",
                isPurchased: 0,
                alreadyReview: false,
                isFromBuyerList: true,
              ),
            );
          },
        ),
      );
    } else {
      // Wallet Credit Check
      final userAuth = HiveUtils.getUserDetails();
      final chatDeduction = int.tryParse(
              context.read<FetchSystemSettingsCubit>().getRawSettings()['chat_deduction']?.toString() ?? '5') ??
          5;

      if ((userAuth.credits ?? 0) < chatDeduction) {
        UiUtils.showBlurredDialoge(
          context,
          dialoge: BlurredDialogBox(
            title: "Recharge Required".translate(context),
            content: CustomText(
              "Initiating this chat requires $chatDeduction NOFAK Credits. Your current balance is ${userAuth.credits}."
                  .translate(context),
            ),
            acceptButtonName: "Recharge".translate(context),
            onAccept: () async {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.creditPackagesRoute);
            },
          ),
        );
        return;
      }

      // Initiate first time chat through MakeAnOfferItemCubit
      context.read<MakeAnOfferItemCubit>().makeAnOfferItem(
            technicianId: technician.id!,
            from: "chat",
          );
    }
  }

  Widget buildTechnicianProfile(Seller technician, FetchSellerRatingsSuccess ratingsState) {
    // Skills split
    final List<String> skillsList = technician.skills != null && technician.skills!.isNotEmpty
        ? technician.skills!.split(',').map((e) => e.trim()).toList()
        : [];

    Color availabilityColor = Colors.grey;
    if (technician.availabilityStatus == "available") {
      availabilityColor = Colors.green;
    } else if (technician.availabilityStatus == "busy") {
      availabilityColor = Colors.amber;
    }

    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: AppBar(
        backgroundColor: context.color.secondaryColor,
        elevation: 0,
        title: CustomText("Technician Profile", fontWeight: FontWeight.bold),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.color.textDefaultColor),
        ),
        actions: [
          IconButton(
            onPressed: () {
              HelperUtils.shareItem(context, "seller", widget.sellerId.toString());
            },
            icon: Icon(Icons.share, color: context.color.textDefaultColor),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: context.color.secondaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Chat button
            Container(
              decoration: BoxDecoration(
                color: context.color.territoryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.chat_bubble_outline_rounded, color: context.color.territoryColor),
                onPressed: () {
                  UiUtils.checkUser(
                    onNotGuest: () => _proceedToChat(technician),
                    context: context,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Call button
            Container(
              decoration: BoxDecoration(
                color: context.color.forthColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.call_outlined, color: context.color.forthColor),
                onPressed: () async {
                  if (technician.mobile != null && technician.mobile!.isNotEmpty) {
                    final Uri launchUri = Uri.parse("tel:${technician.mobile}");
                    if (await canLaunchUrl(launchUri)) {
                      await launchUrl(launchUri);
                    } else {
                      HelperUtils.showSnackBarMessage(context, "Could not launch call dialer");
                    }
                  } else {
                    HelperUtils.showSnackBarMessage(context, "Technician phone number is not available");
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            // Hire Now button
            Expanded(
              child: UiUtils.buildButton(
                context,
                buttonTitle: "Hire Now",
                onPressed: () {
                  UiUtils.checkUser(
                    onNotGuest: () => _showHireSheet(technician),
                    context: context,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Card
            Container(
              color: context.color.secondaryColor,
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 45,
                        backgroundColor: context.color.backgroundColor,
                        backgroundImage: (technician.profile != null && technician.profile!.isNotEmpty)
                            ? NetworkImage(technician.profile!)
                            : null,
                        child: (technician.profile == null || technician.profile!.isEmpty)
                            ? Icon(Icons.person, size: 40, color: context.color.territoryColor)
                            : null,
                      ),
                      if (technician.isVerified == 1)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_rounded,
                              color: context.color.forthColor,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          technician.name ?? "Specialist",
                          fontSize: context.font.larger,
                          fontWeight: FontWeight.bold,
                        ),
                        const SizedBox(height: 5),
                        CustomText(
                          technician.fieldOfExpertise ?? "Technician Specialist",
                          color: context.color.territoryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: context.font.small,
                        ),
                        if (technician.accountType != null && technician.accountType!.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (technician.accountType == 'individual'
                                        ? context.color.territoryColor
                                        : context.color.forthColor)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: (technician.accountType == 'individual'
                                          ? context.color.territoryColor
                                          : context.color.forthColor)
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: CustomText(
                                technician.accountType == 'individual'
                                    ? "individual".translate(context)
                                    : "dealerProfessional".translate(context),
                                fontSize: context.font.smaller - 1,
                                fontWeight: FontWeight.w600,
                                color: technician.accountType == 'individual'
                                    ? context.color.territoryColor
                                    : context.color.forthColor,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: availabilityColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            CustomText(
                              (technician.availabilityStatus ?? "available").toUpperCase(),
                              fontSize: context.font.smaller,
                              fontWeight: FontWeight.bold,
                              color: context.color.textDefaultColor.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. Video Player Section
            if (technician.introductionVideo != null && technician.introductionVideo!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: CustomText(
                  "Self-Introduction Video",
                  fontSize: context.font.large,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () {
                  _flickManager = FlickManager(
                    videoPlayerController: VideoPlayerController.networkUrl(
                      Uri.parse(technician.introductionVideo!),
                    ),
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoViewScreen(
                        videoUrl: technician.introductionVideo!,
                        flickManager: _flickManager,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(15),
                    image: (technician.profile != null)
                        ? DecorationImage(
                            image: NetworkImage(technician.profile!),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.6), BlendMode.darken),
                          )
                        : null,
                  ),
                  child: const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 25,
                      child: Icon(Icons.play_arrow_rounded, color: Colors.black, size: 35),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // 3. Information & Skills Section
            Container(
              color: context.color.secondaryColor,
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    "Professional Details",
                    fontSize: context.font.large,
                    fontWeight: FontWeight.bold,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded, color: context.color.territoryColor, size: 20),
                      const SizedBox(width: 8),
                      CustomText(
                        "${technician.yearsOfExperience ?? 1} Years of Experience",
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
                  if (technician.isAddressVerified == 1) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, color: context.color.forthColor, size: 20),
                        const SizedBox(width: 8),
                        CustomText(
                          "Verified Physical Location",
                          fontWeight: FontWeight.w600,
                          color: context.color.forthColor,
                        ),
                      ],
                    ),
                  ],
                  if (skillsList.isNotEmpty) ...[
                    const SizedBox(height: 15),
                    CustomText(
                      "Skills & Services",
                      fontSize: context.font.small,
                      color: context.color.textLightColor,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skillsList.map((skill) {
                        return Chip(
                          label: CustomText(skill, fontSize: context.font.small),
                          backgroundColor: context.color.backgroundColor,
                          side: BorderSide(color: context.color.borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. Rating & Reviews Breakdown
            _buildSellerSummary(technician, ratingsState.total, ratingsState.ratings),
            const SizedBox(height: 10),

            // 5. Reviews List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: CustomText(
                "Client Reviews (${ratingsState.ratings.length})",
                fontSize: context.font.large,
                fontWeight: FontWeight.bold,
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: ratingsState.ratings.length,
              itemBuilder: (context, index) {
                UserRatings rating = ratingsState.ratings[index];
                return _buildReviewCard(rating, index);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MakeAnOfferItemCubit, MakeAnOfferItemState>(
      listener: (context, offerState) {
        if (offerState is MakeAnOfferItemInProgress) {
          LoadingWidgets.showLoader(context);
        } else {
          LoadingWidgets.hideLoader(context);
        }
        if (offerState is MakeAnOfferItemSuccess) {
          dynamic data = offerState.data;

          context.read<UserProfileCubit>().getUserProfile().then((_) {
            context.read<UserDetailsCubit>().fill(HiveUtils.getUserDetails());
          });

          context.read<GetBuyerChatListCubit>().addOrUpdateChat(
            chat_model.ChatUser(
              itemId: data['item_id'] is String ? int.parse(data['item_id']) : data['item_id'],
              amount: data['amount'] != null ? double.parse(data['amount']) : null,
              buyerId: data['buyer_id'],
              createdAt: data['created_at'],
              id: data['id'],
              sellerId: data['seller_id'],
              updatedAt: data['updated_at'],
              buyer: chat_model.Buyer.fromJson(data['buyer']),
              item: chat_model.Item.fromJson(data['item']),
              seller: chat_model.Seller.fromJson(data['seller']),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (context) => SendMessageCubit()),
                    BlocProvider(create: (context) => LoadChatMessagesCubit()),
                    BlocProvider(create: (context) => DeleteMessageCubit()),
                  ],
                  child: ChatScreen(
                    profilePicture: technicianProfilePicture(data),
                    userName: technicianUserName(data),
                    userId: technicianUserId(data),
                    from: "item",
                    itemImage: data['item'] != null ? data['item']['image'] ?? "" : "",
                    itemId: data['item_id'].toString(),
                    date: data['created_at'] ?? "",
                    itemTitle: data['item'] != null ? data['item']['name'] ?? "" : "",
                    itemOfferId: data['id'],
                    itemPrice: null,
                    status: "approved",
                    buyerId: HiveUtils.getUserId(),
                    itemOfferPrice: null,
                    isPurchased: 0,
                    alreadyReview: false,
                    isFromBuyerList: true,
                  ),
                );
              },
            ),
          );
        }
        if (offerState is MakeAnOfferItemFailure) {
          HelperUtils.showSnackBarMessage(context, offerState.errorMessage.toString());
        }
      },
      child: BlocListener<ManageJobRequestCubit, ManageJobRequestState>(
        listener: (context, jobState) {
          if (jobState is ManageJobRequestInProgress) {
            LoadingWidgets.showLoader(context);
          } else {
            LoadingWidgets.hideLoader(context);
          }
          if (jobState is ManageJobRequestSubmitSuccess) {
            HelperUtils.showSnackBarMessage(context, "Job request submitted successfully!");
            // Redirect to job list
            Navigator.pushNamed(context, Routes.jobRequestsList);
          }
          if (jobState is ManageJobRequestFailure) {
            HelperUtils.showSnackBarMessage(context, jobState.errorMessage);
          }
        },
        child: DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: context.color.backgroundColor,
              body: BlocBuilder<FetchSellerRatingsCubit, FetchSellerRatingsState>(
                builder: (context, state) {
                  if (state is FetchSellerRatingsInProgress ||
                      state is FetchSellerRatingsInitial) {
                    return Material(
                      child: Center(
                        child: UiUtils.progress(),
                      ),
                    );
                  }

                  if (state is FetchSellerRatingsFail) {
                    return SomethingWentWrong();
                  }
                  if (state is FetchSellerRatingsSuccess) {
                    // Check if this seller is a technician
                    final isTechnician = state.seller!.fieldOfExpertise != null && state.seller!.isVerified == 1;
                    if (isTechnician) {
                      return buildTechnicianProfile(state.seller!, state);
                    }

                    return NestedScrollView(
                      headerSliverBuilder: (context, innerBoxIsScrolled) => [
                        SliverAppBar(
                          actions: [
                            IconButton(
                              onPressed: () {
                                HelperUtils.shareItem(
                                    context, "seller", widget.sellerId.toString());
                              },
                              icon: Icon(
                                Icons.share,
                                size: 24,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                          ],
                          leading: Material(
                            clipBehavior: Clip.antiAlias,
                            color: Colors.transparent,
                            type: MaterialType.circle,
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Directionality(
                                  textDirection: Directionality.of(context),
                                  child: RotatedBox(
                                    quarterTurns: Directionality.of(context) ==
                                            ui.TextDirection.rtl
                                        ? 2
                                        : -4,
                                    child: UiUtils.getSvg(AppIcons.arrowLeft,
                                        fit: BoxFit.none,
                                        color: context.color.textDefaultColor),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          //automaticallyImplyLeading: false,
                          pinned: true,

                          expandedHeight: (state.seller!.createdAt != null &&
                                  state.seller!.createdAt != '')
                              ? context.screenHeight / 2.3
                              : context.screenHeight / 2.5,
                          backgroundColor: context.color.secondaryColor,
                          flexibleSpace: FlexibleSpaceBar(
                            background: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 100,
                                  ),
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 45,
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(45),
                                          child: state.seller!.profile != null
                                              ? UiUtils.getImage(
                                                  state.seller!.profile!,
                                                  fit: BoxFit.fill,
                                                  width: 95,
                                                  height: 95)
                                              : UiUtils.getSvg(
                                                  AppIcons.defaultPersonLogo,
                                                  color:
                                                      context.color.territoryColor,
                                                  fit: BoxFit.none,
                                                  width: 95,
                                                  height: 95),
                                        ),
                                      ),
                                      if (state.seller!.isVerified == 1)
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: -10,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                color: context.color.forthColor),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 5, vertical: 1),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Row(
                                                  children: [
                                                    UiUtils.getSvg(
                                                        AppIcons.verifiedIcon,
                                                        width: 14,
                                                        height: 14),
                                                    SizedBox(
                                                      width: 4,
                                                    ),
                                                    CustomText(
                                                      "verifiedLbl"
                                                          .translate(context),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      softWrap: true,
                                                      color: context
                                                          .color.secondaryColor,
                                                      fontWeight: FontWeight.w500,
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 20,
                                  ),
                                  CustomText(
                                    state.seller!.name!,
                                    color: context.color.textDefaultColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  if (state.seller!.accountType != null &&
                                      state.seller!.accountType!.isNotEmpty) ...[
                                    SizedBox(
                                      height: 6,
                                    ),
                                    Align(
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: (state.seller!.accountType ==
                                                      'individual'
                                                  ? context.color.territoryColor
                                                  : context.color.forthColor)
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: (state.seller!.accountType ==
                                                        'individual'
                                                    ? context.color.territoryColor
                                                    : context.color.forthColor)
                                                .withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: CustomText(
                                          state.seller!.accountType == 'individual'
                                              ? "individual".translate(context)
                                              : "dealerProfessional"
                                                  .translate(context),
                                          fontSize: context.font.smaller - 1,
                                          fontWeight: FontWeight.w600,
                                          color: state.seller!.accountType ==
                                                  'individual'
                                              ? context.color.territoryColor
                                              : context.color.forthColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (state.seller!.createdAt != null &&
                                      state.seller!.createdAt != '') ...[
                                    SizedBox(
                                      height: 7,
                                    ),
                                    CustomText(
                                      "${"memberSince".translate(context)}\t${UiUtils.monthYearDate(state.seller!.createdAt!)}",
                                      color: context.color.textDefaultColor,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ],
                                  if (state.seller!.averageRating != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: RichText(
                                        text: TextSpan(
                                          children: [
                                            WidgetSpan(
                                              child: Icon(Icons.star_rounded,
                                                  size: 18,
                                                  color: context.color
                                                      .textDefaultColor), // Star icon
                                            ),
                                            TextSpan(
                                              text:
                                                  '\t${state.seller!.averageRating!.toStringAsFixed(2).toString()}',
                                              // Rating value
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    context.color.textDefaultColor,
                                              ),
                                            ),
                                            TextSpan(
                                              text: '  |  ',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: context
                                                    .color.textDefaultColor
                                                    .withValues(alpha: 0.5),
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '${state.ratings.length.toString()}\t${"ratings".translate(context)}',
                                              // Rating count text
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: context
                                                    .color.textDefaultColor
                                                    .withValues(alpha: 0.3),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ]),
                          ),
                          bottom: PreferredSize(
                            preferredSize: Size.fromHeight(60.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: context.color.secondaryColor,
                                border: Border(
                                  top: BorderSide(
                                      color: context.color.backgroundColor,
                                      width: 2.5),
                                ),
                              ),
                              child: Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    indicatorColor: context.color.territoryColor,
                                    labelColor: context.color.territoryColor,
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.w500),
                                    unselectedLabelColor: context
                                        .color.textDefaultColor
                                        .withValues(alpha: 0.7),
                                    unselectedLabelStyle: Theme.of(context)
                                        .textTheme
                                        .titleMedium!
                                        .copyWith(fontWeight: FontWeight.w500),
                                    tabs: [
                                      Tab(text: 'liveAds'.translate(context)),
                                      Tab(text: 'ratings'.translate(context)),
                                    ],
                                  ),
                                  Divider(
                                    height: 0,
                                    thickness: 2,
                                    color: context.color.textDefaultColor
                                        .withValues(alpha: 0.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      body: SafeArea(
                        top: false,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            liveAdsWidget(),
                            ratingsListWidget(),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container();
                },
              ),
            )),
      ),
    );
  }

  String technicianProfilePicture(dynamic data) {
    if (data['seller'] != null) {
      return data['seller']['profile'] ?? "";
    }
    return "";
  }

  String technicianUserName(dynamic data) {
    if (data['seller'] != null) {
      return data['seller']['name'] ?? "Specialist";
    }
    return "Specialist";
  }

  String technicianUserId(dynamic data) {
    if (data['seller'] != null) {
      return data['seller']['id'].toString();
    }
    return "";
  }

  Widget liveAdsWidget() {
    return BlocBuilder<FetchSellerItemsCubit, FetchSellerItemsState>(
        builder: (context, state) {
      if (state is FetchSellerItemsInProgress) {
        return buildItemsShimmer(context);
      }

      if (state is FetchSellerItemsFail) {
        return Center(
          child: CustomText(state.error),
        );
      }
      if (state is FetchSellerItemsSuccess) {
        if (state.items.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context
                    .read<FetchSellerItemsCubit>()
                    .fetch(sellerId: widget.sellerId);
              },
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "${state.total.toString()}\t${"itemsLive".translate(context)}",
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      _loadMore();
                    }
                    return true;
                  },
                  child: GridView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.only(top: 10),
                    shrinkWrap: true,
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                            crossAxisCount: 2,
                            height: MediaQuery.of(context).size.height / 3.2,
                            mainAxisSpacing: 7,
                            crossAxisSpacing: 10),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      ItemModel item = state.items[index];

                      return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              Routes.adDetailsScreen,
                              arguments: {
                                'model': item,
                              },
                            );
                          },
                          child: ItemCard(
                            item: item,
                          ));
                    },
                  ),
                ),
              ),
              if (state.isLoadingMore) Center(child: UiUtils.progress())
            ],
          ),
        );
      }
      return Container();
    });
  }

  Map<int, int> getRatingCounts(List<UserRatings> userRatings) {
    Map<int, int> ratingCounts = {
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    if (userRatings.isNotEmpty) {
      for (var rating in userRatings) {
        int ratingValue = (rating.ratings ?? 0.0).toInt();

        if (ratingCounts.containsKey(ratingValue)) {
          ratingCounts[ratingValue] = ratingCounts[ratingValue]! + 1;
        }
      }
    }

    return ratingCounts;
  }

  Widget buildRatingsShimmer(BuildContext context) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          border: Border.all(width: 1.5, color: context.color.borderColor),
          color: context.color.secondaryColor,
          borderRadius: BorderRadius.circular(18)),
      child: Row(
        spacing: 10,
        children: [
          getShimmer(height: 120, width: 100),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              getShimmer(height: 10, width: 100, borderadius: 7),
              getShimmer(height: 10, width: 150, borderadius: 7),
              getShimmer(height: 10, width: 120, borderadius: 7),
              getShimmer(height: 10, width: 80, borderadius: 7),
            ],
          )
        ],
      ),
    );
  }

  Widget ratingsListWidget() {
    return BlocBuilder<FetchSellerRatingsCubit, FetchSellerRatingsState>(
        builder: (context, state) {
      if (state is FetchSellerRatingsInProgress) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          itemCount: 10,
          itemBuilder: (context, index) {
            return buildRatingsShimmer(context);
          },
        );
      }

      if (state is FetchSellerRatingsFail) {
        return Center(
          child: CustomText(state.error),
        );
      }
      if (state is FetchSellerRatingsSuccess) {
        if (state.ratings.isEmpty) {
          return Center(
            child: NoDataFound(
              onTap: () {
                context
                    .read<FetchSellerRatingsCubit>()
                    .fetch(sellerId: widget.sellerId);
              },
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state.seller != null)
                _buildSellerSummary(state.seller!, state.total, state.ratings),

              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent) {
                      _reviewLoadMore();
                    }
                    return true;
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: state.ratings.length,
                    itemBuilder: (context, index) {
                      UserRatings ratings = state.ratings[index];

                      return _buildReviewCard(ratings, index);
                    },
                  ),
                ),
              ),
              if (state.isLoadingMore) UiUtils.progress()
            ],
          ),
        );
      }
      return Container();
    });
  }

  Widget _buildSellerSummary(
      Seller seller, int total, List<UserRatings> ratings) {
    Map<int, int> ratingCounts = getRatingCounts(ratings);
    return Card(
      color: context.color.secondaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 20,
              children: [
                Column(
                  children: [
                    Text((seller.averageRating ?? 0).toStringAsFixed(2),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(
                                color: context.color.textDefaultColor,
                                fontWeight: FontWeight.bold)),
                    CustomRatingBar(
                      rating: seller.averageRating ?? 0,
                      itemSize: 25.0,
                      activeColor: Colors.amber,
                      inactiveColor:
                          context.color.textLightColor.withValues(alpha: 0.1),
                      allowHalfRating: true,
                    ),
                    SizedBox(height: 3),
                    CustomText(
                      "${total.toString()}\t${"ratings".translate(context)}",
                      fontSize: context.font.large,
                    )
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(5, (index) {
                      final rating = 5 - index;
                      return _buildRatingBar(
                          rating, ratingCounts[rating]!.toInt(), total > 0 ? total : 1);
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(int starCount, int ratingCount, int total) {
    return Row(
      children: [
        SizedBox(
          width: 10.0,
          child: CustomText("$starCount",
              color: context.color.textDefaultColor,
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w500),
        ),
        SizedBox(
          width: 2,
        ),
        Icon(
          Icons.star_rounded,
          size: 15,
          color: context.color.textDefaultColor,
        ),
        SizedBox(width: 5),
        Expanded(
          child: LinearProgressIndicator(
            value: ratingCount / total,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
                Colors.deepOrange.withValues(alpha: 0.8)),
          ),
        ),
        SizedBox(width: 10),
        SizedBox(
          width: 10.0,
          child: CustomText(ratingCount.toString(),
              color: context.color.textDefaultColor.withValues(alpha: 0.7),
              textAlign: TextAlign.center,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String dateTime(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate).toLocal();
    DateTime now = DateTime.now();

    DateFormat dateFormat = DateFormat('MMM d, yyyy');
    DateFormat timeFormat = DateFormat('h:mm a');

    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      String formattedTime = timeFormat.format(dateTime);
      return formattedTime;
    } else {
      String formattedDate = dateFormat.format(dateTime);
      return formattedDate;
    }
  }

  Widget _buildReviewCard(UserRatings ratings, int index) {
    return Card(
      color: context.color.secondaryColor,
      margin: EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ratings.buyer!.profile == "" || ratings.buyer!.profile == null
                ? CircleAvatar(
                    backgroundColor: context.color.territoryColor,
                    child: SvgPicture.asset(
                      AppIcons.profile,
                      colorFilter: ColorFilter.mode(
                          context.color.buttonColor, BlendMode.srcIn),
                    ),
                  )
                : CustomImageHeroAnimation(
                    type: CImageType.Network,
                    image: ratings.buyer!.profile,
                    child: CircleAvatar(
                      backgroundImage: CachedNetworkImageProvider(
                        ratings.buyer!.profile!,
                      ),
                    ),
                  ),
            Expanded(
              child: Column(
                spacing: 5,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        ratings.buyer!.name!,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      if (ratings.createdAt != null)
                        CustomText(
                          dateTime(
                            ratings.createdAt!,
                          ),
                          fontSize: context.font.small,
                          color: context.color.textDefaultColor.withValues(
                            alpha: .3,
                          ),
                        )
                    ],
                  ),
                  Row(
                    spacing: 5,
                    children: [
                      CustomRatingBar(
                        rating: ratings.ratings!,
                        itemSize: 20.0,
                        activeColor: Colors.amber,
                        inactiveColor: Colors.grey.shade300,
                        allowHalfRating: true,
                      ),
                      CustomText(
                        ratings.ratings!.toString(),
                        color: context.color.textDefaultColor,
                      )
                    ],
                  ),
                  SizedBox(
                    width: context.screenWidth * 0.63,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final span = TextSpan(
                          text: "${ratings.review!}\t",
                          style: TextStyle(
                            color: context.color.textDefaultColor,
                          ),
                        );
                        final tp = TextPainter(
                          text: span,
                          maxLines: 2,
                          textDirection: ui.TextDirection.ltr,
                        );
                        tp.layout(maxWidth: constraints.maxWidth);

                        final isOverflowing = tp.didExceedMaxLines;

                        return Row(
                          spacing: 3,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: CustomText(
                                "${ratings.review!}\t",
                                maxLines: ratings.isExpanded! ? null : 2,
                                softWrap: true,
                                overflow: ratings.isExpanded!
                                    ? TextOverflow.visible
                                    : TextOverflow.ellipsis,
                                color: context.color.textDefaultColor,
                              ),
                            ),
                            if (isOverflowing)
                              InkWell(
                                onTap: () {
                                  context
                                      .read<FetchSellerRatingsCubit>()
                                      .updateIsExpanded(index);
                                },
                                child: CustomText(
                                  ratings.isExpanded!
                                      ? "readLessLbl".translate(context)
                                      : "readMoreLbl".translate(context),
                                  color: context.color.territoryColor,
                                  fontWeight: FontWeight.w400,
                                  fontSize: context.font.small,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildItemsShimmer(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: sidePadding),
      children: [
        Row(
            spacing: 10,
            children: List.generate(
              2,
              (index) => getShimmer(),
            )),
        SizedBox(
          height: 5,
        ),
        Row(
            spacing: 10,
            children: List.generate(
              2,
              (index) => getShimmer(),
            )),
      ],
    );
  }

  Widget getShimmer({double? height, double? width, double? borderadius}) {
    return CustomShimmer(
      borderRadius: borderadius,
      height: height ?? MediaQuery.of(context).size.height / 3.4,
      width: width ?? context.screenWidth / 2.3,
    );
  }
}

class CustomRatingBar extends StatelessWidget {
  final double rating;

  final double itemSize;
  final Color activeColor;
  final Color inactiveColor;
  final bool allowHalfRating;

  const CustomRatingBar({
    Key? key,
    required this.rating,
    this.itemSize = 24.0,
    this.activeColor = Colors.amber,
    this.inactiveColor = Colors.grey,
    this.allowHalfRating = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        IconData icon;
        if (index < rating.floor()) {
          icon = Icons.star_rounded;
        } else if (allowHalfRating && index < rating) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_rounded;
        }

        return Icon(
          icon,
          color: index < rating ? activeColor : inactiveColor,
          size: itemSize,
        );
      }),
    );
  }
}
