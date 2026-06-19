import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:nofak/app/routes.dart';
import 'package:nofak/utils/constant.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void init() {
    try {
      _appLinks = AppLinks();
      _handleInitialLink();
      _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
        _handleLink(uri);
      });
    } catch (e) {
      debugPrint('DeepLinkService initialization error: $e');
    }
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _handleLink(uri);
      }
    } catch (e) {
      debugPrint('Error handling initial deep link: $e');
    }
  }

  void _handleLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');

    // Expected formats:
    // https://nofak.in/ad-details/slug
    // https://nofak.in/seller/id
    
    // Normalize path
    String path = uri.path;
    if (path.isEmpty || path == '/') return;

    // Use the existing routing logic in Routes.onGenerateRouted
    // by pushing the path as a named route.
    // The Routes class already handles paths like /ad-details/slug
    
    Future.delayed(const Duration(milliseconds: 500), () {
       if (Constant.navigatorKey.currentState != null) {
          Constant.navigatorKey.currentState?.pushNamed(path);
       }
    });
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
