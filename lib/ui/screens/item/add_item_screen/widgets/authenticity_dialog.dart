import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';

class AuthenticityProtocolDialog extends StatelessWidget {
  final String? instrKey;
  final VoidCallback onAccept;

  const AuthenticityProtocolDialog({
    super.key,
    this.instrKey,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glassmorphic background
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: FadeTransition(
                    opacity: AlwaysStoppedAnimation(scale),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.color.secondaryColor.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: context.color.borderColor,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 40,
                        offset: const Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Builder(
                    builder: (context) {
                      // Check if a real translation exists for the instruction key
                      final translatedInstr = instrKey?.translate(context);
                      final hasTranslation = instrKey != null &&
                          translatedInstr != null &&
                          translatedInstr != instrKey;

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Premium Header Section
                          Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.security_rounded,
                                  color: context.color.territoryColor,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText(
                                      "authenticityProtocol".translate(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: context.font.extraLarge,
                                      color: context.color.textColorDark,
                                    ),
                                    Row(
                                      children: [
                                        _buildPulsingDot(),
                                        const SizedBox(width: 6),
                                        CustomText(
                                          "liveRecordingProtocol".translate(context),
                                          fontSize: context.font.small,
                                          color: context.color.textLightColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),

                          // Category Guidelines Section (Dynamic)
                          if (hasTranslation) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    context.color.territoryColor.withValues(alpha: 0.15),
                                    context.color.territoryColor.withValues(alpha: 0.05),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: context.color.territoryColor.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 22,
                                        color: context.color.territoryColor,
                                      ),
                                      const SizedBox(width: 10),
                                      CustomText(
                                        "categoryGuidelines".translate(context),
                                        fontWeight: FontWeight.bold,
                                        fontSize: context.font.large,
                                        color: context.color.territoryColor,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  CustomText(
                                    translatedInstr!,
                                    fontSize: context.font.normal,
                                    color: context.color.textColorDark.withValues(alpha: 0.9),
                                    height: 1.6,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Checklist section
                          CustomText(
                            "verificationChecklist".translate(context),
                            fontWeight: FontWeight.bold,
                            fontSize: context.font.normal,
                            color: context.color.textLightColor,
                            letterSpacing: 1.2,
                          ),
                          const SizedBox(height: 16),
                          _buildCheckPoint(context, "openItemFully".translate(context)),
                          _buildCheckPoint(context, "presentProofOfOwnership".translate(context)),
                          _buildCheckPoint(context, "demonstrateWorkingCondition".translate(context)),
                          _buildCheckPoint(context, "stateAskingPriceOnCamera".translate(context)),

                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: CustomText(
                                    "cancelBtnLbl".translate(context),
                                    color: context.color.textLightColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        context.color.territoryColor,
                                        context.color.territoryColor.withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: context.color.territoryColor.withValues(alpha: 0.4),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context, true);
                                      onAccept();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    child: CustomText(
                                      "ok".translate(context).toUpperCase(),
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: context.font.large,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red,
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckPoint(BuildContext context, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.color.textColorDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.color.borderColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              size: 16,
              color: context.color.territoryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: CustomText(
              text,
              fontSize: context.font.normal,
              fontWeight: FontWeight.w500,
              color: context.color.textColorDark.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
