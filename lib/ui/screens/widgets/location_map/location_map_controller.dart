import 'dart:developer';

import 'package:nofak/data/model/location/leaf_location.dart';
import 'package:nofak/ui/theme/theme.dart';
import 'package:nofak/utils/constant.dart';
import 'package:nofak/utils/hive_utils.dart';
import 'package:nofak/utils/location_utility.dart';
import 'package:nofak/utils/ui_utils.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nofak/utils/extensions/extensions.dart';

class MapData {
  MapData({
    required this.location,
    required this.marker,
    required this.circle,
    required this.cameraPosition,
    required this.radius,
  });

  final LeafLocation location;
  final Marker marker;
  final Circle circle;
  final CameraPosition cameraPosition;
  final double radius;
}

class LocationMapController extends ChangeNotifier {
  LocationMapController({
    this.initialCoordinates,
    LeafLocation? initialLocation,
  }) : _location = initialLocation ?? LeafLocation();

  final LatLng? initialCoordinates;

  GoogleMapController? _mapController;
  final LocationUtility _locationUtility = LocationUtility();

  late LeafLocation _location;
  late Marker _marker;
  late Circle _circle;
  late CameraPosition _cameraPosition;
  double _radius = 25.0;

  double get radius => _radius;

  MapData get data => MapData(
    location: _location.copyWith(radius: _radius),
    marker: _marker,
    circle: _circle,
    cameraPosition: _cameraPosition,
    radius: _radius,
  );

  bool isReady = false;
  bool isGeocoding = false;

  static const double _zoom = 12;
  static const String _markerId = 'current_location';
  static const String _circleId = 'current_area';

  void init() async {
    // This is only used in ad_details_screen and is statically written for that purpose only.
    // If needed to be used elsewhere, then it may require further modification or
    // a streamlined approach.
    if (initialCoordinates != null) {
      isReady = true;
      _radius = 1;
      _updatePosition(initialCoordinates!);
    } else {
      // TODO(rio): Do not directly use HiveUtils here.
      final location = HiveUtils.getLocationV2();

      if (location == null || !location.hasCoordinates) {
        _location = Constant.defaultLocation;
      } else {
        _location = location;
      }
      _radius = _location.radius ?? 25.0;
      isReady = true;
      _updatePosition(LatLng(_location.latitude!, _location.longitude!));
    }
  }

  void onMapCreated(GoogleMapController? controller) {
    _mapController = controller;
  }

  void onTap(LatLng coordinates) async {
    try {
      isGeocoding = true;
      notifyListeners();
      _location = await _locationUtility.getLeafLocationFromLatLng(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );
      isGeocoding = false;
      log('${_location.toJson()}', name: 'Location Updated');
      _updatePosition(
        LatLng(
          _location.latitude ?? coordinates.latitude,
          _location.longitude ?? coordinates.longitude,
        ),
      );
    } catch (e) {
      isGeocoding = false;
      notifyListeners();
      // We don't necessarily want to show a dialog for every tap failure,
      // but we should at least log it and maybe revert to the coordinates.
      log('Error during map tap: $e');
      _updatePosition(coordinates);
    }
  }

  void _updatePosition(LatLng coordinates) async {
    _marker = Marker(
      markerId: MarkerId(_markerId),
      position: coordinates,
      anchor: Offset(.5, .5),
    );
    _circle = Circle(
      circleId: CircleId(_circleId),
      center: coordinates,
      radius: _radius * 1000,
      fillColor: territoryColor_.withValues(alpha: .5),
      strokeWidth: 2,
      strokeColor: territoryColor_,
    );
    _cameraPosition = CameraPosition(target: coordinates, zoom: _zoom);
    if (isReady) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(coordinates));
    }
    notifyListeners();
  }

  Future<void> getLocation(BuildContext context) async {
    try {
      isGeocoding = true;
      notifyListeners();
      final location = await _locationUtility.getLocation(context);
      isGeocoding = false;
      if (location == null || !location.hasCoordinates) {
        throw Exception("couldNotFetchLocation".translate(context));
      }
      _location = location;
      _radius = _location.radius != null && _location.radius != 0
          ? _location.radius!
          : _radius;
      _updatePosition(LatLng(_location.latitude!, _location.longitude!));
    } catch (e) {
      isGeocoding = false;
      notifyListeners();
      if (context.mounted) {
        UiUtils.showError(context, e);
      }
    }
  }

  void updateRadius(double value) {
    if (value == _radius) return;
    _radius = value;
    _circle = _circle.copyWith(radiusParam: _radius * 1000);
    notifyListeners();
  }

  void updateLocation(LeafLocation location) {
    if (_location == location) return;
    _location = location;
    if (_location.latitude != null && _location.longitude != null) {
      _updatePosition(LatLng(_location.latitude!, _location.longitude!));
    }
    notifyListeners();
  }
}
