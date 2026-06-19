import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/custom_text.dart';
import 'package:nofak/utils/extensions/extensions.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/material.dart';

class CategoryHomeCard extends StatelessWidget {
  final String title;
  final String url;
  final VoidCallback onTap;
  const CategoryHomeCard({
    super.key,
    required this.title,
    required this.url,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          spacing: 4,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: context.color.secondaryColor,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: UiUtils.imageType(url, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CustomText(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                fontSize: context.font.smaller,
                color: context.color.textDefaultColor.withValues(alpha: .7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
