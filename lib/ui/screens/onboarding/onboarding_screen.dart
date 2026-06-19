import 'dart:io';

import 'package:nofak/app/routes.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "onboarding_1_title",
      "description": "onboarding_1_des",
      "image": "assets/onboarding_1.png"
    },
    {
      "title": "onboarding_2_title",
      "description": "onboarding_2_des",
      "image": "assets/onboarding_2.png"
    },
    {
      "title": "onboarding_3_title",
      "description": "onboarding_3_des",
      "image": "assets/onboarding_3.png"
    },
    {
      "title": "onboarding_4_title",
      "description": "onboarding_4_des",
      "image": "assets/onboarding_4.png"
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _onboardingData.length,
              itemBuilder: (context, index) {
                return _buildPage(
                  context,
                  _onboardingData[index]["title"]!,
                  _onboardingData[index]["description"]!,
                  _onboardingData[index]["image"]!,
                );
              },
            ),
            
            // Skip button at top right
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: GestureDetector(
                onTap: _onFinish,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.color.textColorDark.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "skip".translate(context),
                    style: TextStyle(
                      color: context.color.textColorDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation (Dots & Buttons)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  // Dots Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? context.color.territoryColor
                              : context.color.textColorDark.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Action Button
                  UiUtils.buildButton(
                    context,
                    onPressed: () {
                      if (_currentPage < _onboardingData.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _onFinish();
                      }
                    },
                    radius: 16,
                    height: 56,
                    buttonTitle: (_currentPage == _onboardingData.length - 1)
                        ? "getStarted".translate(context)
                        : "next".translate(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, String title, String description, String image) {
    return Column(
      children: [
        // Image Area
        Expanded(
          flex: 6,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.color.territoryColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Image.asset(
                  image,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
        
        // Text Area
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 40, 30, 0),
            child: Column(
              children: [
                Text(
                  title.translate(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.color.textColorDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description.translate(context),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.color.textLightColor,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _onFinish() {
    HiveUtils.setUserIsNotNew();
    Navigator.pushReplacementNamed(
      context,
      Routes.login,
      arguments: {"from": "login", "isSkipped": false},
    );
  }
}
