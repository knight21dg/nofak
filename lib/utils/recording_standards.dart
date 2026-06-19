import 'package:flutter/material.dart';
import 'package:nofak/data/model/category_model.dart';

class RecordingStandards {
  /// Returns an instruction key unique to the category's slug.
  /// Format: instr_{slug_with_underscores}
  /// Walks the breadcrumb from leaf → root, returning the first slug-based key.
  /// The dialog checks whether a real translation exists for this key.
  static String? getInstructionsKey(List<CategoryModel> breadcrumbs) {
    if (breadcrumbs.isEmpty) return null;

    // Walk from the most specific (leaf) category toward the root
    for (var category in breadcrumbs.reversed) {
      final slug = category.slug?.toLowerCase().trim();
      if (slug == null || slug.isEmpty) continue;

      // Convert hyphens to underscores for a valid localization key
      final key = 'instr_${slug.replaceAll('-', '_')}';
      debugPrint("RecordingStandards: slug=$slug → key=$key");
      return key;
    }

    return null;
  }
}
