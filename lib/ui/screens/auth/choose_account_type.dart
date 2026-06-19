import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/data/cubits/auth/auth_cubit.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:nofak/utils/widgets.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/data/cubits/system/user_details.dart';
import 'package:nofak/data/cubits/auth/user_profile_cubit.dart';
import 'package:nofak/utils/api.dart';

class ChooseAccountTypeScreen extends StatefulWidget {
  const ChooseAccountTypeScreen({super.key});

  static Route route(RouteSettings routeSettings) {
    return MaterialPageRoute(
      settings: routeSettings,
      builder: (_) => const ChooseAccountTypeScreen(),
    );
  }

  @override
  State<ChooseAccountTypeScreen> createState() => _ChooseAccountTypeScreenState();
}

class _ChooseAccountTypeScreenState extends State<ChooseAccountTypeScreen> {
  String? _selectedType;
  int _signupBonusIndividual = 100;
  int _signupBonusProfessional = 300;

  @override
  void initState() {
    super.initState();
    _fetchCreditRules();
  }

  Future<void> _fetchCreditRules() async {
    try {
      final response = await Api.get(url: Api.creditRules);
      if (response['error'] == false && response['data'] != null) {
        final data = response['data'];
        if (mounted) {
          setState(() {
            _signupBonusIndividual =
                int.tryParse(data['signup_bonus_individual'].toString()) ?? 100;
            _signupBonusProfessional =
                int.tryParse(data['signup_bonus_professional'].toString()) ??
                    300;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching credit rules: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                "chooseAccountType".translate(context),
                style: TextStyle(
                  color: context.color.textColorDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "selectAccountTypeDescription".translate(context),
                style: TextStyle(
                  color: context.color.textLightColor,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              _buildTypeOption(
                type: 'individual',
                title: "individual".translate(context),
                description: "individualDescription"
                    .translate(context)
                    .replaceAll("{credits}", _signupBonusIndividual.toString()),
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildTypeOption(
                type: 'dealer',
                title: "dealerProfessional".translate(context),
                description: "dealerDescription"
                    .translate(context)
                    .replaceAll("{credits}", _signupBonusProfessional.toString()),
                icon: Icons.business_outlined,
              ),
              const Spacer(),
              UiUtils.buildButton(
                context,
                onPressed: _handleContinue,
                buttonTitle: "continue".translate(context),
                disabled: _selectedType == null,
                disabledColor: Colors.grey.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeOption({
    required String type,
    required String title,
    required String description,
    required IconData icon,
  }) {
    bool isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? context.color.territoryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? context.color.territoryColor : context.color.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? context.color.territoryColor : context.color.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : context.color.territoryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.color.textColorDark,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: context.color.textLightColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.color.territoryColor,
              ),
          ],
        ),
      ),
    );
  }

  void _handleContinue() async {
    try {
      LoadingWidgets.showLoader(context);

      await context.read<AuthCubit>().updateUserData(
        context,
        accountType: _selectedType,
        personalDetail: HiveUtils.getUserDetails().isPersonalDetailShow ?? 0,
      );

      // Sync profile from server to get correct credit balance
      await context.read<UserProfileCubit>().getUserProfile();

      // Update UserDetailsCubit with the new data from Hive
      context.read<UserDetailsCubit>().fill(HiveUtils.getUserDetails());

      LoadingWidgets.hideLoader(context);

      // Check if location is already set, if not go to location permission screen
      final location = HiveUtils.getLocationV2();
      if (location != null && !location.isEmpty) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.main,
          (route) => false,
          arguments: {"from": "login"},
        );
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil(
          Routes.locationPermissionScreen,
          (route) => false,
        );
      }
    } catch (e) {
      LoadingWidgets.hideLoader(context);
      UiUtils.showError(context, e);
    }
  }
}
