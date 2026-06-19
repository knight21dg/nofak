import 'package:nofak/app/routes.dart';
import 'package:nofak/ui/screens/home/home_screen.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/app_icon.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class SellerIntroVerificationScreen extends StatefulWidget {
  final bool isResubmitted;
  final String type;

  SellerIntroVerificationScreen({super.key, required this.isResubmitted, this.type = 'seller'});

  @override
  State<SellerIntroVerificationScreen> createState() =>
      _SellerIntroVerificationScreenState();

  static Route route(RouteSettings routeSettings) {
    Map? arguments = routeSettings.arguments as Map?;
    return MaterialPageRoute(
      builder: (_) => SellerIntroVerificationScreen(
        isResubmitted: arguments?["isResubmitted"] ?? false,
        type: arguments?["type"] ?? 'seller',
      ),
    );
  }
}

class _SellerIntroVerificationScreenState
    extends State<SellerIntroVerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(context, showBackButton: true),
      body: SingleChildScrollView(child: mainBody()),
    );
  }

  Widget mainBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: context.screenHeight * 0.08),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: UiUtils.getSvg(AppIcons.userVerificationIcon),
        ),
        SizedBox(height: 30),
        CustomText(
          "userVerification".translate(context),
          fontSize: context.font.extraLarge,
          fontWeight: FontWeight.w600,
          color: context.color.textDefaultColor,
        ),
        SizedBox(height: 25),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.08),
          child: CustomText(
            "userVerificationHeadline".translate(context),
            textAlign: TextAlign.center,
            color: context.color.textLightColor,
            fontSize: context.font.normal,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.08),
          child: CustomText(
            "userVerificationHeadline1".translate(context),
            textAlign: TextAlign.center,
            color: context.color.textLightColor,
            fontSize: context.font.normal,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.screenWidth * 0.25),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: UiUtils.buildButton(
            context,
            height: 46,
            radius: 8,
            onPressed: () {
              Navigator.pushNamed(
                context,
                Routes.sellerVerificationScreen,
                arguments: {
                  "isResubmitted": widget.isResubmitted,
                  "type": widget.type,
                },
              );
            },
            buttonTitle: "startVerification".translate(context),
          ),
        ),
        SizedBox(height: 30),
        GestureDetector(
          child: Text(
            "skipForLater".translate(context),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              decoration: TextDecoration.underline,
              color: context.color.textDefaultColor,
            ),
          ),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
